"""/v1/config — min-app-version, banner, feature flags."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ... import models, schemas
from ...core.settings import get_settings
from ...db.session import get_db

router = APIRouter()


@router.get("", response_model=schemas.ConfigResponse)
def get_config(db: Session = Depends(get_db)) -> schemas.ConfigResponse:
    settings = get_settings()
    versions = {row.platform: row.min_version for row in db.query(models.MinAppVersion).all()}
    flags = {row.key: bool(row.value_bool) for row in db.query(models.FeatureFlag).all()}
    banner = db.query(models.MaintenanceBanner).first()
    banner_schema = schemas.config.MaintenanceBannerSchema(
        enabled=bool(banner and banner.enabled),
        title_ar=banner.title_ar if banner else None,
        title_en=banner.title_en if banner else None,
        body_ar=banner.body_ar if banner else None,
        body_en=banner.body_en if banner else None,
    )
    return schemas.ConfigResponse(
        min_app_version=schemas.config.MinAppVersionSchema(
            android=versions.get("android", settings.min_app_version_android),
            ios=versions.get("ios", settings.min_app_version_ios),
        ),
        maintenance_banner=banner_schema,
        feature_flags=flags or {"feature.store_enabled": False},
    )
