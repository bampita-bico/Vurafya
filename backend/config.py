from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql://cdfd:change-me-postgres-password@localhost:5432/cdfd"
    DB_PATH: str = str(Path(__file__).parent.parent / "AfyaFigo.db")  # Legacy support
    JWT_SECRET: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    CORS_ORIGINS: list[str] = ["*"]
    DEBUG: bool = False
    DEMO_EMAIL: str = "director.demo@vurafya.local"
    DEMO_USERNAME: str = "director_demo"
    DEMO_PASSWORD: str = "change-me-demo-password"

    # FlutterWave
    FLW_PUBLIC_KEY: str = ""
    FLW_SECRET_KEY: str = ""
    FLW_SECRET_HASH: str = ""     # Webhook signature verification hash
    APP_BASE_URL: str = "http://localhost:8000"
    RUNTIME_ARTIFACT_ROOT: str = str(Path(__file__).parent.parent / "runtime_runs")
    RUNTIME_REQUIRE_FINITE: bool = True

    # Firebase (FCM push notifications)
    FCM_SERVER_KEY: str = ""      # Firebase server key for sending pushes

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
