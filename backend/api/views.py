from django.db.models import Prefetch, Q
from django.shortcuts import get_object_or_404
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from api.serializers import (
    DiseaseDetailSerializer,
    RemedyDetailSerializer,
    RemedyRateRequestSerializer,
    RemedyRateResponseSerializer,
    SearchRequestSerializer,
    SearchResponseSerializer,
    SymptomListSerializer,
)
from core.models import (
    Disease,
    DiseaseSymptom,
    Remedy,
    RemedyIngredient,
    Symptom,
    UserRating,
)


def serialize_evidence_level(evidence_level) -> dict:
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
        responses={status.HTTP_200_OK: SymptomListSerializer(many=True)},
    )
    def get(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        symptoms = list(Symptom.objects.values("id", "name").order_by("name"))
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
            )
        ],
        responses={
            status.HTTP_200_OK: DiseaseDetailSerializer,
            status.HTTP_404_NOT_FOUND: "Disease not found.",
        },
    )
    def get(self, request, disease_id, *args, **kwargs):  # noqa: ANN002, ANN003
        disease = get_object_or_404(Disease, id=disease_id)
        remedies = disease.remedies.select_related("evidence_level").order_by(
            "-evidence_level__rank",
            "name",
        )

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
            status.HTTP_200_OK: RemedyDetailSerializer,
            status.HTTP_404_NOT_FOUND: "Remedy not found.",
        },
    )
    def get(self, request, remedy_id, *args, **kwargs):  # noqa: ANN002, ANN003
        remedy = get_object_or_404(
            Remedy.objects.select_related("disease", "evidence_level").prefetch_related(
                Prefetch(
                    "remedy_ingredients",
                    queryset=RemedyIngredient.objects.select_related("ingredient"),
                )
            ),
            id=remedy_id,
        )

        payload = {
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

        serializer = RemedyDetailSerializer(data=payload)
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
