from unittest.mock import patch

from django.core.cache import cache
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.cache_utils import CATALOG_CACHE_NAMESPACE, build_versioned_cache_key
from core.models import (
    AnalyticsEvent,
    DeviceRegistration,
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Ingredient,
    PrivacyPolicy,
    Remedy,
    RemedyIngredient,
    Source,
    Symptom,
    TermsOfService,
    UserConsent,
)


class BaseApiDataMixin:
    @classmethod
    def setUpTestData(cls) -> None:
        cache.clear()
        cls.evidence_a = EvidenceLevel.objects.create(
            code="A",
            description="Высокий уровень доказательности",
            color="#2E7D32",
            rank=10,
        )
        cls.evidence_c = EvidenceLevel.objects.create(
            code="C",
            description="Ограниченные данные",
            color="#FBC02D",
            rank=5,
        )
        cls.source_arab = Source.objects.create(
            title="Arab source",
            author="Author A",
            year=1200,
            region="arab",
            source_type="book",
            reference="Reference A",
        )
        cls.source_chinese = Source.objects.create(
            title="Chinese source",
            author="Author C",
            year=1600,
            region="chinese",
            source_type="treatise",
            reference="Reference C",
        )

        cls.disease_flu = Disease.objects.create(
            name="Грипп",
            description="Описание гриппа",
        )
        cls.disease_migraine = Disease.objects.create(
            name="Мигрень",
            description="Описание мигрени",
        )

        cls.symptom_headache = Symptom.objects.create(name="Головная боль")
        cls.symptom_nausea = Symptom.objects.create(name="Тошнота")
        cls.symptom_fever = Symptom.objects.create(name="Лихорадка")
        cls.symptom_head_spin = Symptom.objects.create(name="Сильная головная боль")
        cls.symptom_throat = Symptom.objects.create(name="Боль в горле")

        DiseaseSymptom.objects.create(
            disease=cls.disease_flu,
            symptom=cls.symptom_headache,
            weight=3.0,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_migraine,
            symptom=cls.symptom_headache,
            weight=1.0,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_migraine,
            symptom=cls.symptom_nausea,
            weight=1.5,
        )
        DiseaseSymptom.objects.create(
            disease=cls.disease_migraine,
            symptom=cls.symptom_fever,
            weight=0.5,
        )

        cls.remedy_flu = Remedy.objects.create(
            disease=cls.disease_flu,
            name="Травяной настой при гриппе",
            description="Описание настоя при гриппе",
            recipe="Рецепт настоя",
            risks="Риски настоя",
            source="https://example.org/remedy-flu",
            region="other",
            cultural_context="Базовый контекст",
            evidence_level=cls.evidence_a,
        )
        cls.remedy_migraine_high = Remedy.objects.create(
            disease=cls.disease_migraine,
            name="Настой мяты при мигрени",
            description="Описание настоя мяты",
            recipe="Рецепт мяты",
            risks="Риски мяты",
            source="https://example.org/remedy-migraine-a",
            source_record=cls.source_arab,
            region="arab",
            cultural_context="Культурный контекст арабской традиции",
            evidence_level=cls.evidence_a,
        )
        cls.remedy_migraine_low = Remedy.objects.create(
            disease=cls.disease_migraine,
            name="Компресс при мигрени",
            description="Описание компресса",
            recipe="Рецепт компресса",
            risks="Риски компресса",
            source="https://example.org/remedy-migraine-c",
            source_record=cls.source_chinese,
            region="chinese",
            cultural_context="Культурный контекст китайской традиции",
            evidence_level=cls.evidence_c,
        )

        cls.ingredient_mint = Ingredient.objects.create(
            name="Мята",
            description="Описание мяты",
            contraindications="Индивидуальная непереносимость",
            alternative_names={"ar": ["nana"], "zh": ["bo he"]},
        )
        cls.ingredient_water = Ingredient.objects.create(
            name="Вода",
            description="Описание воды",
            contraindications="",
            alternative_names={"ar": ["maa"]},
        )
        RemedyIngredient.objects.create(
            remedy=cls.remedy_migraine_high,
            ingredient=cls.ingredient_mint,
            amount="1 столовая ложка",
        )
        RemedyIngredient.objects.create(
            remedy=cls.remedy_migraine_high,
            ingredient=cls.ingredient_water,
            amount="250 мл",
        )


