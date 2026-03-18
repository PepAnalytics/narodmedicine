from copy import deepcopy

from django.db import transaction
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
)
from core.models import Disease, EvidenceLevel, Remedy, UserRating

SEARCH_SAMPLE = {
    "diseases": [
        {"id": 1, "name": "Мигрень"},
        {"id": 2, "name": "Гастрит"},
        {"id": 3, "name": "ОРВИ"},
    ]
}

DISEASE_SAMPLE = {
    1: {
        "id": 1,
        "name": "Мигрень",
        "description": (
            "Хроническое неврологическое заболевание " "с приступами головной боли."
        ),
        "remedies": [
            {
                "id": 1,
                "name": "Настой мяты",
                "short_description": (
                    "Травяной настой для временного облегчения симптомов."
                ),
                "evidence_level": {
                    "id": 1,
                    "code": "B",
                    "description": "Умеренный уровень доказательности.",
                    "color": "#F4B400",
                },
                "rating": {"likes": 0, "dislikes": 0},
            },
            {
                "id": 2,
                "name": "Точечный массаж",
                "short_description": "Немедикаментозный метод расслабления.",
                "evidence_level": {
                    "id": 2,
                    "code": "C",
                    "description": "Ограниченные доказательства эффективности.",
                    "color": "#DB4437",
                },
                "rating": {"likes": 0, "dislikes": 0},
            },
        ],
    },
    2: {
        "id": 2,
        "name": "Гастрит",
        "description": "Воспаление слизистой оболочки желудка различной этиологии.",
        "remedies": [
            {
                "id": 3,
                "name": "Отвар ромашки",
                "short_description": "Щадящий тёплый напиток для поддержки ЖКТ.",
                "evidence_level": {
                    "id": 3,
                    "code": "B",
                    "description": "Умеренный уровень доказательности.",
                    "color": "#F4B400",
                },
                "rating": {"likes": 0, "dislikes": 0},
            }
        ],
    },
}

REMEDY_SAMPLE = {
    1: {
        "id": 1,
        "disease_id": 1,
        "name": "Настой мяты",
        "description": (
            "Травяной напиток, применяемый в народной практике " "при головной боли."
        ),
        "recipe": "1 ст. ложка сухой мяты на 200 мл горячей воды, настоять 10 минут.",
        "risks": "Не рекомендуется при индивидуальной непереносимости и гипотонии.",
        "source": "https://example.org/mint-remedy",
        "evidence_level": {
            "id": 1,
            "code": "B",
            "description": "Умеренный уровень доказательности.",
            "color": "#F4B400",
        },
        "ingredients": [
            {"id": 1, "name": "Мята", "amount": "1 столовая ложка"},
            {"id": 2, "name": "Вода", "amount": "200 мл"},
        ],
        "rating": {"likes": 0, "dislikes": 0},
    },
    2: {
        "id": 2,
        "disease_id": 1,
        "name": "Точечный массаж",
        "description": "Метод самомассажа для снижения напряжения.",
        "recipe": (
            "Массировать точки у основания черепа " "3-5 минут круговыми движениями."
        ),
        "risks": "Избегать при кожных воспалениях в зоне массажа.",
        "source": "https://example.org/acupressure-remedy",
        "evidence_level": {
            "id": 2,
            "code": "C",
            "description": "Ограниченные доказательства эффективности.",
            "color": "#DB4437",
        },
        "ingredients": [],
        "rating": {"likes": 0, "dislikes": 0},
    },
    3: {
        "id": 3,
        "disease_id": 2,
        "name": "Отвар ромашки",
        "description": "Популярный поддерживающий метод при дискомфорте в желудке.",
        "recipe": "1 ч. ложка ромашки на 250 мл воды, кипятить 5 минут, остудить.",
        "risks": "Осторожно при аллергии на растения семейства астровых.",
        "source": "https://example.org/chamomile-remedy",
        "evidence_level": {
            "id": 3,
            "code": "B",
            "description": "Умеренный уровень доказательности.",
            "color": "#F4B400",
        },
        "ingredients": [
            {"id": 3, "name": "Ромашка", "amount": "1 чайная ложка"},
            {"id": 2, "name": "Вода", "amount": "250 мл"},
        ],
        "rating": {"likes": 0, "dislikes": 0},
    },
}

