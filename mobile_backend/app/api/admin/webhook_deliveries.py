from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from ...schemas import WebhookEnvelope
from ...services import webhook_dispatcher
from .deps import require_admin

router = APIRouter()


class DeliveryItem(BaseModel):
    id: int
    delivery_id: str
    event: str
    resource: str | None
    status: str
    error: str | None
    received_at: str

    @classmethod
    def from_orm_row(cls, r: models.WebhookDeliveryLog) -> "DeliveryItem":
        return cls(
            id=r.id,
            delivery_id=r.delivery_id,
            event=r.event,
            resource=r.resource,
            status=r.status,
            error=r.error,
            received_at=r.received_at.isoformat() if r.received_at else "",
        )


@router.get("", response_model=list[DeliveryItem])
def list_deliveries(
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
    limit: int = 100,
) -> list[DeliveryItem]:
    rows = (
        db.query(models.WebhookDeliveryLog)
        .order_by(models.WebhookDeliveryLog.id.desc())
        .limit(limit)
        .all()
    )
    return [DeliveryItem.from_orm_row(r) for r in rows]


@router.post("/{delivery_pk}/replay")
def replay(
    delivery_pk: int,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
):
    rec = db.get(models.WebhookDeliveryLog, delivery_pk)
    if not rec or not rec.payload:
        raise HTTPException(404, "not_found")
    env = WebhookEnvelope(**rec.payload)
    status_str = webhook_dispatcher.apply_envelope(db, env)
    rec.status = status_str
    rec.error = None
    db.commit()
    return {"status": status_str}
