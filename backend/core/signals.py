from django.db.models.signals import post_delete, post_save
from django.db.models import Count, Q
from django.dispatch import receiver

from core.cache_utils import (
    CATALOG_CACHE_NAMESPACE,
    LEGAL_CACHE_NAMESPACE,
    bump_cache_namespace_version,
)
from core.models import (
    Disease,
    DiseaseSymptom,
    EvidenceLevel,
    Favorite,
    Ingredient,
    PrivacyPolicy,
    Remedy,
    RemedyIngredient,
    Source,
    Symptom,
    TermsOfService,
    UserConsent,
    UserRating,
    ViewHistory,
)


def _recalculate_remedy_reactions(remedy_id: int) -> None:
    aggregate = UserRating.objects.filter(remedy_id=remedy_id).aggregate(
        likes=Count("id", filter=Q(is_like=True)),
        dislikes=Count("id", filter=Q(is_like=False)),
    )
    Remedy.objects.filter(id=remedy_id).update(
        likes_count=aggregate["likes"] or 0,
        dislikes_count=aggregate["dislikes"] or 0,
    )


def _invalidate_catalog_cache() -> None:
    bump_cache_namespace_version(CATALOG_CACHE_NAMESPACE)


def _invalidate_legal_cache() -> None:
    bump_cache_namespace_version(LEGAL_CACHE_NAMESPACE)


@receiver(post_save, sender=UserRating)
def update_reactions_on_save(
    sender, instance: UserRating, **kwargs
) -> None:  # noqa: ARG001
    _recalculate_remedy_reactions(instance.remedy_id)
    _invalidate_catalog_cache()


@receiver(post_delete, sender=UserRating)
def update_reactions_on_delete(
    sender, instance: UserRating, **kwargs
) -> None:  # noqa: ARG001
    _recalculate_remedy_reactions(instance.remedy_id)
    _invalidate_catalog_cache()


CATALOG_INVALIDATION_MODELS = (
    Symptom,
    Disease,
    DiseaseSymptom,
    Ingredient,
    EvidenceLevel,
    Source,
    Remedy,
    RemedyIngredient,
    Favorite,
    ViewHistory,
)

LEGAL_INVALIDATION_MODELS = (
    TermsOfService,
    PrivacyPolicy,
    UserConsent,
)


def invalidate_catalog_cache_on_change(
    sender, **kwargs
) -> None:  # noqa: ANN001, ARG001
    _invalidate_catalog_cache()


def invalidate_legal_cache_on_change(sender, **kwargs) -> None:  # noqa: ANN001, ARG001
    _invalidate_legal_cache()


for catalog_model in CATALOG_INVALIDATION_MODELS:
    post_save.connect(
        invalidate_catalog_cache_on_change,
        sender=catalog_model,
        dispatch_uid=f"catalog-save-{catalog_model._meta.label_lower}",
    )
    post_delete.connect(
        invalidate_catalog_cache_on_change,
        sender=catalog_model,
        dispatch_uid=f"catalog-delete-{catalog_model._meta.label_lower}",
    )


for legal_model in LEGAL_INVALIDATION_MODELS:
    post_save.connect(
        invalidate_legal_cache_on_change,
        sender=legal_model,
        dispatch_uid=f"legal-save-{legal_model._meta.label_lower}",
    )
    post_delete.connect(
        invalidate_legal_cache_on_change,
        sender=legal_model,
        dispatch_uid=f"legal-delete-{legal_model._meta.label_lower}",
    )
