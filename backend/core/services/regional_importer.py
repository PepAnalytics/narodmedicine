from __future__ import annotations

import json
from pathlib import Path

from django.db import transaction

from core.models import (
    Disease,
    EvidenceLevel,
    Ingredient,
    Remedy,
    RemedyIngredient,
    Source,
)

DEFAULT_DATASET_PATH = (
    Path(__file__).resolve().parent.parent / "data" / "regional_content.json"
)


def load_regional_dataset(dataset_path: str | None = None) -> dict:
    path = Path(dataset_path) if dataset_path else DEFAULT_DATASET_PATH
    with path.open(encoding="utf-8") as dataset_file:
        return json.load(dataset_file)


def _merge_alternative_names(current: dict, incoming: dict) -> dict:
    merged: dict[str, list[str]] = {
        key: list(values) for key, values in current.items() if isinstance(values, list)
    }
    for locale, names in incoming.items():
        bucket = merged.setdefault(locale, [])
        for name in names:
            if name not in bucket:
                bucket.append(name)
    return merged


class RegionalContentImporter:
    def __init__(self, dataset: dict | None = None, dataset_path: str | None = None):
        self.dataset = dataset or load_regional_dataset(dataset_path)

    @transaction.atomic
    def import_dataset(self, *, reset: bool = False) -> dict[str, int]:
        sources = self.dataset.get("sources", [])
        regions = self.dataset.get("regions", [])

        if reset:
            region_codes = [region["code"] for region in regions]
            source_titles = [source["title"] for source in sources]
            Remedy.objects.filter(region__in=region_codes).delete()
            Source.objects.filter(title__in=source_titles).delete()

        evidence_map = {level.code: level for level in EvidenceLevel.objects.all()}
        source_map = self._import_sources(sources)

        imported_remedies = 0
        imported_sources = len(source_map)
        touched_ingredients: set[int] = set()

        for region_payload in regions:
            region_code = region_payload["code"]
            disease_names = region_payload.get("diseases", [])
            templates = region_payload.get("templates", [])

            diseases = [self._get_or_create_disease(name) for name in disease_names]
            for disease in diseases:
                for template in templates:
                    remedy_name = f"{template['title']} при {disease.name.lower()}"
                    source_record = source_map.get(template["source_title"])
                    evidence_level = evidence_map[template["evidence_code"]]

                    remedy, _ = Remedy.objects.update_or_create(
                        disease=disease,
                        name=remedy_name,
                        defaults={
                            "description": (
                                f"{template['description']} Традиционно описывается "
                                f"для состояния «{disease.name}» как часть культурной "
                                "практики, а не как современный клинический стандарт."
                            ),
                            "recipe": template["recipe"],
                            "risks": template["risks"],
                            "source": source_record.url if source_record else "",
                            "source_record": source_record,
                            "evidence_level": evidence_level,
                            "region": region_code,
                            "cultural_context": template["cultural_context"],
                        },
                    )
                    remedy.remedy_ingredients.all().delete()
                    for ingredient_payload in template.get("ingredients", []):
                        ingredient = self._get_or_create_ingredient(ingredient_payload)
                        touched_ingredients.add(ingredient.id)
                        RemedyIngredient.objects.create(
                            remedy=remedy,
                            ingredient=ingredient,
                            amount=ingredient_payload["amount"],
                        )
                    imported_remedies += 1

        return {
            "sources": imported_sources,
            "ingredients": len(touched_ingredients),
            "remedies": imported_remedies,
        }

    def _import_sources(self, sources: list[dict]) -> dict[str, Source]:
        source_map: dict[str, Source] = {}
        for payload in sources:
            source, _ = Source.objects.update_or_create(
                title=payload["title"],
                author=payload.get("author", ""),
                year=payload.get("year"),
                defaults={
                    "region": payload["region"],
                    "source_type": payload["source_type"],
                    "url": payload.get("url", ""),
                    "reference": payload.get("reference", ""),
                },
            )
            source_map[source.title] = source
        return source_map

    @staticmethod
    def _get_or_create_disease(name: str) -> Disease:
        disease, _ = Disease.objects.update_or_create(
            name=name,
            defaults={
                "description": (
                    f"Состояние «{name}», используемое в расширенном региональном "
                    "демо-наборе для привязки традиционных методов."
                )
            },
        )
        return disease

    @staticmethod
    def _get_or_create_ingredient(payload: dict) -> Ingredient:
        ingredient, created = Ingredient.objects.get_or_create(
            name=payload["name"],
            defaults={
                "description": payload.get(
                    "description",
                    f"Ингредиент регионального набора: {payload['name']}.",
                ),
                "contraindications": payload.get(
                    "contraindications",
                    (
                        "Индивидуальная непереносимость, аллергические реакции, "
                        "беременность или лактация без консультации врача."
                    ),
                ),
                "alternative_names": payload.get("alternative_names", {}),
            },
        )
        if created:
            return ingredient

        merged_names = _merge_alternative_names(
            ingredient.alternative_names or {},
            payload.get("alternative_names", {}),
        )
        update_fields: list[str] = []
        if merged_names != (ingredient.alternative_names or {}):
            ingredient.alternative_names = merged_names
            update_fields.append("alternative_names")
        if not ingredient.description and payload.get("description"):
            ingredient.description = payload["description"]
            update_fields.append("description")
        if not ingredient.contraindications and payload.get("contraindications"):
            ingredient.contraindications = payload["contraindications"]
            update_fields.append("contraindications")
        if update_fields:
            ingredient.save(update_fields=update_fields)
        return ingredient
