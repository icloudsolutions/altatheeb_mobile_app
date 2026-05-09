"""/v1/invoices — single invoice detail and pay-init."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from ..deps import require_parent

router = APIRouter()


@router.get("/{invoice_id}")
def get_invoice(
    invoice_id: int,
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
):
    rec = db.query(models.EmsInvoice).filter_by(odoo_id=invoice_id).one_or_none()
    if not rec:
        raise HTTPException(404, "not_found")
    return {
        "id": rec.odoo_id,
        "name": rec.name,
        "state": rec.state,
        "payment_state": rec.payment_state,
        "amount_total": rec.amount_total,
        "amount_residual": rec.amount_residual,
        "currency": rec.currency,
        "invoice_date": rec.invoice_date.isoformat() if rec.invoice_date else None,
        "invoice_date_due": rec.invoice_date_due.isoformat() if rec.invoice_date_due else None,
        "student_id": rec.student_odoo_id,
        "raw": rec.raw,
    }


@router.post("/{invoice_id}/pay-init")
def pay_init(invoice_id: int, user: models.AppUser = Depends(require_parent)):
    # Hosted-checkout flow: ask the gateway for a payment URL.
    # Implementation lands in sprint 2 once the Odoo payment acquirer is wired.
    return {"payment_url": None, "status": "not_implemented"}
