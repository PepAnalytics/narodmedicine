from __future__ import annotations

import hashlib
import json
from typing import Any

from django.conf import settings
from django.core.cache import cache

CATALOG_CACHE_NAMESPACE = "catalog"
LEGAL_CACHE_NAMESPACE = "legal"


def get_cache_namespace_version(namespace: str) -> int:
    version_key = f"{namespace}:version"
    return cache.get_or_set(version_key, 1, timeout=None)


def build_versioned_cache_key(namespace: str, prefix: str, payload: Any) -> str:
    payload_json = json.dumps(payload, sort_keys=True, ensure_ascii=True)
    payload_hash = hashlib.md5(payload_json.encode("utf-8")).hexdigest()
    version = get_cache_namespace_version(namespace)
    return f"{namespace}:v{version}:{prefix}:{payload_hash}"


def bump_cache_namespace_version(namespace: str) -> None:
    version_key = f"{namespace}:version"
    if cache.get(version_key) is None:
        cache.set(version_key, 2, timeout=None)
        return
    try:
        cache.incr(version_key)
    except ValueError:
        current_version = get_cache_namespace_version(namespace)
        cache.set(version_key, current_version + 1, timeout=None)


def get_catalog_cache_timeout() -> int:
    return getattr(settings, "CATALOG_CACHE_TTL", 3600)


def get_legal_cache_timeout() -> int:
    return getattr(settings, "LEGAL_CACHE_TTL", 3600)
