from typing import Any

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


def _normalize_detail(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: _normalize_detail(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_normalize_detail(item) for item in value]
    return str(value)


def custom_exception_handler(exc, context):  # noqa: ANN001
    response = exception_handler(exc, context)
    if response is None:
        return Response(
            {
                "error": {
                    "code": "server_error",
                    "message": "Internal server error.",
                }
            },
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )

    details = _normalize_detail(response.data)
    message = "Request failed."
    code = "api_error"

    if response.status_code == status.HTTP_400_BAD_REQUEST:
        code = "validation_error"
        message = "Validation error."
    elif response.status_code == status.HTTP_404_NOT_FOUND:
        code = "not_found"
        message = "Resource not found."
    elif response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE:
        code = "service_unavailable"
        message = "Service temporarily unavailable."

    if isinstance(details, dict) and "detail" in details:
        message = str(details["detail"])
    elif isinstance(details, str):
        message = details

    response.data = {
        "error": {
            "code": code,
            "message": message,
            "details": details,
        }
    }
    return response
