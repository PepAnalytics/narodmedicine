from django.test import TestCase

from core.models import Disease, EvidenceLevel, Remedy, UserRating


class UserRatingSignalTests(TestCase):
    def setUp(self) -> None:
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
