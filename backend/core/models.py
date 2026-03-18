from django.core.validators import RegexValidator
from django.db import models


class Symptom(models.Model):
    name = models.CharField(max_length=255, unique=True)
    description = models.TextField(blank=True)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name


class Disease(models.Model):
    name = models.CharField(max_length=255, unique=True)
    description = models.TextField()
    symptoms = models.ManyToManyField(
        Symptom,
        through="DiseaseSymptom",
        related_name="diseases",
    )

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name


class DiseaseSymptom(models.Model):
    disease = models.ForeignKey(
        Disease,
        on_delete=models.CASCADE,
        related_name="disease_symptoms",
    )
    symptom = models.ForeignKey(
        Symptom,
        on_delete=models.CASCADE,
        related_name="symptom_diseases",
    )
    weight = models.FloatField(default=1.0)

    class Meta:
        ordering = ("disease__name", "symptom__name")
        constraints = [
            models.UniqueConstraint(
                fields=("disease", "symptom"),
                name="unique_disease_symptom",
            )
        ]

    def __str__(self) -> str:
        return f"{self.disease} <-> {self.symptom} ({self.weight})"


class Ingredient(models.Model):
    name = models.CharField(max_length=255, unique=True)
    description = models.TextField()
    contraindications = models.TextField(blank=True)

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name


hex_color_validator = RegexValidator(
    regex=r"^#[0-9A-Fa-f]{6}$",
    message="Color should match HEX format, e.g. #22AA77",
)


class EvidenceLevel(models.Model):
    code = models.CharField(max_length=10, unique=True)
    description = models.TextField()
    color = models.CharField(max_length=7, validators=[hex_color_validator])

    class Meta:
        ordering = ("code",)

    def __str__(self) -> str:
        return self.code


class Remedy(models.Model):
    disease = models.ForeignKey(
        Disease,
        on_delete=models.CASCADE,
        related_name="remedies",
    )
    name = models.CharField(max_length=255)
    description = models.TextField()
    recipe = models.TextField()
    risks = models.TextField(blank=True)
    source = models.URLField(max_length=1024, blank=True)
    evidence_level = models.ForeignKey(
        EvidenceLevel,
        on_delete=models.PROTECT,
        related_name="remedies",
    )
    ingredients = models.ManyToManyField(
        Ingredient,
        through="RemedyIngredient",
        related_name="remedies",
    )

    class Meta:
        ordering = ("name",)

    def __str__(self) -> str:
        return self.name


class RemedyIngredient(models.Model):
    remedy = models.ForeignKey(
        Remedy,
        on_delete=models.CASCADE,
        related_name="remedy_ingredients",
    )
    ingredient = models.ForeignKey(
        Ingredient,
        on_delete=models.CASCADE,
        related_name="ingredient_remedies",
    )
    amount = models.CharField(max_length=255)

    class Meta:
        ordering = ("remedy__name", "ingredient__name")
        constraints = [
            models.UniqueConstraint(
                fields=("remedy", "ingredient"),
                name="unique_remedy_ingredient",
            )
        ]

    def __str__(self) -> str:
        return f"{self.remedy} -> {self.ingredient} ({self.amount})"


class UserRating(models.Model):
    user_id = models.CharField(max_length=128)
    remedy = models.ForeignKey(
        Remedy,
        on_delete=models.CASCADE,
        related_name="ratings",
    )
    is_like = models.BooleanField()
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=("user_id", "remedy"),
                name="unique_user_remedy_rating",
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id}: {'like' if self.is_like else 'dislike'}"