class SearchApiTests(BaseApiDataMixin, APITestCase):
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
        self.assertEqual(diseases[0]["description"], diseases[0]["short_description"])
        self.assertEqual(diseases[0]["symptoms"], diseases[0]["matched_symptoms"])
        self.assertEqual(diseases[1]["name"], "Мигрень")
        self.assertEqual(diseases[1]["match_score"], 2.5)

    def test_search_ignores_unknown_symptoms(self) -> None:
        response = self.client.post(
            reverse("search"),
            data={"symptoms": ["Несуществующий симптом", "Лихорадка"]},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["diseases"]), 1)
        self.assertEqual(response.data["diseases"][0]["name"], "Мигрень")

    def test_search_filters_by_region(self) -> None:
        response = self.client.post(
            f"{reverse('search')}?region=arab",
            data={"symptoms": ["Головная боль", "Тошнота"]},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        diseases = response.data["diseases"]
        self.assertEqual(len(diseases), 1)
        self.assertEqual(diseases[0]["name"], "Мигрень")


class SymptomListApiTests(BaseApiDataMixin, APITestCase):
    def test_symptom_list_returns_all_symptoms_sorted_without_query(self) -> None:
        response = self.client.get(reverse("symptom-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item["name"] for item in response.data]
        self.assertEqual(names, sorted(names))

    def test_symptom_list_supports_fuzzy_query_and_relevance(self) -> None:
        response = self.client.get(reverse("symptom-list"), {"q": "головная"})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item["name"] for item in response.data]
        self.assertEqual(names[0], "Головная боль")
        self.assertIn("Сильная головная боль", names)
        self.assertNotIn("Боль в горле", names)

    def test_symptom_list_populates_cache(self) -> None:
        response = self.client.get(reverse("symptom-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        cache_key = build_versioned_cache_key(
            CATALOG_CACHE_NAMESPACE,
            "symptom-list",
            {"query": ""},
        )
        self.assertIsNotNone(cache.get(cache_key))


class DiseaseAndRemedyApiTests(BaseApiDataMixin, APITestCase):
    def test_disease_detail_filters_by_evidence_level(self) -> None:
        response = self.client.get(
            reverse("disease-detail", kwargs={"disease_id": self.disease_migraine.id}),
            {"evidence_level": "C"},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        remedies = response.data["remedies"]
        self.assertEqual(len(remedies), 1)
        self.assertEqual(remedies[0]["name"], "Компресс при мигрени")
        self.assertEqual(remedies[0]["evidence_level"]["code"], "C")
        self.assertEqual(remedies[0]["region"], "chinese")

    def test_remedy_list_filters_by_evidence_disease_and_region(self) -> None:
        response = self.client.get(
            reverse("remedy-list"),
            {
                "evidence_level": "A",
                "disease_id": self.disease_migraine.id,
                "region": "arab",
            },
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        remedies = response.data["remedies"]
        self.assertEqual(len(remedies), 1)
        self.assertEqual(remedies[0]["name"], "Настой мяты при мигрени")
        self.assertEqual(remedies[0]["region"], "arab")

    def test_remedy_detail_contains_region_source_and_ingredient_aliases(self) -> None:
        response = self.client.get(
            reverse("remedy-detail", kwargs={"remedy_id": self.remedy_migraine_high.id})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["likes_count"], 0)
        self.assertEqual(response.data["dislikes_count"], 0)
        self.assertEqual(len(response.data["ingredients"]), 2)
        self.assertEqual(response.data["region"], "arab")
        self.assertEqual(
            response.data["source_record"]["title"],
            self.source_arab.title,
        )
        self.assertIn("ar", response.data["ingredients"][0]["alternative_names"])

    def test_remedy_rate_recalculates_counters(self) -> None:
        url = reverse("remedy-rate", kwargs={"remedy_id": self.remedy_migraine_high.id})

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


class FavoriteApiTests(BaseApiDataMixin, APITestCase):
    USER_ID = "favorite-user"

    def test_favorite_lifecycle(self) -> None:
        create_response = self.client.post(
            reverse("favorite-list-create"),
            data={"remedy_id": self.remedy_migraine_high.id},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)

        list_response = self.client.get(
            reverse("favorite-list-create"),
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data["page"], 1)
        self.assertEqual(list_response.data["page_size"], 20)
        self.assertEqual(list_response.data["total"], 1)
        self.assertEqual(len(list_response.data["favorites"]), 1)
        self.assertEqual(
            list_response.data["favorites"][0]["remedy"]["id"],
            self.remedy_migraine_high.id,
        )

        delete_response = self.client.delete(
            reverse(
                "favorite-delete",
                kwargs={"remedy_id": self.remedy_migraine_high.id},
            ),
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)

    def test_favorites_requires_user_id(self) -> None:
        response = self.client.get(reverse("favorite-list-create"))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["error"]["code"], "validation_error")
        self.assertIn("user_id", response.data["error"]["details"])

    def test_favorites_returns_paginated_results(self) -> None:
        self.client.post(
            reverse("favorite-list-create"),
            data={"remedy_id": self.remedy_flu.id},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.client.post(
            reverse("favorite-list-create"),
            data={"remedy_id": self.remedy_migraine_high.id},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )

        response = self.client.get(
            reverse("favorite-list-create"),
            {"page": 1, "page_size": 1},
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["page"], 1)
        self.assertEqual(response.data["page_size"], 1)
        self.assertEqual(response.data["total"], 2)
        self.assertEqual(len(response.data["favorites"]), 1)

    def test_favorite_delete_returns_standard_not_found_error(self) -> None:
        response = self.client.delete(
            reverse("favorite-delete", kwargs={"remedy_id": 99999}),
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertEqual(response.data["error"]["code"], "not_found")


class HistoryApiTests(BaseApiDataMixin, APITestCase):
    USER_ID = "history-user"

    def test_history_records_and_returns_paginated_results(self) -> None:
        create_url = reverse("history-list-create")

        first = self.client.post(
            create_url,
            data={"remedy_id": self.remedy_flu.id},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        second = self.client.post(
            create_url,
            data={"remedy_id": self.remedy_migraine_high.id},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(first.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second.status_code, status.HTTP_201_CREATED)

        page_response = self.client.get(
            create_url,
            {"page": 1, "page_size": 1},
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(page_response.status_code, status.HTTP_200_OK)
        self.assertEqual(page_response.data["total"], 2)
        self.assertEqual(page_response.data["page"], 1)
        self.assertEqual(page_response.data["page_size"], 1)
        self.assertEqual(len(page_response.data["results"]), 1)
        self.assertEqual(
            page_response.data["results"][0]["remedy"]["id"],
            self.remedy_migraine_high.id,
        )

    def test_history_requires_user_id(self) -> None:
        response = self.client.get(reverse("history-list-create"))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["error"]["code"], "validation_error")
        self.assertIn("user_id", response.data["error"]["details"])

    def test_history_validates_page_size(self) -> None:
        response = self.client.get(
            reverse("history-list-create"),
            {"page_size": 0},
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["error"]["code"], "validation_error")
        self.assertIn("page_size", response.data["error"]["details"])


class SyncApiTests(BaseApiDataMixin, APITestCase):
    def test_sync_returns_offline_payload_and_cache_headers(self) -> None:
        response = self.client.get(reverse("sync"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("symptoms", response.data)
        self.assertIn("diseases", response.data)
        self.assertIn("evidence_levels", response.data)
        self.assertIn("Cache-Control", response.headers)
        self.assertIn("max-age", response.headers["Cache-Control"])


class PopularDiseaseApiTests(BaseApiDataMixin, APITestCase):
    def test_popular_diseases_returns_ranked_items(self) -> None:
        rate_url = reverse(
            "remedy-rate", kwargs={"remedy_id": self.remedy_migraine_high.id}
        )
        self.client.post(
            rate_url,
            data={"user_id": "u-1", "is_like": True},
            format="json",
        )
        self.client.post(
            reverse("remedy-rate", kwargs={"remedy_id": self.remedy_migraine_low.id}),
            data={"user_id": "u-2", "is_like": False},
            format="json",
        )

        response = self.client.get(reverse("popular-disease-list"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data["diseases"]), 1)
        self.assertEqual(response.data["diseases"][0]["name"], "Мигрень")
        self.assertEqual(
            response.data["diseases"][0]["description"],
            response.data["diseases"][0]["short_description"],
        )
        self.assertGreaterEqual(response.data["diseases"][0]["remedies_count"], 1)


class LegalApiTests(APITestCase):
    USER_ID = "legal-user"

    @classmethod
    def setUpTestData(cls) -> None:
        cache.clear()
        now = timezone.now()
        cls.terms = TermsOfService.objects.create(
            version="1.0",
            content="Terms v1",
            effective_from=now,
        )
        cls.privacy = PrivacyPolicy.objects.create(
            version="1.0",
            content="Privacy v1",
            effective_from=now,
        )

    def test_terms_endpoint_returns_current_document(self) -> None:
        response = self.client.get(reverse("legal-terms"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["document_type"], "terms_of_service")
        self.assertEqual(response.data["version"], self.terms.version)

    def test_privacy_endpoint_returns_current_document(self) -> None:
        response = self.client.get(reverse("legal-privacy"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["document_type"], "privacy_policy")
        self.assertEqual(response.data["version"], self.privacy.version)

    def test_consent_endpoint_records_agreement(self) -> None:
        response = self.client.post(
            reverse("legal-consent"),
            data={
                "document_type": "terms_of_service",
                "version": "1.0",
            },
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(UserConsent.objects.count(), 1)
        self.assertEqual(response.data["document_type"], "terms_of_service")


class AnalyticsApiTests(APITestCase):
    def test_analytics_endpoint_stores_event(self) -> None:
        response = self.client.post(
            reverse("analytics"),
            data={
                "event_type": "screen_view",
                "metadata": {"screen": "remedy_detail"},
            },
            format="json",
            HTTP_X_USER_ID="analytics-user",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(AnalyticsEvent.objects.count(), 1)
        self.assertEqual(response.data["event_type"], "screen_view")
        self.assertEqual(response.data["user_id"], "analytics-user")


class PushApiTests(BaseApiDataMixin, APITestCase):
    USER_ID = "push-user"

    def test_push_subscribe_and_unsubscribe(self) -> None:
        subscribe_url = reverse("push-subscribe")
        unsubscribe_url = reverse("push-unsubscribe")

        subscribe_response = self.client.post(
            subscribe_url,
            data={"fcm_token": "token-1", "platform": "android"},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(subscribe_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(DeviceRegistration.objects.count(), 1)
        device = DeviceRegistration.objects.get()
        self.assertTrue(device.is_active)
        self.assertEqual(device.platform, "android")

        unsubscribe_response = self.client.post(
            unsubscribe_url,
            data={"fcm_token": "token-1"},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )
        self.assertEqual(unsubscribe_response.status_code, status.HTTP_200_OK)
        device.refresh_from_db()
        self.assertFalse(device.is_active)

    @patch("api.views.send_push_notifications")
    def test_push_notify_delivers_to_user_devices(self, send_mock) -> None:
        DeviceRegistration.objects.create(
            user_id=self.USER_ID,
            fcm_token="token-user-1",
            platform="android",
            is_active=True,
        )
        send_mock.return_value = [
            {
                "token": "token-user-1",
                "status": "sent",
                "message_id": "m-1",
            }
        ]

        response = self.client.post(
            reverse("push-notify"),
            data={"title": "Тест", "body": "Проверьте уведомление"},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["requested"], 1)
        self.assertEqual(response.data["sent"], 1)
        self.assertEqual(response.data["failed"], 0)
        send_mock.assert_called_once()

    @patch("api.views.send_push_notifications")
    def test_push_notify_marks_failed_tokens_inactive(self, send_mock) -> None:
        DeviceRegistration.objects.create(
            user_id=self.USER_ID,
            fcm_token="token-user-2",
            platform="ios",
            is_active=True,
        )
        send_mock.return_value = [
            {
                "token": "token-user-2",
                "status": "failed",
                "error": "registration token not registered",
            }
        ]

        response = self.client.post(
            reverse("push-notify"),
            data={"title": "Тест", "body": "Проверьте уведомление"},
            format="json",
            HTTP_X_USER_ID=self.USER_ID,
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["failed"], 1)
        device = DeviceRegistration.objects.get(fcm_token="token-user-2")
        self.assertFalse(device.is_active)

    @patch("api.views.send_push_notifications")
    def test_push_notify_returns_service_unavailable_when_config_missing(
        self,
        send_mock,
    ) -> None:
        from api.push_service import PushConfigurationError

        send_mock.side_effect = PushConfigurationError("Missing credentials")

        response = self.client.post(
            reverse("push-notify"),
            data={
                "title": "Тест",
                "body": "Проверьте уведомление",
                "tokens": ["token-a"],
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertEqual(response.data["error"]["code"], "service_unavailable")

    def test_push_notify_requires_target(self) -> None:
        response = self.client.post(
            reverse("push-notify"),
            data={"title": "Тест", "body": "Без таргета"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data["error"]["code"], "validation_error")
