from datetime import date
from pydantic import BaseModel


class InvoiceItem(BaseModel):
    id: int
    name: str
    state: str
    payment_state: str | None
    amount_total: float
    amount_residual: float
    currency: str | None
    invoice_date: date | None
    invoice_date_due: date | None
    student_odoo_id: int | None


class InvoicesResponse(BaseModel):
    invoices: list[InvoiceItem]
