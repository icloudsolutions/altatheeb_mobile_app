from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from .deps import require_admin

router = APIRouter()


class VersionPayload(BaseModel):
    android: str
    ios: str


@router.get("", response_model=VersionPayload)
def get_versions(
    _: models.AppUser = Depends(require_admin), db: Session = Depends(get_db)
) -> VersionPayload:
    rows = {row.platform: row.min_version for row in db.query(models.MinAppVersion).all()}
    return VersionPayload(
        android=rows.get("android", "1.0.0"),
        ios=rows.get("ios", "1.0.0"),
    )


@router.put("", response_model=VersionPayload)
def set_versions(
    body: VersionPayload,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
) -> VersionPayload:
    for platform, version in (("android", body.android), ("ios", body.ios)):
        row = db.query(models.MinAppVersion).filter_by(platform=platform).one_or_none()
        if not row:
            row = models.MinAppVersion(platform=platform, min_version=version)
            db.add(row)
        else:
            row.min_version = version
    db.commit()
    return body
