"""/v1/children — list and per-child resources."""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ... import models, schemas
from ...db.session import get_db
from ...services.odoo_gateway import OdooGatewayClient
from ..deps import require_parent

router = APIRouter()


@router.get("")
def list_children(
    user: models.AppUser = Depends(require_parent),
):
    if not (user.ems_parent_id and user.odoo_user_id):
        return {"students": []}
    client = OdooGatewayClient()
    try:
        return client.children(user.ems_parent_id, user.odoo_user_id)
    finally:
        client.close()


@router.get("/{student_id}/invoices", response_model=schemas.InvoicesResponse)
def child_invoices(
    student_id: int,
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.InvoicesResponse:
    # Mirror-first read; if mirror is empty (cold start), proxy to gateway.
    rows = (
        db.query(models.EmsInvoice)
        .filter(models.EmsInvoice.student_odoo_id == student_id)
        .order_by(models.EmsInvoice.invoice_date.desc().nullslast())
        .all()
    )
    if rows:
        return schemas.InvoicesResponse(
            invoices=[
                schemas.InvoiceItem(
                    id=r.odoo_id,
                    name=r.name,
                    state=r.state,
                    payment_state=r.payment_state,
                    amount_total=r.amount_total,
                    amount_residual=r.amount_residual,
                    currency=r.currency,
                    invoice_date=r.invoice_date,
                    invoice_date_due=r.invoice_date_due,
                    student_odoo_id=r.student_odoo_id,
                )
                for r in rows
            ]
        )
    if not (user.ems_parent_id and user.odoo_user_id):
        return schemas.InvoicesResponse(invoices=[])
    client = OdooGatewayClient()
    try:
        body = client.child_invoices(user.ems_parent_id, user.odoo_user_id, student_id)
    finally:
        client.close()
    items = []
    for inv in body.get("invoices", []):
        items.append(schemas.InvoiceItem(
            id=inv["id"],
            name=inv["name"],
            state=inv["state"],
            payment_state=inv.get("payment_state"),
            amount_total=float(inv.get("amount_total") or 0.0),
            amount_residual=float(inv.get("amount_residual") or 0.0),
            currency=inv.get("currency"),
            invoice_date=inv.get("invoice_date"),
            invoice_date_due=inv.get("invoice_date_due"),
            student_odoo_id=inv.get("student_id"),
        ))
    return schemas.InvoicesResponse(invoices=items)
