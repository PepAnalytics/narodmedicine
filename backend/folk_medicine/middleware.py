from __future__ import annotations

import re

from django.conf import settings
from django.http import HttpResponse
from django.utils.cache import patch_vary_headers


class SimpleCORSMiddleware:
    def __init__(self, get_response):  # noqa: ANN001
        self.get_response = get_response

    def __call__(self, request):  # noqa: ANN001, ANN202
        is_preflight = (
            request.method == "OPTIONS"
            and "Origin" in request.headers
            and "Access-Control-Request-Method" in request.headers
        )
        if is_preflight:
            response = HttpResponse(status=200)
        else:
            response = self.get_response(request)

        origin = request.headers.get("Origin")
        if not origin or not self._is_origin_allowed(origin):
            return response

        if settings.CORS_ALLOW_ALL_ORIGINS and not settings.CORS_ALLOW_CREDENTIALS:
            response["Access-Control-Allow-Origin"] = "*"
        else:
            response["Access-Control-Allow-Origin"] = origin
            patch_vary_headers(response, ("Origin",))

        if settings.CORS_ALLOW_CREDENTIALS:
            response["Access-Control-Allow-Credentials"] = "true"

        if settings.CORS_EXPOSE_HEADERS:
            response["Access-Control-Expose-Headers"] = ", ".join(
                settings.CORS_EXPOSE_HEADERS
            )

        if is_preflight:
            response["Access-Control-Allow-Methods"] = ", ".join(
                settings.CORS_ALLOW_METHODS
            )
            response["Access-Control-Allow-Headers"] = ", ".join(
                settings.CORS_ALLOW_HEADERS
            )
            response["Access-Control-Max-Age"] = "86400"

        return response

    def _is_origin_allowed(self, origin: str) -> bool:
        if settings.CORS_ALLOW_ALL_ORIGINS:
            return True
        if origin in settings.CORS_ALLOWED_ORIGINS:
            return True
        return any(
            re.match(pattern, origin)
            for pattern in settings.CORS_ALLOWED_ORIGIN_REGEXES
        )
