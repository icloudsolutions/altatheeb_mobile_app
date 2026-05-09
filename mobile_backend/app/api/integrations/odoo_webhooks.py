"""/integrations/odoo/v1/webhooks — inbound, signed by the Odoo addon."""

import json
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Header, Request, status
from sqlalchemy.orm import Session

from ... import models
from ...core.security import verify_webhook_signature
from ...core.settings import get_settings
from ...db.session import get_db
from ...schemas import WebhookEnvelope
from ...services import notifications, webhook_dispatcher

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/webhooks")
async def receive(
    request: Request,
    x_ems_signature: str | None = Header(None, alias="X-EMS-Signature"),
    x_ems_delivery_id: str | None = Header(None, alias="X-EMS-Delivery-Id"),
    db: Session = Depends(get_db),
):
    settings = get_settings()
    raw = await request.body()

    if not settings.odoo_inbound_hmac_secret:
        raise HTTPException(503, "webhook_secret_not_configured")
    if not x_ems_signature or not verify_webhook_signature(
        raw, x_ems_signature, settings.odoo_inbound_hmac_secret
    ):
        raise HTTPException(401, "invalid_signature")

    try:
        body = json.loads(raw.decode("utf-8") or "{}")
        env = WebhookEnvelope(**body)
    except Exception as exc:
        raise HTTPException(400, f"invalid_payload: {exc}") from exc

    delivery_id = env.delivery_id or (x_ems_delivery_id or "")
    if not delivery_id:
        raise HTTPException(400, "missing_delivery_id")

    existing = (
        db.query(models.WebhookDeliveryLog).filter_by(delivery_id=delivery_id).one_or_none()
    )
    if existing and existing.status == "processed":
        return {"status": "duplicate"}

    log = existing or models.WebhookDeliveryLog(
        delivery_id=delivery_id,
        event=env.event,
        resource=env.resource,
        contract_version=env.integration_contract_version,
        payload=body,
    )
    if not existing:
        db.add(log)
        db.flush()

    try:
        status_str = webhook_dispatcher.apply_envelope(db, env)
        db.flush()
        notifications.maybe_notify(db, env)
        log.status = status_str
        log.processed_at = datetime.utcnow()
        log.error = None
        db.commit()
        return {"status": status_str, "delivery_id": delivery_id}
    except Exception as exc:
        db.rollback()
        log.status = "error"
        log.error = str(exc)[:2000]
        db.merge(log)
        db.commit()
        logger.exception("Failed to apply webhook delivery_id=%s", delivery_id)
        raise HTTPException(status_code=500, detail="processing_failed") from exc
