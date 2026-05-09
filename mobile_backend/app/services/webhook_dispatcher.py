"""Apply incoming webhook envelopes to the mirror tables."""

from datetime import date, datetime
from typing import Any, Dict

from sqlalchemy.orm import Session

from .. import models
from ..schemas import WebhookEnvelope


def _parse_date(s: str | None) -> date | None:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).date()
    except ValueError:
        return None


def _parse_datetime(s: str | None) -> datetime | None:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def _upsert_student(db: Session, odoo_id: int, env: WebhookEnvelope, data: Dict[str, Any]) -> None:
    rec = db.query(models.EmsStudent).filter_by(odoo_id=odoo_id).one_or_none()
    if not rec:
        rec = models.EmsStudent(odoo_id=odoo_id)
        db.add(rec)
    rec.name = data.get("name") or rec.name or ""
    rec.name_en = data.get("name_en")
    rec.student_number = data.get("student_number")
    rec.grade_id = data.get("grade_id")
    rec.division_id = data.get("division_id")
    rec.school_id = env.school_id
    rec.state = data.get("state")
    rec.write_date = _parse_datetime(data.get("write_date"))
    rec.raw = data


def _upsert_invoice(db: Session, odoo_id: int, env: WebhookEnvelope, data: Dict[str, Any]) -> None:
    rec = db.query(models.EmsInvoice).filter_by(odoo_id=odoo_id).one_or_none()
    if not rec:
        rec = models.EmsInvoice(odoo_id=odoo_id, name=data.get("name") or "")
        db.add(rec)
    rec.name = data.get("name") or rec.name or ""
    rec.state = data.get("state") or rec.state
    rec.payment_state = data.get("payment_state")
    rec.amount_total = float(data.get("amount_total") or 0.0)
    rec.amount_residual = float(data.get("amount_residual") or 0.0)
    rec.currency = data.get("currency")
    rec.invoice_date = _parse_date(data.get("invoice_date"))
    rec.invoice_date_due = _parse_date(data.get("invoice_date_due"))
    rec.student_odoo_id = data.get("student_id")
    rec.school_id = env.school_id
    rec.write_date = _parse_datetime(data.get("write_date"))
    rec.raw = data


def _upsert_attendance(db: Session, odoo_id: int, env: WebhookEnvelope, data: Dict[str, Any]) -> None:
    rec = db.query(models.EmsAttendance).filter_by(odoo_id=odoo_id).one_or_none()
    if not rec:
        rec = models.EmsAttendance(
            odoo_id=odoo_id,
            student_odoo_id=data.get("student_id") or 0,
            date=_parse_date(data.get("date")) or date.today(),
            status=data.get("status") or "present",
        )
        db.add(rec)
    rec.student_odoo_id = data.get("student_id") or rec.student_odoo_id
    rec.date = _parse_date(data.get("date")) or rec.date
    rec.status = data.get("status") or rec.status
    rec.remarks = data.get("remarks")
    rec.write_date = _parse_datetime(data.get("write_date"))


def _upsert_grade(db: Session, odoo_id: int, env: WebhookEnvelope, data: Dict[str, Any]) -> None:
    rec = db.query(models.EmsExamResult).filter_by(odoo_id=odoo_id).one_or_none()
    if not rec:
        rec = models.EmsExamResult(
            odoo_id=odoo_id,
            student_odoo_id=data.get("student_id") or 0,
            exam_id=data.get("exam_id") or 0,
            exam_name=data.get("exam_name") or "",
        )
        db.add(rec)
    rec.exam_name = data.get("exam_name") or rec.exam_name
    rec.subject = data.get("subject_id") and str(data.get("subject_id")) or rec.subject
    rec.date = _parse_date(data.get("date")) or rec.date
    rec.marks_obtained = float(data.get("marks_obtained") or 0.0)
    rec.total_marks = float(data.get("total_marks") or 0.0)
    rec.percentage = float(data.get("percentage") or 0.0)
    rec.grade = data.get("grade")


HANDLERS = {
    "student.created": _upsert_student,
    "student.updated": _upsert_student,
    "fee.invoice.posted": _upsert_invoice,
    "fee.invoice.paid": _upsert_invoice,
    "fee.invoice.cancelled": _upsert_invoice,
    "attendance.recorded": _upsert_attendance,
    "attendance.updated": _upsert_attendance,
    "exam.result.published": _upsert_grade,
    "report_card.published": _upsert_grade,
}


def apply_envelope(db: Session, env: WebhookEnvelope) -> str:
    """Returns a short status string ('processed', 'unknown_event')."""
    handler = HANDLERS.get(env.event)
    if not handler:
        return "unknown_event"
    for odoo_id in env.ids or []:
        handler(db, odoo_id, env, env.data or {})
    return "processed"
