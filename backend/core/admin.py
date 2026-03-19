from django.contrib import admin

from core.models import (
    DeviceRegistration,
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Favorite,
    Ingredient,
    Remedy,
    RemedyIngredient,
    Symptom,
    UserRating,
    ViewHistory,
)


@admin.register(Symptom)
class SymptomAdmin(admin.ModelAdmin):
    list_display = ("id", "name")
    search_fields = ("name", "description")


@admin.register(Disease)
class DiseaseAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "symptoms_count")
    search_fields = ("name", "description")

    @staticmethod
    def symptoms_count(obj: Disease) -> int:
        return obj.symptoms.count()


@admin.register(DiseaseSymptom)
class DiseaseSymptomAdmin(admin.ModelAdmin):
    list_display = ("id", "disease", "symptom", "weight")
    search_fields = ("disease__name", "symptom__name")
    list_filter = ("disease", "symptom")


@admin.register(Ingredient)
class IngredientAdmin(admin.ModelAdmin):
    list_display = ("id", "name")
    search_fields = ("name", "description", "contraindications")


@admin.register(EvidenceLevel)
class EvidenceLevelAdmin(admin.ModelAdmin):
    list_display = ("id", "code", "rank", "color")
    search_fields = ("code", "description")
    list_filter = ("rank",)


class RemedyIngredientInline(admin.TabularInline):
    model = RemedyIngredient
    extra = 1
    autocomplete_fields = ("ingredient",)


@admin.register(Remedy)
class RemedyAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "name",
        "disease",
        "evidence_level",
        "likes_count",
        "dislikes_count",
    )
    search_fields = ("name", "description", "recipe", "disease__name")
    list_filter = ("evidence_level", "disease")
    inlines = (RemedyIngredientInline,)


@admin.register(RemedyIngredient)
class RemedyIngredientAdmin(admin.ModelAdmin):
    list_display = ("id", "remedy", "ingredient", "amount")
    search_fields = ("remedy__name", "ingredient__name", "amount")
    list_filter = ("ingredient",)


@admin.register(UserRating)
class UserRatingAdmin(admin.ModelAdmin):
    list_display = ("id", "remedy", "user_id", "is_like", "created_at")
    search_fields = ("user_id", "comment", "remedy__name")
    list_filter = ("is_like", "created_at")
    readonly_fields = ("created_at",)


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ("id", "user_id", "remedy", "created_at")
    search_fields = ("user_id", "remedy__name")
    list_filter = ("created_at",)
    readonly_fields = ("created_at",)


@admin.register(ViewHistory)
class ViewHistoryAdmin(admin.ModelAdmin):
    list_display = ("id", "user_id", "remedy", "viewed_at")
    search_fields = ("user_id", "remedy__name")
    list_filter = ("viewed_at",)
    readonly_fields = ("viewed_at",)


@admin.register(DeviceRegistration)
class DeviceRegistrationAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user_id",
        "platform",
        "is_active",
        "created_at",
        "last_seen_at",
    )
    search_fields = ("user_id", "fcm_token")
    list_filter = ("platform", "is_active", "created_at")
    readonly_fields = ("created_at", "updated_at", "last_seen_at")
