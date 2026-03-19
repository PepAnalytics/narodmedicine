from django.db.models import Case, IntegerField, Prefetch, Q, Value, When
from django.db.models.functions import Lower, StrIndex
from django.shortcuts import get_object_or_404
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from api.serializers import (
    DiseaseDetailSerializer,
    FavoriteCreateSerializer,
    FavoriteItemSerializer,
    FavoriteListResponseSerializer,
    HistoryCreateResponseSerializer,
    HistoryCreateSerializer,
    HistoryListResponseSerializer,
    RemedyFullSerializer,
    RemedyListResponseSerializer,
    RemedyRateRequestSerializer,
    RemedyRateResponseSerializer,
    SearchRequestSerializer,
    SearchResponseSerializer,
    SymptomListSerializer,
    SyncResponseSerializer,
)
from core.models import (
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Favorite,
    Remedy,
    RemedyIngredient,
    Symptom,
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
    return Remedy.objects.select_related("disease", "evidence_level").prefetch_related(
        Prefetch(
            "remedy_ingredients",
            queryset=RemedyIngredient.objects.select_related("ingredient").order_by(
                "ingredient__name"
            ),
        )
    )


def serialize_remedy(remedy: Remedy) -> dict:
    return {
        "id": remedy.id,
        "disease_id": remedy.disease_id,
        "name": remedy.name,
        "description": remedy.description,
        "recipe": remedy.recipe,
        "risks": remedy.risks,
        "source": remedy.source,
        "evidence_level": serialize_evidence_level(remedy.evidence_level),
        "ingredients": [
            {
                "id": remedy_ingredient.ingredient_id,
                "name": remedy_ingredient.ingredient.name,
                "amount": remedy_ingredient.amount,
            }
            for remedy_ingredient in remedy.remedy_ingredients.all()
        ],
        "likes_count": remedy.likes_count,
        "dislikes_count": remedy.dislikes_count,
    }


class SearchView(APIView):
    @swagger_auto_schema(
        operation_summary="Поиск болезней по симптомам",
        request_body=SearchRequestSerializer,
        responses={status.HTTP_200_OK: SearchResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        request_serializer = SearchRequestSerializer(data=request.data)
        request_serializer.is_valid(raise_exception=True)

        normalized_symptoms = normalize_symptom_names(
            request_serializer.validated_data["symptoms"]
        )
        if not normalized_symptoms:
            return Response({"diseases": []}, status=status.HTTP_200_OK)

        lookup_query = Q()
        for symptom_name in normalized_symptoms:
            lookup_query |= Q(name__iexact=symptom_name)

        matched_symptoms = list(Symptom.objects.filter(lookup_query))
        if not matched_symptoms:
            return Response({"diseases": []}, status=status.HTTP_200_OK)

        links = (
            DiseaseSymptom.objects.select_related("disease", "symptom")
            .filter(symptom__in=matched_symptoms)
            .order_by("disease__name", "symptom__name")
        )

        disease_payloads: dict[int, dict] = {}
        for link in links:
            disease_data = disease_payloads.setdefault(
                link.disease_id,
                {
                    "id": link.disease_id,
                    "name": link.disease.name,
                    "description": link.disease.description,
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

        diseases.sort(key=lambda item: (-item["match_score"], item["name"]))

        response_data = {"diseases": diseases}
        response_serializer = SearchResponseSerializer(data=response_data)
        response_serializer.is_valid(raise_exception=True)
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

        remedies = disease.remedies.select_related("evidence_level")
        if evidence_codes:
            remedies = remedies.filter(evidence_level__code__in=evidence_codes)
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
        manual_parameters=[USER_ID_HEADER_PARAM, USER_ID_QUERY_PARAM],
        responses={status.HTTP_200_OK: FavoriteListResponseSerializer},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        user_id = resolve_user_id(request)
        favorites = (
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

        payload = {
            "favorites": [
                {
                    "favorited_at": favorite.created_at,
                    "remedy": serialize_remedy(favorite.remedy),
                }
                for favorite in favorites
            ]
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
            return Response(
                {"detail": "Favorite not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
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
            openapi.Parameter(
                "page",
                openapi.IN_QUERY,
                description="Номер страницы (начиная с 1).",
                type=openapi.TYPE_INTEGER,
                required=False,
            ),
            openapi.Parameter(
                "page_size",
                openapi.IN_QUERY,
                description="Размер страницы (по умолчанию 20, максимум 100).",
                type=openapi.TYPE_INTEGER,
                required=False,
            ),
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

        response = Response(serializer.data, status=status.HTTP_200_OK)
        response["Cache-Control"] = "public, max-age=3600, stale-while-revalidate=86400"
        return response
