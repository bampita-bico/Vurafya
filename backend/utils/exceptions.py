from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class AppException(HTTPException):
    def __init__(self, status_code: int, code: str, message: str, detail=None):
        super().__init__(
            status_code=status_code,
            detail={"error": {"code": code, "message": message, "detail": detail}},
        )


class NotFoundError(AppException):
    def __init__(self, resource: str, id=None):
        super().__init__(404, "not_found", f"{resource} not found", {"id": id})


class AuthenticationError(AppException):
    def __init__(self, message: str = "Invalid credentials"):
        super().__init__(401, "authentication_error", message)


class ForbiddenError(AppException):
    def __init__(self, message: str = "Access denied"):
        super().__init__(403, "forbidden", message)


class FeatureGatedError(AppException):
    def __init__(self, feature: str, required_tier: int):
        tier_names = {1: "Free", 2: "Plus", 3: "Pro"}
        super().__init__(
            403,
            "feature_gated",
            f"This feature requires {tier_names.get(required_tier, 'Unknown')} subscription",
            {"feature": feature, "required_tier": required_tier},
        )


class ValidationError(AppException):
    def __init__(self, message: str, detail=None):
        super().__init__(422, "validation_error", message, detail)
