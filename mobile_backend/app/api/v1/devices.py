"""/v1/devices — register / refresh FCM token."""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ... import models, schemas
from ...db.session import get_db
from ..deps import get_current_user

router = APIRouter()


@router.post("", response_model=schemas.DeviceRegisterResponse)
def register(
    body: schemas.DeviceRegisterRequest,
    user: models.AppUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.DeviceRegisterResponse:
    rec = (
        db.query(models.AppDevice)
        .filter(models.AppDevice.user_id == user.id, models.AppDevice.device_id == body.device_id)
        .one_or_none()
    )
    if not rec:
        rec = models.AppDevice(user_id=user.id, device_id=body.device_id, platform=body.platform)
        db.add(rec)
    rec.platform = body.platform
    rec.fcm_token = body.fcm_token
    rec.app_version = body.app_version
    rec.os_version = body.os_version
    rec.locale = body.locale
    rec.last_seen_at = datetime.utcnow()
    db.commit()
    db.refresh(rec)
    return schemas.DeviceRegisterResponse(id=rec.id, ok=True)


@router.delete("/{device_id}", response_model=schemas.OkResponse)
def unregister(
    device_id: int,
    user: models.AppUser = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> schemas.OkResponse:
    rec = db.query(models.AppDevice).filter_by(id=device_id, user_id=user.id).one_or_none()
    if not rec:
        raise HTTPException(404, "not_found")
    db.delete(rec)
    db.commit()
    return schemas.OkResponse()
