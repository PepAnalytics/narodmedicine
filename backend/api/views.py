from django.conf import settings
from django.core.cache import cache
from django.db.models import Case, Count, IntegerField, Prefetch, Q, Sum, Value, When
from django.db.models.functions import Coalesce, Lower, StrIndex
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.exceptions import APIException, NotFound, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from api.push_service import PushConfigurationError, send_push_notifications
from api.serializers import (
    AnalyticsEventRequestSerializer,
    AnalyticsEventResponseSerializer,
    DiseaseDetailSerializer,
    FavoriteCreateSerializer,
    FavoriteItemSerializer,
    FavoriteListResponseSerializer,
    HistoryCreateResponseSerializer,
    HistoryCreateSerializer,
    HistoryListResponseSerializer,
    LegalDocumentSerializer,
    PopularDiseaseListResponseSerializer,
    PushDeviceSerializer,
    PushNotifyRequestSerializer,
    PushNotifyResponseSerializer,
    PushSubscribeRequestSerializer,
    PushUnsubscribeRequestSerializer,
    PushUnsubscribeResponseSerializer,
    RemedyFullSerializer,
    RemedyListResponseSerializer,
    RemedyRateRequestSerializer,
    RemedyRateResponseSerializer,
    SearchRequestSerializer,
    SearchResponseSerializer,
    SymptomListSerializer,
    SyncResponseSerializer,
    UserConsentRequestSerializer,
    UserConsentResponseSerializer,
)
from core.cache_utils import (
    CATALOG_CACHE_NAMESPACE,
    LEGAL_CACHE_NAMESPACE,
    build_versioned_cache_key,
    get_catalog_cache_timeout,
    get_legal_cache_timeout,
)
from core.models import (
    AnalyticsEvent,
    DeviceRegistration,
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Favorite,
    LegalDocumentTypeChoices,
    PrivacyPolicy,
    RegionChoices,
    Remedy,
    RemedyIngredient,
    Source,
    Symptom,
    TermsOfService,
    UserConsent,
    UserRating,
    ViewHistory,
)

USER_ID_HEADER_PARAM = openapi.Parameter(
    "X-User-Id",
    openapi.IN_HEADER,
    description="Идентификатор пользователя без авторизации.",
    type=openapi.TYPE_STRING,
    required=False,
)

USER_ID_QUERY_PARAM = openapi.Parameter(
    "user_id",
    openapi.IN_QUERY,
    description="Идентификатор пользователя (альтернатива заголовку X-User-Id).",
    type=openapi.TYPE_STRING,
    required=False,
)

EVIDENCE_LEVEL_QUERY_PARAM = openapi.Parameter(
    "evidence_level",
    openapi.IN_QUERY,
    description="Коды уровней доказательности через запятую, например A,B,C.",
    type=openapi.TYPE_STRING,
    required=False,
)

PAGE_QUERY_PARAM = openapi.Parameter(
    "page",
    openapi.IN_QUERY,
    description="Номер страницы (начиная с 1).",
    type=openapi.TYPE_INTEGER,
    required=False,
)

PAGE_SIZE_QUERY_PARAM = openapi.Parameter(
    "page_size",
    openapi.IN_QUERY,
    description="Размер страницы (по умолчанию 20, максимум 100).",
    type=openapi.TYPE_INTEGER,
    required=False,
)

REGION_QUERY_PARAM = openapi.Parameter(
    "region",
    openapi.IN_QUERY,
    description=(
        "Фильтр по региону метода: arab, persian, caucasian, turkic, "
        "chinese, indian, other."
    ),
    type=openapi.TYPE_STRING,
    required=False,
)


