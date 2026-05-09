from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from .deps import require_admin

router = APIRouter()


class AuditItem(BaseModel):
    id: int
    action: str
    actor_user_id: int | None
    actor_role: str | None
    target: str | None
    created_at: str


@router.get("", response_model=list[AuditItem])
def audit(
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
    limit: int = 200,
) -> list[AuditItem]:
    rows = (
        db.query(models.AuditLog)
        .order_by(models.AuditLog.id.desc())
        .limit(limit)
        .all()
    )
    return [
        AuditItem(
            id=r.id,
            action=r.action,
            actor_user_id=r.actor_user_id,
            actor_role=r.actor_role,
            target=r.target,
            created_at=r.created_at.isoformat() if r.created_at else "",
        )
        for r in rows
    ]
