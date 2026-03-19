from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import (
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Ingredient,
    Remedy,
    RemedyIngredient,
    Symptom,
)


class SearchApiTests(APITestCase):
    @classmethod
    def setUpTestData(cls) -> None:
        cls.symptom_headache = Symptom.objects.create(name="Головная боль")
        cls.symptom_nausea = Symptom.objects.create(name="Тошнота")
        cls.symptom_fever = Symptom.objects.create(name="Лихорадка")

        cls.disease_strong = Disease.objects.create(
            name="Грипп",
            description="Описание гриппа",
        )
        cls.disease_balanced = Disease.objects.create(
            name="Мигрень",
            description="Описание мигрени",
        )

        DiseaseSymptom.objects.create(
            disease=cls.disease_strong,
            symptom=cls.symptom_headache,
            weight=3.0,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_balanced,
            symptom=cls.symptom_headache,
            weight=1.0,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_balanced,
            symptom=cls.symptom_nausea,
            weight=1.5,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_balanced,
            symptom=cls.symptom_fever,
            weight=0.5,
        )

    def test_search_returns_sorted_diseases_by_match_score(self) -> None:
        response = self.client.post(
            reverse("search"),
            data={"symptoms": ["Головная боль", "Тошнота"]},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        diseases = response.data["diseases"]
        self.assertEqual(len(diseases), 2)

        self.assertEqual(diseases[0]["name"], "Грипп")
        self.assertEqual(diseases[0]["match_score"], 3.0)
        self.assertEqual(len(diseases[0]["symptoms"]), 1)

        self.assertEqual(diseases[1]["name"], "Мигрень")
        self.assertEqual(diseases[1]["match_score"], 2.5)
        self.assertEqual(len(diseases[1]["symptoms"]), 2)

    def test_search_ignores_unknown_symptoms(self) -> None:
        response = self.client.post(
            reverse("search"),
            data={"symptoms": ["Несуществующий симптом", "Лихорадка"]},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        diseases = response.data["diseases"]
        self.assertEqual(len(diseases), 1)
        self.assertEqual(diseases[0]["name"], "Мигрень")
        self.assertEqual(diseases[0]["match_score"], 0.5)


class SymptomListApiTests(APITestCase):
    @classmethod
    def setUpTestData(cls) -> None:
        Symptom.objects.create(name="Боль в горле")
        Symptom.objects.create(name="Головная боль")
        Symptom.objects.create(name="Лихорадка")

    def test_symptom_list_returns_all_symptoms_sorted(self) -> None:
        response = self.client.get(reverse("symptom-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        symptom_names = [symptom["name"] for symptom in response.data]
        self.assertEqual(
            symptom_names,
            ["Боль в горле", "Головная боль", "Лихорадка"],
        )


class DiseaseAndRemedyApiTests(APITestCase):
    def setUp(self) -> None:
        self.evidence_a = EvidenceLevel.objects.create(
            code="A",
            description="Высокий уровень доказательности",
            color="#2E7D32",
            rank=10,
        )
        self.evidence_c = EvidenceLevel.objects.create(
            code="C",
            description="Ограниченные данные",
            color="#FBC02D",
            rank=5,
        )
        self.disease = Disease.objects.create(
            name="Синусит",
            description="Описание синусита",
        )
        self.remedy_high = Remedy.objects.create(
            disease=self.disease,
            name="Травяной настой при синусите",
            description="Описание настоя",
            recipe="Рецепт настоя",
            risks="Риски настоя",
            source="https://example.org/sinusitis-a",
            evidence_level=self.evidence_a,
        )
        self.remedy_low = Remedy.objects.create(
            disease=self.disease,
            name="Компресс при синусите",
            description="Описание компресса",
            recipe="Рецепт компресса",
            risks="Риски компресса",
            source="https://example.org/sinusitis-c",
            evidence_level=self.evidence_c,
        )
        ingredient = Ingredient.objects.create(
            name="Ромашка",
            description="Описание ромашки",
            contraindications="Индивидуальная непереносимость",
        )
        RemedyIngredient.objects.create(
            remedy=self.remedy_high,
            ingredient=ingredient,
            amount="1 столовая ложка",
        )

    def test_disease_detail_sorts_remedies_by_evidence_rank(self) -> None:
        response = self.client.get(
            reverse("disease-detail", kwargs={"disease_id": self.disease.id})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        remedy_names = [remedy["name"] for remedy in response.data["remedies"]]
        self.assertEqual(
            remedy_names,
            ["Травяной настой при синусите", "Компресс при синусите"],
        )
        self.assertIn("likes_count", response.data["remedies"][0])
        self.assertIn("dislikes_count", response.data["remedies"][0])

    def test_remedy_detail_contains_ingredients_and_counters(self) -> None:
        response = self.client.get(
            reverse("remedy-detail", kwargs={"remedy_id": self.remedy_high.id})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["likes_count"], 0)
        self.assertEqual(response.data["dislikes_count"], 0)
        self.assertEqual(len(response.data["ingredients"]), 1)
        self.assertEqual(response.data["ingredients"][0]["name"], "Ромашка")

    def test_remedy_rate_recalculates_counters(self) -> None:
        url = reverse("remedy-rate", kwargs={"remedy_id": self.remedy_high.id})

        create_response = self.client.post(
            url,
            data={"user_id": "user-1", "is_like": True, "comment": "Помогло"},
            format="json",
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(create_response.data["likes_count"], 1)
        self.assertEqual(create_response.data["dislikes_count"], 0)

        update_response = self.client.post(
            url,
            data={"user_id": "user-1", "is_like": False, "comment": "Передумал"},
            format="json",
        )
        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertEqual(update_response.data["likes_count"], 0)
        self.assertEqual(update_response.data["dislikes_count"], 1)
