from pydantic import BaseModel


class MaintenanceBannerSchema(BaseModel):
    enabled: bool
    title_ar: str | None = None
    title_en: str | None = None
    body_ar: str | None = None
    body_en: str | None = None


class MinAppVersionSchema(BaseModel):
    android: str
    ios: str


class ConfigResponse(BaseModel):
    min_app_version: MinAppVersionSchema
    maintenance_banner: MaintenanceBannerSchema
    feature_flags: dict[str, bool]
