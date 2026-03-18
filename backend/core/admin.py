from django.contrib import admin

from core.models import (
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Ingredient,
    Remedy,
    RemedyIngredient,
    Symptom,
    UserRating,
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
    list_display = ("id", "code", "color")
    search_fields = ("code", "description")


class RemedyIngredientInline(admin.TabularInline):
    model = RemedyIngredient
    extra = 1
    autocomplete_fields = ("ingredient",)


@admin.register(Remedy)
class RemedyAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "disease", "evidence_level")
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
