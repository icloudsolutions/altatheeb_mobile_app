from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from .deps import require_admin

router = APIRouter()


class FlagItem(BaseModel):
    key: str
    value_bool: bool
    description: str | None = None


@router.get("", response_model=list[FlagItem])
def list_flags(
    _: models.AppUser = Depends(require_admin), db: Session = Depends(get_db)
) -> list[FlagItem]:
    return [
        FlagItem(key=f.key, value_bool=f.value_bool, description=f.description)
        for f in db.query(models.FeatureFlag).all()
    ]


@router.put("/{key}", response_model=FlagItem)
def upsert_flag(
    key: str,
    body: FlagItem,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
) -> FlagItem:
    flag = db.query(models.FeatureFlag).filter_by(key=key).one_or_none()
    if not flag:
        flag = models.FeatureFlag(key=key)
        db.add(flag)
    flag.value_bool = bool(body.value_bool)
    flag.description = body.description
    db.commit()
    db.refresh(flag)
    return FlagItem(key=flag.key, value_bool=flag.value_bool, description=flag.description)
