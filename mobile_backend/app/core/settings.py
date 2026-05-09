"""Runtime settings, sourced from environment / .env."""

from functools import lru_cache
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    app_name: str = "altatheeb-mobile-backend"
    app_env: str = "local"
    log_level: str = "INFO"
    allowed_cors_origins: str = "http://localhost:5173"

    database_url: str = Field(default="postgresql+psycopg2://ems:ems@localhost:5432/ems_mobile")
    redis_url: str = "redis://localhost:6379/0"

    jwt_secret: str = "change-me"
    jwt_alg: str = "HS256"
    jwt_access_ttl: int = 900
    jwt_refresh_ttl: int = 30 * 24 * 3600

    odoo_base_url: str = "http://localhost:8069"
    odoo_service_token: str = ""
    user_context_secret: str = ""
    odoo_inbound_hmac_secret: str = ""

    fcm_project_id: str = ""
    fcm_credentials_path: str = ""

    min_app_version_android: str = "1.0.0"
    min_app_version_ios: str = "1.0.0"

    @property
    def cors_origins(self) -> List[str]:
        return [o.strip() for o in self.allowed_cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
