import pytest

from backend.config import Settings
from backend.services import auth_service
from backend.services.auth_service import create_access_token, create_refresh_token, decode_token


def test_production_configuration_rejects_insecure_defaults():
    settings = Settings(
        ENVIRONMENT="production",
        JWT_SECRET="change-this-in-production",
        DATABASE_URL="postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd",
        CORS_ORIGINS=["*"],
        DEMO_LOGIN_ENABLED=True,
    )
    with pytest.raises(RuntimeError):
        settings.validate_deployment()


def test_token_version_is_carried_by_both_token_types(monkeypatch):
    monkeypatch.setattr(auth_service.settings, "JWT_SECRET", "test-secret-that-is-longer-than-thirty-two-characters")
    access = decode_token(create_access_token(9, token_version=3))
    refresh = decode_token(create_refresh_token(9, token_version=3))
    assert access["type"] == "access"
    assert refresh["type"] == "refresh"
    assert access["ver"] == refresh["ver"] == 3
    assert refresh["jti"]