REMEDY_SEED = {
    1: {
        "disease_name": "Мигрень",
        "disease_description": "Хроническое неврологическое заболевание.",
        "evidence_code": "B",
        "evidence_description": "Умеренный уровень доказательности.",
        "evidence_color": "#F4B400",
    },
    2: {
        "disease_name": "Мигрень",
        "disease_description": "Хроническое неврологическое заболевание.",
        "evidence_code": "C",
        "evidence_description": "Ограниченные доказательства эффективности.",
        "evidence_color": "#DB4437",
    },
    3: {
        "disease_name": "Гастрит",
        "disease_description": "Воспаление слизистой желудка.",
        "evidence_code": "B",
        "evidence_description": "Умеренный уровень доказательности.",
        "evidence_color": "#F4B400",
    },
}


def get_rating_summary(remedy_id: int) -> dict[str, int]:
    likes = UserRating.objects.filter(remedy_id=remedy_id, is_like=True).count()
    dislikes = UserRating.objects.filter(remedy_id=remedy_id, is_like=False).count()
    return {"likes": likes, "dislikes": dislikes}


def attach_rating_to_remedies(payload: dict) -> dict:
    result = deepcopy(payload)
    for remedy in result.get("remedies", []):
        remedy["rating"] = get_rating_summary(remedy["id"])
    return result


def attach_rating_to_remedy(payload: dict) -> dict:
    result = deepcopy(payload)
    result["rating"] = get_rating_summary(result["id"])
    return result


def resolve_remedy_for_rating(remedy_id: int) -> Remedy | None:
    existing = Remedy.objects.filter(id=remedy_id).first()
    if existing:
        return existing

    remedy_data = REMEDY_SAMPLE.get(remedy_id)
    seed_data = REMEDY_SEED.get(remedy_id)
    if not remedy_data or not seed_data:
        return None

    with transaction.atomic():
        disease, _ = Disease.objects.get_or_create(
            name=seed_data["disease_name"],
            defaults={"description": seed_data["disease_description"]},
        )
        evidence_level, _ = EvidenceLevel.objects.get_or_create(
            code=seed_data["evidence_code"],
            defaults={
                "description": seed_data["evidence_description"],
                "color": seed_data["evidence_color"],
            },
        )
        remedy = Remedy.objects.create(
            id=remedy_id,
            disease=disease,
            name=remedy_data["name"],
            description=remedy_data["description"],
            recipe=remedy_data["recipe"],
            risks=remedy_data["risks"],
            source=remedy_data["source"],
            evidence_level=evidence_level,
        )
    return remedy


class SearchView(APIView):
    @swagger_auto_schema(
        operation_summary="Поиск болезней по симптомам",
        request_body=SearchRequestSerializer,
        responses={status.HTTP_200_OK: SearchResponseSerializer},
    )
    def post(self, request, *args, **kwargs):  # noqa: ANN002, ANN003
        serializer = SearchRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        response_serializer = SearchResponseSerializer(data=SEARCH_SAMPLE)
        response_serializer.is_valid(raise_exception=True)
        return Response(response_serializer.data)


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
            status.HTTP_404_NOT_FOUND: "Disease not found in stub dataset.",
        },
    )
    def get(self, request, disease_id, *args, **kwargs):  # noqa: ANN002, ANN003
        payload = DISEASE_SAMPLE.get(disease_id)
        if not payload:
            return Response(
                {"detail": "Disease not found in stub dataset."},
                status=status.HTTP_404_NOT_FOUND,
            )

        payload_with_rating = attach_rating_to_remedies(payload)
        serializer = DiseaseDetailSerializer(data=payload_with_rating)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data)


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
            status.HTTP_404_NOT_FOUND: "Remedy not found in stub dataset.",
        },
    )
    def get(self, request, remedy_id, *args, **kwargs):  # noqa: ANN002, ANN003
        payload = REMEDY_SAMPLE.get(remedy_id)
        if not payload:
            return Response(
                {"detail": "Remedy not found in stub dataset."},
                status=status.HTTP_404_NOT_FOUND,
            )

        payload_with_rating = attach_rating_to_remedy(payload)
        serializer = RemedyDetailSerializer(data=payload_with_rating)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.data)


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

        remedy = resolve_remedy_for_rating(remedy_id)
        if not remedy:
            remedy = get_object_or_404(Remedy, id=remedy_id)

        rating, created = UserRating.objects.update_or_create(
            user_id=serializer.validated_data["user_id"],
            remedy=remedy,
            defaults={
                "is_like": serializer.validated_data["is_like"],
                "comment": serializer.validated_data.get("comment") or "",
            },
        )

        response_payload = {
            "id": rating.id,
            "remedy": rating.remedy_id,
            "user_id": rating.user_id,
            "is_like": rating.is_like,
            "comment": rating.comment,
            "created_at": rating.created_at,
        }
        response_serializer = RemedyRateResponseSerializer(data=response_payload)
        response_serializer.is_valid(raise_exception=True)

        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(response_serializer.data, status=response_status)
