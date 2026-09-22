from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    DATABASE_URL: str = "postgresql://cdfd:change-me-postgres-password@localhost:5435/cdfd"
    JWT_SECRET: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    DEBUG: bool = False
    DEMO_EMAIL: str = "director.demo@vurafya.local"
    DEMO_USERNAME: str = "director_demo"
    DEMO_PASSWORD: str = "vurafya123"
    DEMO_LOGIN_ENABLED: bool = True
    ENABLE_BACKGROUND_WORKER: bool = False
    ENABLE_MODEL_AUTOMATIONS: bool = False
    RUNTIME_PERSIST_ON_READ: bool = False

    APP_BASE_URL: str = "http://localhost:8000"
    RUNTIME_ARTIFACT_ROOT: str = str(Path(__file__).parent.parent / "runtime_runs")
    RUNTIME_REQUIRE_FINITE: bool = True

    # Firebase (FCM push notifications)
    FCM_SERVER_KEY: str = ""      # Firebase server key for sending pushes

    model_config = {"env_file": ".env", "extra": "ignore"}

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT.strip().lower() in {"production", "prod"}

    def validate_deployment(self) -> None:
        """Reject dangerous defaults when the API is started for production."""
        if not self.is_production:
            return
        if self.JWT_SECRET in {"", "change-this-in-production", "replace-with-a-long-random-string-minimum-32-chars"}:
            raise RuntimeError("JWT_SECRET must be a unique production secret.")
        if len(self.JWT_SECRET) < 32:
            raise RuntimeError("JWT_SECRET must be at least 32 characters in production.")
        if "change-me-" in self.DATABASE_URL:
            raise RuntimeError("DATABASE_URL must not use the example password in production.")
        if "*" in self.CORS_ORIGINS:
            raise RuntimeError("CORS_ORIGINS must name explicit production origins.")
        if self.DEMO_LOGIN_ENABLED:
            raise RuntimeError("DEMO_LOGIN_ENABLED must be false in production.")


settings = Settings()