class PushServiceUnavailable(APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Push service is not configured."
    default_code = "service_unavailable"


def serialize_evidence_level(evidence_level: EvidenceLevel) -> dict:
    return {
        "id": evidence_level.id,
        "code": evidence_level.code,
        "description": evidence_level.description,
        "color": evidence_level.color,
        "rank": evidence_level.rank,
    }


def make_short_description(text: str, max_length: int = 160) -> str:
    if len(text) <= max_length:
        return text
    return f"{text[: max_length - 3].rstrip()}..."


def normalize_symptom_names(raw_symptoms: list[str]) -> list[str]:
    unique_names: list[str] = []
    seen: set[str] = set()

    for raw_name in raw_symptoms:
        clean_name = raw_name.strip()
        if not clean_name:
            continue
        lookup_key = clean_name.casefold()
        if lookup_key in seen:
            continue
        seen.add(lookup_key)
        unique_names.append(clean_name)
    return unique_names


def resolve_user_id(request, fallback: str | None = None) -> str:  # noqa: ANN001
    candidates = [
        fallback,
        request.headers.get("X-User-Id"),
        request.query_params.get("user_id"),
    ]
    for candidate in candidates:
        if candidate is None:
            continue
        value = str(candidate).strip()
        if value:
            return value
    raise ValidationError({"user_id": "Provide user_id in body, query, or X-User-Id."})


def parse_evidence_codes(raw_codes: str | None) -> list[str]:
    if not raw_codes:
        return []
    codes: list[str] = []
    for chunk in raw_codes.split(","):
        code = chunk.strip().upper()
        if not code:
            continue
        if code in codes:
            continue
        codes.append(code)
    return codes


def parse_region(raw_region: str | None) -> str | None:
    if raw_region is None:
        return None
    region = raw_region.strip().lower()
    if not region:
        return None
    allowed_regions = {choice[0] for choice in RegionChoices.choices}
    if region not in allowed_regions:
        raise ValidationError(
            {
                "region": (
                    "Unsupported region. Expected one of: "
                    f"{', '.join(sorted(allowed_regions))}."
                )
            }
        )
    return region


def parse_positive_int(
    raw_value: str | None,
    *,
    field_name: str,
    default: int,
    max_value: int,
) -> int:
    if raw_value is None:
        return default
    try:
        value = int(raw_value)
    except ValueError as exc:
        raise ValidationError({field_name: "Must be an integer."}) from exc
    if value < 1:
        raise ValidationError({field_name: "Must be greater than 0."})
    if value > max_value:
        raise ValidationError({field_name: f"Must be <= {max_value}."})
    return value


def get_remedy_queryset():
    return Remedy.objects.select_related(
        "disease",
        "evidence_level",
        "source_record",
    ).prefetch_related(
        Prefetch(
            "remedy_ingredients",
            queryset=RemedyIngredient.objects.select_related("ingredient").order_by(
                "ingredient__name"
            ),
        )
    )


def serialize_source_record(source_record: Source | None) -> dict | None:
    if source_record is None:
        return None
    return {
        "id": source_record.id,
        "title": source_record.title,
        "author": source_record.author,
        "year": source_record.year,
        "region": source_record.region,
        "source_type": source_record.source_type,
        "url": source_record.url,
        "reference": source_record.reference,
    }


def serialize_remedy(remedy: Remedy) -> dict:
    return {
        "id": remedy.id,
        "disease_id": remedy.disease_id,
        "name": remedy.name,
        "description": remedy.description,
        "recipe": remedy.recipe,
        "risks": remedy.risks,
        "source": remedy.source,
        "source_record": serialize_source_record(remedy.source_record),
        "region": remedy.region,
        "cultural_context": remedy.cultural_context,
        "evidence_level": serialize_evidence_level(remedy.evidence_level),
        "ingredients": [
            {
                "id": remedy_ingredient.ingredient_id,
                "name": remedy_ingredient.ingredient.name,
                "amount": remedy_ingredient.amount,
                "alternative_names": remedy_ingredient.ingredient.alternative_names,
            }
            for remedy_ingredient in remedy.remedy_ingredients.all()
        ],
        "likes_count": remedy.likes_count,
        "dislikes_count": remedy.dislikes_count,
    }


def serialize_device(device: DeviceRegistration) -> dict:
    return {
        "id": device.id,
        "user_id": device.user_id,
        "fcm_token": device.fcm_token,
        "platform": device.platform,
        "is_active": device.is_active,
        "created_at": device.created_at,
        "updated_at": device.updated_at,
        "last_seen_at": device.last_seen_at,
    }


def serialize_legal_document(document, document_type: str) -> dict:  # noqa: ANN001
    return {
        "document_type": document_type,
        "version": document.version,
        "content": document.content,
        "effective_from": document.effective_from,
        "created_at": document.created_at,
    }


def get_current_document(model_class):  # noqa: ANN001, ANN202
    document = (
        model_class.objects.filter(effective_from__lte=timezone.now())
        .order_by("-effective_from", "-created_at")
        .first()
    )
    if document is not None:
        return document

    document = model_class.objects.order_by("-effective_from", "-created_at").first()
    if document is not None:
        return document
    raise NotFound("Requested document is not available.")


def serialize_disease_preview(
    disease: Disease,
    *,
    match_score: float | None = None,
    matched_symptoms: list[dict] | None = None,
    popularity_score: int | None = None,
    remedies_count: int | None = None,
) -> dict:
    short_description = make_short_description(disease.description or "")
    payload = {
        "id": disease.id,
        "name": disease.name,
        "description": short_description,
        "short_description": short_description,
    }
    if match_score is not None:
        payload["match_score"] = match_score
    if matched_symptoms is not None:
        payload["symptoms"] = matched_symptoms
        payload["matched_symptoms"] = matched_symptoms
    if popularity_score is not None:
        payload["popularity_score"] = popularity_score
    if remedies_count is not None:
        payload["remedies_count"] = remedies_count
    return payload


class SearchView(APIView):
    @swagger_auto_schema(
        operation_summary="Поиск болезней по симптомам",
        manual_parameters=[REGION_QUERY_PARAM],
        request_body=SearchRequestSerializer,
        responses={status.HTTP_200_OK: SearchResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        request_serializer = SearchRequestSerializer(data=request.data)
        request_serializer.is_valid(raise_exception=True)
        region = parse_region(request.query_params.get("region"))

        normalized_symptoms = normalize_symptom_names(
            request_serializer.validated_data["symptoms"]
        )
        if not normalized_symptoms:
            return Response({"diseases": []}, status=status.HTTP_200_OK)

        cache_key = build_versioned_cache_key(
            CATALOG_CACHE_NAMESPACE,
            "search",
            {
                "symptoms": normalized_symptoms,
                "region": region,
            },
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            return Response(cached_response, status=status.HTTP_200_OK)

        lookup_query = Q()
        for symptom_name in normalized_symptoms:
            lookup_query |= Q(name__iexact=symptom_name)

        matched_symptoms = list(Symptom.objects.filter(lookup_query))
        if not matched_symptoms:
            return Response({"diseases": []}, status=status.HTTP_200_OK)

        links_queryset = (
            DiseaseSymptom.objects.select_related("disease", "symptom")
            .filter(symptom__in=matched_symptoms)
            .order_by("disease__name", "symptom__name")
        )
        if region:
            eligible_disease_ids = Disease.objects.filter(
                remedies__region=region
            ).values_list("id", flat=True)
            links_queryset = links_queryset.filter(disease_id__in=eligible_disease_ids)
        links = links_queryset.distinct()

        disease_payloads: dict[int, dict] = {}
        for link in links:
            disease_data = disease_payloads.setdefault(
                link.disease_id,
                {
                    "disease": link.disease,
                    "match_score": 0.0,
                    "symptoms": [],
                },
            )
            disease_data["match_score"] += float(link.weight)
            disease_data["symptoms"].append(
                {
                    "id": link.symptom_id,
                    "name": link.symptom.name,
                    "weight": float(link.weight),
                }
            )

        diseases = list(disease_payloads.values())
        for disease in diseases:
            disease["match_score"] = round(disease["match_score"], 2)
            disease["symptoms"].sort(key=lambda item: (-item["weight"], item["name"]))

        diseases.sort(key=lambda item: (-item["match_score"], item["disease"].name))
        disease_items = [
            serialize_disease_preview(
                disease=item["disease"],
                match_score=item["match_score"],
                matched_symptoms=item["symptoms"],
            )
            for item in diseases
        ]

        response_data = {"diseases": disease_items}
        response_serializer = SearchResponseSerializer(data=response_data)
        response_serializer.is_valid(raise_exception=True)
        cache.set(
            cache_key,
            response_serializer.data,
            timeout=get_catalog_cache_timeout(),
        )
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class SymptomListView(APIView):
    @swagger_auto_schema(
        operation_summary="Список симптомов для автодополнения",
        manual_parameters=[
            openapi.Parameter(
                "q",
                openapi.IN_QUERY,
                description="Нечёткий поиск по названию симптома (подстрока).",
                type=openapi.TYPE_STRING,
                required=False,
            )
        ],
        responses={status.HTTP_200_OK: SymptomListSerializer(many=True)},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        query = request.query_params.get("q", "").strip()
        cache_key = build_versioned_cache_key(
            CATALOG_CACHE_NAMESPACE,
            "symptom-list",
            {"query": query.casefold()},
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            return Response(cached_response, status=status.HTTP_200_OK)

        symptoms_queryset = Symptom.objects.all()

        if query:
            query_lower = query.casefold()
            symptoms_queryset = (
                symptoms_queryset.filter(name__icontains=query)
                .annotate(
                    relevance=Case(
                        When(name__iexact=query, then=Value(3)),
                        When(name__istartswith=query, then=Value(2)),
                        default=Value(1),
                        output_field=IntegerField(),
                    ),
                    position=StrIndex(Lower("name"), Value(query_lower)),
                )
                .order_by("-relevance", "position", "name")
            )
        else:
            symptoms_queryset = symptoms_queryset.order_by("name")

        symptoms = list(symptoms_queryset.values("id", "name"))
        serializer = SymptomListSerializer(data=symptoms, many=True)
        serializer.is_valid(raise_exception=True)
        cache.set(cache_key, serializer.data, timeout=get_catalog_cache_timeout())
        return Response(serializer.data, status=status.HTTP_200_OK)


class DiseaseDetailView(APIView):
    @swagger_auto_schema(
        operation_summary="Детальная информация о болезни",
        manual_parameters=[
            openapi.Parameter(
                "disease_id",
                openapi.IN_PATH,
                description="ID болезни",
                type=openapi.TYPE_INTEGER,
                required=True,
            ),
            EVIDENCE_LEVEL_QUERY_PARAM,
            REGION_QUERY_PARAM,
        ],
        responses={
            status.HTTP_200_OK: DiseaseDetailSerializer,
            status.HTTP_404_NOT_FOUND: "Disease not found.",
        },
    )
    def get(self, request, disease_id, *args, **kwargs):  # noqa: ANN002, ANN003
        disease = get_object_or_404(Disease, id=disease_id)
        evidence_codes = parse_evidence_codes(
            request.query_params.get("evidence_level")
        )
        region = parse_region(request.query_params.get("region"))

        remedies = disease.remedies.select_related("evidence_level")
        if evidence_codes:
            remedies = remedies.filter(evidence_level__code__in=evidence_codes)
        if region:
            remedies = remedies.filter(region=region)
        remedies = remedies.order_by("-evidence_level__rank", "name")

        payload = {
            "id": disease.id,
            "name": disease.name,
            "description": disease.description,
            "remedies": [
                {
                    "id": remedy.id,
                    "name": remedy.name,
                    "short_description": make_short_description(remedy.description),
                    "region": remedy.region,
                    "evidence_level": serialize_evidence_level(remedy.evidence_level),
                    "likes_count": remedy.likes_count,
                    "dislikes_count": remedy.dislikes_count,
                }
                for remedy in remedies
            ],
        }
        serializer = DiseaseDetailSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RemedyListView(APIView):
    @swagger_auto_schema(
        operation_summary="Список методов лечения",
        manual_parameters=[
            EVIDENCE_LEVEL_QUERY_PARAM,
            REGION_QUERY_PARAM,
            openapi.Parameter(
                "disease_id",
                openapi.IN_QUERY,
                description="Фильтр по ID болезни.",
                type=openapi.TYPE_INTEGER,
                required=False,
            ),
        ],
        responses={status.HTTP_200_OK: RemedyListResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        remedies = get_remedy_queryset()

        evidence_codes = parse_evidence_codes(
            request.query_params.get("evidence_level")
        )
        if evidence_codes:
            remedies = remedies.filter(evidence_level__code__in=evidence_codes)
        region = parse_region(request.query_params.get("region"))
        if region:
            remedies = remedies.filter(region=region)

        disease_id = request.query_params.get("disease_id")
        if disease_id:
            try:
                remedies = remedies.filter(disease_id=int(disease_id))
            except ValueError as exc:
                raise ValidationError({"disease_id": "Must be an integer."}) from exc

        remedies = remedies.order_by("-evidence_level__rank", "name")
        payload = {"remedies": [serialize_remedy(remedy) for remedy in remedies]}
        serializer = RemedyListResponseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RemedyDetailView(APIView):
    @swagger_auto_schema(
        operation_summary="Детальная информация о методе лечения",
        manual_parameters=[
            openapi.Parameter(
                "remedy_id",
                openapi.IN_PATH,
                description="ID метода лечения",
                type=openapi.TYPE_INTEGER,
                required=True,
            )
        ],
        responses={
            status.HTTP_200_OK: RemedyFullSerializer,
            status.HTTP_404_NOT_FOUND: "Remedy not found.",
        },
    )
    def get(self, request, remedy_id, *args, **kwargs):  # noqa: ANN002, ANN003
        remedy = get_object_or_404(get_remedy_queryset(), id=remedy_id)
        payload = serialize_remedy(remedy)
        serializer = RemedyFullSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RemedyRateView(APIView):
    @swagger_auto_schema(
        operation_summary="Сохранение лайка/дизлайка по методу",
        manual_parameters=[
            openapi.Parameter(
                "remedy_id",
                openapi.IN_PATH,
                description="ID метода лечения",
                type=openapi.TYPE_INTEGER,
                required=True,
            )
        ],
        request_body=RemedyRateRequestSerializer,
        responses={
            status.HTTP_201_CREATED: RemedyRateResponseSerializer,
            status.HTTP_200_OK: RemedyRateResponseSerializer,
            status.HTTP_404_NOT_FOUND: "Remedy not found.",
        },
    )
    def post(self, request, remedy_id, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = RemedyRateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        remedy = get_object_or_404(Remedy, id=remedy_id)
        rating, created = UserRating.objects.update_or_create(
            user_id=serializer.validated_data["user_id"],
            remedy=remedy,
            defaults={
                "is_like": serializer.validated_data["is_like"],
                "comment": serializer.validated_data.get("comment") or "",
            },
        )
        remedy.refresh_from_db(fields=("likes_count", "dislikes_count"))

        response_payload = {
            "id": rating.id,
            "remedy": rating.remedy_id,
            "user_id": rating.user_id,
            "is_like": rating.is_like,
            "comment": rating.comment,
            "created_at": rating.created_at,
            "likes_count": remedy.likes_count,
            "dislikes_count": remedy.dislikes_count,
        }
        response_serializer = RemedyRateResponseSerializer(data=response_payload)
        response_serializer.is_valid(raise_exception=True)

        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=response_status)


class FavoriteListCreateView(APIView):
    @swagger_auto_schema(
        operation_summary="Список избранных методов пользователя",
        manual_parameters=[
            USER_ID_HEADER_PARAM,
            USER_ID_QUERY_PARAM,
            PAGE_QUERY_PARAM,
            PAGE_SIZE_QUERY_PARAM,
        ],
        responses={status.HTTP_200_OK: FavoriteListResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        user_id = resolve_user_id(request)
        page = parse_positive_int(
            request.query_params.get("page"),
            field_name="page",
            default=1,
            max_value=10_000,
        )
        page_size = parse_positive_int(
            request.query_params.get("page_size"),
            field_name="page_size",
            default=20,
            max_value=100,
        )
        offset = (page - 1) * page_size

        favorites_queryset = (
            Favorite.objects.filter(user_id=user_id)
            .select_related("remedy__disease", "remedy__evidence_level")
            .prefetch_related(
                Prefetch(
                    "remedy__remedy_ingredients",
                    queryset=RemedyIngredient.objects.select_related("ingredient"),
                )
            )
            .order_by("-created_at")
        )

        total = favorites_queryset.count()
        favorites = list(favorites_queryset[offset : offset + page_size])
        payload = {
            "page": page,
            "page_size": page_size,
            "total": total,
            "favorites": [
                {
                    "favorited_at": favorite.created_at,
                    "remedy": serialize_remedy(favorite.remedy),
                }
                for favorite in favorites
            ],
        }
        serializer = FavoriteListResponseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    @swagger_auto_schema(
        operation_summary="Добавить метод в избранное",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=FavoriteCreateSerializer,
        responses={
            status.HTTP_201_CREATED: FavoriteItemSerializer,
            status.HTTP_200_OK: FavoriteItemSerializer,
        },
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = FavoriteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = resolve_user_id(
            request,
            fallback=serializer.validated_data.get("user_id"),
        )
        remedy_id = serializer.validated_data["remedy_id"]
        get_object_or_404(Remedy, id=remedy_id)

        favorite, created = Favorite.objects.get_or_create(
            user_id=user_id,
            remedy_id=remedy_id,
        )
        remedy = get_remedy_queryset().get(id=remedy_id)
        payload = {
            "favorited_at": favorite.created_at,
            "remedy": serialize_remedy(remedy),
        }
        response_serializer = FavoriteItemSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=response_status)


class FavoriteDeleteView(APIView):
    @swagger_auto_schema(
        operation_summary="Удалить метод из избранного",
        manual_parameters=[
            openapi.Parameter(
                "remedy_id",
                openapi.IN_PATH,
                description="ID метода лечения",
                type=openapi.TYPE_INTEGER,
                required=True,
            ),
            USER_ID_HEADER_PARAM,
            USER_ID_QUERY_PARAM,
        ],
        responses={
            status.HTTP_204_NO_CONTENT: "Removed from favorites.",
            status.HTTP_404_NOT_FOUND: "Favorite not found.",
        },
    )
    def delete(self, request, remedy_id, *args, **kwargs):  # noqa: ANN002, ANN003
        user_id = resolve_user_id(request)
        deleted_count, _ = Favorite.objects.filter(
            user_id=user_id,
            remedy_id=remedy_id,
        ).delete()
        if deleted_count == 0:
            raise NotFound("Favorite not found.")
        return Response(status=status.HTTP_204_NO_CONTENT)


class HistoryListCreateView(APIView):
    @swagger_auto_schema(
        operation_summary="Записать просмотр метода",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=HistoryCreateSerializer,
        responses={status.HTTP_201_CREATED: HistoryCreateResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = HistoryCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = resolve_user_id(
            request,
            fallback=serializer.validated_data.get("user_id"),
        )
        remedy = get_object_or_404(Remedy, id=serializer.validated_data["remedy_id"])

        history_item = ViewHistory.objects.create(
            user_id=user_id,
            remedy=remedy,
        )
        payload = {
            "id": history_item.id,
            "user_id": history_item.user_id,
            "remedy_id": history_item.remedy_id,
            "viewed_at": history_item.viewed_at,
        }
        response_serializer = HistoryCreateResponseSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @swagger_auto_schema(
        operation_summary="История просмотров пользователя",
        manual_parameters=[
            USER_ID_HEADER_PARAM,
            USER_ID_QUERY_PARAM,
            PAGE_QUERY_PARAM,
            PAGE_SIZE_QUERY_PARAM,
        ],
        responses={status.HTTP_200_OK: HistoryListResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        user_id = resolve_user_id(request)
        page = parse_positive_int(
            request.query_params.get("page"),
            field_name="page",
            default=1,
            max_value=10_000,
        )
        page_size = parse_positive_int(
            request.query_params.get("page_size"),
            field_name="page_size",
            default=20,
            max_value=100,
        )
        offset = (page - 1) * page_size

        history_queryset = (
            ViewHistory.objects.filter(user_id=user_id)
            .select_related("remedy__disease", "remedy__evidence_level")
            .prefetch_related(
                Prefetch(
                    "remedy__remedy_ingredients",
                    queryset=RemedyIngredient.objects.select_related("ingredient"),
                )
            )
            .order_by("-viewed_at")
        )

        total = history_queryset.count()
        history_items = list(history_queryset[offset : offset + page_size])
        payload = {
            "page": page,
            "page_size": page_size,
            "total": total,
            "results": [
                {
                    "viewed_at": history_item.viewed_at,
                    "remedy": serialize_remedy(history_item.remedy),
                }
                for history_item in history_items
            ],
        }
        serializer = HistoryListResponseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class SyncView(APIView):
    @swagger_auto_schema(
        operation_summary="Пакет данных для офлайн-синхронизации",
        responses={status.HTTP_200_OK: SyncResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        cache_key = build_versioned_cache_key(
            CATALOG_CACHE_NAMESPACE,
            "sync",
            {"scope": "full"},
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            response = Response(cached_response, status=status.HTTP_200_OK)
            response["Cache-Control"] = (
                "public, max-age=3600, stale-while-revalidate=86400"
            )
            return response

        payload = {
            "symptoms": list(Symptom.objects.values("id", "name").order_by("name")),
            "diseases": list(Disease.objects.values("id", "name").order_by("name")),
            "evidence_levels": list(
                EvidenceLevel.objects.values(
                    "id",
                    "code",
                    "description",
                    "color",
                    "rank",
                ).order_by("-rank", "code")
            ),
        }
        serializer = SyncResponseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        cache.set(
            cache_key,
            serializer.data,
            timeout=get_catalog_cache_timeout(),
        )

        response = Response(serializer.data, status=status.HTTP_200_OK)
        response["Cache-Control"] = "public, max-age=3600, stale-while-revalidate=86400"
        return response


class PopularDiseaseListView(APIView):
    @swagger_auto_schema(
        operation_summary="Список популярных болезней",
        manual_parameters=[
            openapi.Parameter(
                "limit",
                openapi.IN_QUERY,
                description=(
                    "Количество болезней в ответе " "(по умолчанию 10, максимум 50)."
                ),
                type=openapi.TYPE_INTEGER,
                required=False,
            )
        ],
        responses={status.HTTP_200_OK: PopularDiseaseListResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        limit = parse_positive_int(
            request.query_params.get("limit"),
            field_name="limit",
            default=settings.POPULAR_DISEASES_LIMIT,
            max_value=50,
        )
        cache_key = build_versioned_cache_key(
            CATALOG_CACHE_NAMESPACE,
            "popular-diseases",
            {"limit": limit},
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            return Response(cached_response, status=status.HTTP_200_OK)

        diseases = Disease.objects.annotate(
            popularity_score=Coalesce(Sum("remedies__likes_count"), 0)
            + Coalesce(Sum("remedies__dislikes_count"), 0),
            remedies_count=Count("remedies", distinct=True),
        ).order_by("-popularity_score", "name")[:limit]
        payload = {
            "diseases": [
                serialize_disease_preview(
                    disease=disease,
                    popularity_score=int(disease.popularity_score or 0),
                    remedies_count=int(disease.remedies_count or 0),
                )
                for disease in diseases
            ]
        }
        serializer = PopularDiseaseListResponseSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        cache.set(
            cache_key,
            serializer.data,
            timeout=get_catalog_cache_timeout(),
        )
        return Response(serializer.data, status=status.HTTP_200_OK)


class TermsOfServiceView(APIView):
    @swagger_auto_schema(
        operation_summary="Актуальная версия пользовательского соглашения",
        responses={status.HTTP_200_OK: LegalDocumentSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        cache_key = build_versioned_cache_key(
            LEGAL_CACHE_NAMESPACE,
            "terms-of-service",
            {"scope": "current"},
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            return Response(cached_response, status=status.HTTP_200_OK)

        document = get_current_document(TermsOfService)
        payload = serialize_legal_document(
            document,
            LegalDocumentTypeChoices.TERMS_OF_SERVICE,
        )
        serializer = LegalDocumentSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        cache.set(cache_key, serializer.data, timeout=get_legal_cache_timeout())
        return Response(serializer.data, status=status.HTTP_200_OK)


class PrivacyPolicyView(APIView):
    @swagger_auto_schema(
        operation_summary="Актуальная версия политики конфиденциальности",
        responses={status.HTTP_200_OK: LegalDocumentSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        cache_key = build_versioned_cache_key(
            LEGAL_CACHE_NAMESPACE,
            "privacy-policy",
            {"scope": "current"},
        )
        cached_response = cache.get(cache_key)
        if cached_response is not None:
            return Response(cached_response, status=status.HTTP_200_OK)

        document = get_current_document(PrivacyPolicy)
        payload = serialize_legal_document(
            document,
            LegalDocumentTypeChoices.PRIVACY_POLICY,
        )
        serializer = LegalDocumentSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        cache.set(cache_key, serializer.data, timeout=get_legal_cache_timeout())
        return Response(serializer.data, status=status.HTTP_200_OK)


class UserConsentView(APIView):
    @swagger_auto_schema(
        operation_summary="Зафиксировать согласие пользователя с версией документа",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=UserConsentRequestSerializer,
        responses={
            status.HTTP_201_CREATED: UserConsentResponseSerializer,
            status.HTTP_200_OK: UserConsentResponseSerializer,
        },
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = UserConsentRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = resolve_user_id(
            request,
            fallback=serializer.validated_data.get("user_id"),
        )
        document_type = serializer.validated_data["document_type"]
        version = serializer.validated_data["version"]

        if document_type == LegalDocumentTypeChoices.TERMS_OF_SERVICE:
            get_object_or_404(TermsOfService, version=version)
        else:
            get_object_or_404(PrivacyPolicy, version=version)

        consent, created = UserConsent.objects.get_or_create(
            user_id=user_id,
            document_type=document_type,
            version=version,
        )
        payload = {
            "id": consent.id,
            "user_id": consent.user_id,
            "document_type": consent.document_type,
            "version": consent.version,
            "timestamp": consent.timestamp,
        }
        response_serializer = UserConsentResponseSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=response_status)


class AnalyticsEventView(APIView):
    @swagger_auto_schema(
        operation_summary="Приём аналитических событий с клиента",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=AnalyticsEventRequestSerializer,
        responses={status.HTTP_201_CREATED: AnalyticsEventResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = AnalyticsEventRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = serializer.validated_data.get("user_id")
        if not user_id:
            user_id = request.headers.get("X-User-Id", "").strip()

        event = AnalyticsEvent.objects.create(
            user_id=user_id or "",
            event_type=serializer.validated_data["event_type"],
            metadata=serializer.validated_data.get("metadata", {}),
        )
        payload = {
            "id": event.id,
            "user_id": event.user_id,
            "event_type": event.event_type,
            "metadata": event.metadata,
            "timestamp": event.timestamp,
        }
        response_serializer = AnalyticsEventResponseSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class PushSubscribeView(APIView):
    @swagger_auto_schema(
        operation_summary="Подписка устройства на push-уведомления",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=PushSubscribeRequestSerializer,
        responses={
            status.HTTP_201_CREATED: PushDeviceSerializer,
            status.HTTP_200_OK: PushDeviceSerializer,
        },
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = PushSubscribeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = resolve_user_id(
            request,
            fallback=serializer.validated_data.get("user_id"),
        )
        token = serializer.validated_data["fcm_token"].strip()
        platform = serializer.validated_data["platform"]

        device, created = DeviceRegistration.objects.update_or_create(
            fcm_token=token,
            defaults={
                "user_id": user_id,
                "platform": platform,
                "is_active": True,
            },
        )
        payload = serialize_device(device)
        response_serializer = PushDeviceSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=response_status)


class PushUnsubscribeView(APIView):
    @swagger_auto_schema(
        operation_summary="Отписка устройства от push-уведомлений",
        manual_parameters=[USER_ID_HEADER_PARAM],
        request_body=PushUnsubscribeRequestSerializer,
        responses={status.HTTP_200_OK: PushUnsubscribeResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = PushUnsubscribeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user_id = resolve_user_id(
            request,
            fallback=serializer.validated_data.get("user_id"),
        )
        token = serializer.validated_data["fcm_token"].strip()

        device = get_object_or_404(
            DeviceRegistration,
            user_id=user_id,
            fcm_token=token,
        )
        if device.is_active:
            device.is_active = False
            device.save(update_fields=("is_active", "updated_at", "last_seen_at"))

        response_serializer = PushUnsubscribeResponseSerializer(
            data={"detail": "Device unsubscribed."}
        )
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class PushNotifyView(APIView):
    @swagger_auto_schema(
        operation_summary="Базовая отправка push-уведомления через Firebase",
        manual_parameters=[USER_ID_HEADER_PARAM, USER_ID_QUERY_PARAM],
        request_body=PushNotifyRequestSerializer,
        responses={
            status.HTTP_200_OK: PushNotifyResponseSerializer,
            status.HTTP_503_SERVICE_UNAVAILABLE: "Push service unavailable.",
        },
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = PushNotifyRequestSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)

        user_id: str | None = None
        for candidate in (
            serializer.validated_data.get("user_id"),
            request.headers.get("X-User-Id"),
            request.query_params.get("user_id"),
        ):
            if candidate is None:
                continue
            value = str(candidate).strip()
            if value:
                user_id = value
                break

        tokens: list[str] = []
        explicit_tokens = serializer.validated_data.get("tokens")
        if explicit_tokens:
            tokens.extend([token.strip() for token in explicit_tokens if token.strip()])

        if user_id:
            user_devices = DeviceRegistration.objects.filter(
                user_id=user_id,
                is_active=True,
            )
            tokens.extend(
                list(
                    user_devices.values_list("fcm_token", flat=True),
                )
            )

        deduplicated_tokens: list[str] = []
        seen: set[str] = set()
        for token in tokens:
            if token in seen:
                continue
            deduplicated_tokens.append(token)
            seen.add(token)

        results: list[dict] = []
        if deduplicated_tokens:
            try:
                results = send_push_notifications(
                    tokens=deduplicated_tokens,
                    title=serializer.validated_data["title"],
                    body=serializer.validated_data["body"],
                    data=serializer.validated_data.get("data", {}),
                    dry_run=serializer.validated_data.get("dry_run", False),
                )
            except PushConfigurationError as exc:
                raise PushServiceUnavailable(str(exc)) from exc

        failed_tokens = {
            result["token"] for result in results if result.get("status") == "failed"
        }
        if failed_tokens:
            DeviceRegistration.objects.filter(
                fcm_token__in=failed_tokens,
                is_active=True,
            ).update(is_active=False)

        sent_count = sum(1 for result in results if result.get("status") == "sent")
        failed_count = sum(1 for result in results if result.get("status") == "failed")
        payload = {
            "requested": len(deduplicated_tokens),
            "sent": sent_count,
            "failed": failed_count,
            "results": results,
        }
        response_serializer = PushNotifyResponseSerializer(data=payload)
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data, status=status.HTTP_200_OK)
