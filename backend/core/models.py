from django.core.validators import RegexValidator
from django.db import models


class RegionChoices(models.TextChoices):
    ARAB = "arab", "Arab"
    PERSIAN = "persian", "Persian"
    CAUCASIAN = "caucasian", "Caucasian"
    TURKIC = "turkic", "Turkic"
    CHINESE = "chinese", "Chinese"
    INDIAN = "indian", "Indian"
    OTHER = "other", "Other"


class SourceTypeChoices(models.TextChoices):
    BOOK = "book", "Book"
    WEBSITE = "website", "Website"
    TREATISE = "treatise", "Treatise"
    ARTICLE = "article", "Article"
    ETHNOGRAPHY = "ethnography", "Ethnography"
    ARCHIVE = "archive", "Archive"


class LegalDocumentTypeChoices(models.TextChoices):
    TERMS_OF_SERVICE = "terms_of_service", "Terms of Service"
    PRIVACY_POLICY = "privacy_policy", "Privacy Policy"


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
    alternative_names = models.JSONField(default=dict, blank=True)

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
    rank = models.IntegerField(default=1)

    class Meta:
        ordering = ("-rank", "code")

    def __str__(self) -> str:
        return self.code


class Source(models.Model):
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=255, blank=True)
    year = models.IntegerField(null=True, blank=True)
    region = models.CharField(
        max_length=32,
        choices=RegionChoices.choices,
        default=RegionChoices.OTHER,
    )
    source_type = models.CharField(
        max_length=32,
        choices=SourceTypeChoices.choices,
        default=SourceTypeChoices.BOOK,
    )
    url = models.URLField(max_length=1024, blank=True)
    reference = models.CharField(max_length=1024, blank=True)

    class Meta:
        ordering = ("title", "author")
        constraints = [
            models.UniqueConstraint(
                fields=("title", "author", "year"),
                name="unique_source_record",
            )
        ]

    def __str__(self) -> str:
        return self.title


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
    source_record = models.ForeignKey(
        Source,
        on_delete=models.SET_NULL,
        related_name="remedies",
        null=True,
        blank=True,
    )
    evidence_level = models.ForeignKey(
        EvidenceLevel,
        on_delete=models.PROTECT,
        related_name="remedies",
    )
    region = models.CharField(
        max_length=32,
        choices=RegionChoices.choices,
        default=RegionChoices.OTHER,
    )
    cultural_context = models.TextField(blank=True)
    likes_count = models.IntegerField(default=0)
    dislikes_count = models.IntegerField(default=0)
    ingredients = models.ManyToManyField(
        Ingredient,
        through="RemedyIngredient",
        related_name="remedies",
    )

    class Meta:
        ordering = ("name",)
        indexes = [
            models.Index(fields=("region",), name="remedy_region_idx"),
            models.Index(
                fields=("disease", "region"),
                name="remedy_disease_region_idx",
            ),
        ]

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


class Favorite(models.Model):
    user_id = models.CharField(max_length=128)
    remedy = models.ForeignKey(
        Remedy,
        on_delete=models.CASCADE,
        related_name="favorites",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=("user_id", "remedy"),
                name="unique_user_favorite_remedy",
            )
        ]
        indexes = [
            models.Index(
                fields=("user_id", "-created_at"),
                name="favorite_user_created_idx",
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id} -> {self.remedy_id}"


class ViewHistory(models.Model):
    user_id = models.CharField(max_length=128)
    remedy = models.ForeignKey(
        Remedy,
        on_delete=models.CASCADE,
        related_name="history_items",
    )
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-viewed_at",)
        indexes = [
            models.Index(
                fields=("user_id", "-viewed_at"), name="history_user_viewed_idx"
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id}: {self.remedy_id} at {self.viewed_at.isoformat()}"


class DeviceRegistration(models.Model):
    class Platform(models.TextChoices):
        ANDROID = "android", "Android"
        IOS = "ios", "iOS"
        WEB = "web", "Web"
        OTHER = "other", "Other"

    user_id = models.CharField(max_length=128)
    fcm_token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(
        max_length=16,
        choices=Platform.choices,
        default=Platform.OTHER,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-updated_at",)
        indexes = [
            models.Index(
                fields=("user_id", "is_active"),
                name="device_user_active_idx",
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id} [{self.platform}] active={self.is_active}"


class TermsOfService(models.Model):
    version = models.CharField(max_length=32)
    content = models.TextField()
    effective_from = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-effective_from", "-created_at")
        constraints = [
            models.UniqueConstraint(
                fields=("version",),
                name="unique_terms_version",
            )
        ]

    def __str__(self) -> str:
        return f"Terms v{self.version}"


class PrivacyPolicy(models.Model):
    version = models.CharField(max_length=32)
    content = models.TextField()
    effective_from = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-effective_from", "-created_at")
        constraints = [
            models.UniqueConstraint(
                fields=("version",),
                name="unique_privacy_version",
            )
        ]

    def __str__(self) -> str:
        return f"Privacy v{self.version}"


class UserConsent(models.Model):
    user_id = models.CharField(max_length=128)
    document_type = models.CharField(
        max_length=32,
        choices=LegalDocumentTypeChoices.choices,
    )
    version = models.CharField(max_length=32)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-timestamp",)
        constraints = [
            models.UniqueConstraint(
                fields=("user_id", "document_type", "version"),
                name="unique_user_document_consent",
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id}: {self.document_type} {self.version}"


class AnalyticsEvent(models.Model):
    user_id = models.CharField(max_length=128, blank=True)
    event_type = models.CharField(max_length=128)
    metadata = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-timestamp",)
        indexes = [
            models.Index(
                fields=("event_type", "-timestamp"), name="analytics_event_idx"
            ),
            models.Index(fields=("user_id", "-timestamp"), name="analytics_user_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.event_type} @ {self.timestamp.isoformat()}"
