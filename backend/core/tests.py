from django.core.cache import cache
from django.test import TestCase

from core.cache_utils import CATALOG_CACHE_NAMESPACE, get_cache_namespace_version
from core.models import Disease, EvidenceLevel, Remedy, Source, UserRating
from core.services.regional_importer import RegionalContentImporter


class UserRatingSignalTests(TestCase):
    def setUp(self) -> None:
        cache.clear()
        self.disease = Disease.objects.create(
            name="Мигрень",
            description="Описание мигрени",
        )
        self.evidence = EvidenceLevel.objects.create(
            code="B",
            description="Умеренный уровень доказательности",
            color="#66BB6A",
            rank=7,
        )
        self.remedy = Remedy.objects.create(
            disease=self.disease,
            name="Настой мяты",
            description="Описание",
            recipe="Рецепт",
            risks="Риски",
            source="https://example.org/remedy",
            evidence_level=self.evidence,
        )

    def test_reactions_are_recalculated_after_rating_changes(self) -> None:
        rating = UserRating.objects.create(
            user_id="u-1",
            remedy=self.remedy,
            is_like=True,
            comment="ok",
        )
        self.remedy.refresh_from_db()
        self.assertEqual(self.remedy.likes_count, 1)
        self.assertEqual(self.remedy.dislikes_count, 0)

        rating.is_like = False
        rating.save(update_fields=("is_like",))
        self.remedy.refresh_from_db()
        self.assertEqual(self.remedy.likes_count, 0)
        self.assertEqual(self.remedy.dislikes_count, 1)

        rating.delete()
        self.remedy.refresh_from_db()
        self.assertEqual(self.remedy.likes_count, 0)
        self.assertEqual(self.remedy.dislikes_count, 0)

    def test_catalog_cache_version_changes_after_rating(self) -> None:
        initial_version = get_cache_namespace_version(CATALOG_CACHE_NAMESPACE)

        UserRating.objects.create(
            user_id="u-1",
            remedy=self.remedy,
            is_like=True,
            comment="ok",
        )

        updated_version = get_cache_namespace_version(CATALOG_CACHE_NAMESPACE)
        self.assertGreater(updated_version, initial_version)


class RegionalContentImporterTests(TestCase):
    def setUp(self) -> None:
        self.disease = Disease.objects.create(
            name="Гастрит",
            description="Описание гастрита",
        )
        for code, color, rank in (
            ("A", "#2E7D32", 10),
            ("B", "#66BB6A", 7),
            ("C", "#FBC02D", 5),
            ("D", "#FB8C00", 3),
            ("E", "#E53935", 1),
        ):
            EvidenceLevel.objects.create(
                code=code,
                description=f"Level {code}",
                color=color,
                rank=rank,
            )

    def test_importer_creates_sources_and_regional_remedy(self) -> None:
        dataset = {
            "sources": [
                {
                    "title": "Test source",
                    "author": "Author",
                    "year": 1900,
                    "region": "arab",
                    "source_type": "book",
                    "reference": "Reference",
                    "url": "",
                }
            ],
            "regions": [
                {
                    "code": "arab",
                    "diseases": ["Гастрит"],
                    "templates": [
                        {
                            "title": "Тестовый настой",
                            "description": "Описание",
                            "recipe": "Рецепт",
                            "risks": "Риски",
                            "cultural_context": "Контекст",
                            "evidence_code": "E",
                            "source_title": "Test source",
                            "ingredients": [
                                {
                                    "name": "Тестовая трава",
                                    "amount": "1 чайная ложка",
                                    "alternative_names": {"ar": ["test-name"]},
                                }
                            ],
                        }
                    ],
                }
            ],
        }

        result = RegionalContentImporter(dataset=dataset).import_dataset(reset=False)

        self.assertEqual(result["sources"], 1)
        self.assertEqual(result["remedies"], 1)
        self.assertEqual(Source.objects.count(), 1)
        remedy = Remedy.objects.get(name="Тестовый настой при гастрит")
        self.assertEqual(remedy.region, "arab")
        self.assertEqual(remedy.source_record.title, "Test source")

    def test_bundled_dataset_imports_at_least_thirty_remedies_per_region(self) -> None:
        RegionalContentImporter().import_dataset(reset=False)

        region_counts = {
            region: Remedy.objects.filter(region=region).count()
            for region in (
                "arab",
                "persian",
                "caucasian",
                "turkic",
                "chinese",
                "indian",
            )
        }

        for count in region_counts.values():
            self.assertGreaterEqual(count, 30)
