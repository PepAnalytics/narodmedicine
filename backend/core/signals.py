from django.db.models import Count, Q
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from core.models import Remedy, UserRating


def _recalculate_remedy_reactions(remedy_id: int) -> None:
    aggregate = UserRating.objects.filter(remedy_id=remedy_id).aggregate(
        likes=Count("id", filter=Q(is_like=True)),
        dislikes=Count("id", filter=Q(is_like=False)),
    )
    Remedy.objects.filter(id=remedy_id).update(
        likes_count=aggregate["likes"] or 0,
        dislikes_count=aggregate["dislikes"] or 0,
    )


@receiver(post_save, sender=UserRating)
def update_reactions_on_save(
    sender, instance: UserRating, **kwargs
) -> None:  # noqa: ARG001
    _recalculate_remedy_reactions(instance.remedy_id)


@receiver(post_delete, sender=UserRating)
def update_reactions_on_delete(
    sender, instance: UserRating, **kwargs
) -> None:  # noqa: ARG001
    _recalculate_remedy_reactions(instance.remedy_id)
