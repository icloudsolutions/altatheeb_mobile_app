"""/v1/children — list and per-child resources."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from ... import models, schemas
from ...db.session import get_db
from ...services.odoo_gateway import OdooGatewayClient, OdooUnavailable
from ..deps import require_parent

router = APIRouter()
logger = logging.getLogger(__name__)


def _students_from_mirror(db: Session, parent_odoo_id: int) -> list[schemas.StudentSummary]:
    links = (
        db.query(models.EmsStudentParent)
        .filter(models.EmsStudentParent.parent_odoo_id == parent_odoo_id)
        .all()
    )
    student_ids = [lnk.student_odoo_id for lnk in links]
    if not student_ids:
        return []
    rows = (
        db.query(models.EmsStudent)
        .filter(models.EmsStudent.odoo_id.in_(student_ids))
        .all()
    )
    return [
        schemas.StudentSummary(
            id=r.odoo_id,
            name=r.name,
            name_en=r.name_en,
            student_number=r.student_number,
            grade=r.grade_name,
            division=r.division_name,
            school_id=r.school_id,
            state=r.state,
        )
        for r in rows
    ]


@router.get("")
def list_children(
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
):
    if user.ems_parent_id and user.odoo_user_id:
        client = OdooGatewayClient()
        try:
            result = client.children(user.ems_parent_id, user.odoo_user_id)
            return result
        except OdooUnavailable:
            logger.info("Odoo unavailable — serving children from mirror DB for parent %s", user.ems_parent_id)
        finally:
            client.close()

    # Mirror DB fallback
    if user.ems_parent_id:
        students = _students_from_mirror(db, user.ems_parent_id)
        return {"students": [s.model_dump() for s in students]}
    return {"students": []}


@router.get("/{student_id}/invoices", response_model=schemas.InvoicesResponse)
def child_invoices(
    student_id: int,
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.InvoicesResponse:
    # Mirror-first read; proxy to Odoo gateway only on cold start.
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
    except OdooUnavailable:
        return schemas.InvoicesResponse(invoices=[])
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


@router.get("/{student_id}/attendance", response_model=schemas.AttendanceResponse)
def child_attendance(
    student_id: int,
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.AttendanceResponse:
    # Try Odoo gateway first if available
    if user.ems_parent_id and user.odoo_user_id:
        client = OdooGatewayClient()
        try:
            body = client.child_attendance(
                user.ems_parent_id, user.odoo_user_id, student_id,
                from_date=from_date, to_date=to_date
            )
            items = [
                schemas.AttendanceItem(
                    id=a["id"],
                    student_odoo_id=a.get("student_id", student_id),
                    date=a.get("date"),
                    status=a.get("status", "present"),
                    remarks=a.get("remarks"),
                )
                for a in body.get("attendance", [])
            ]
            stats = _attendance_stats(items)
            return schemas.AttendanceResponse(attendance=items, **stats)
        except OdooUnavailable:
            logger.info("Odoo unavailable — serving attendance from mirror for student %s", student_id)
        finally:
            client.close()

    # Mirror DB fallback
    q = db.query(models.EmsAttendance).filter(
        models.EmsAttendance.student_odoo_id == student_id
    )
    if from_date:
        q = q.filter(models.EmsAttendance.date >= from_date)
    if to_date:
        q = q.filter(models.EmsAttendance.date <= to_date)
    rows = q.order_by(models.EmsAttendance.date.desc()).all()
    items = [
        schemas.AttendanceItem(
            id=r.odoo_id,
            student_odoo_id=r.student_odoo_id,
            date=r.date,
            status=r.status,
            remarks=r.remarks,
        )
        for r in rows
    ]
    stats = _attendance_stats(items)
    return schemas.AttendanceResponse(attendance=items, **stats)


@router.get("/{student_id}/results", response_model=schemas.ResultsResponse)
def child_results(
    student_id: int,
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.ResultsResponse:
    if user.ems_parent_id and user.odoo_user_id:
        client = OdooGatewayClient()
        try:
            body = client.child_results(user.ems_parent_id, user.odoo_user_id, student_id)
            items = [
                schemas.ExamResultItem(
                    id=r["id"],
                    student_odoo_id=r.get("student_id", student_id),
                    exam_id=r.get("exam_id", 0),
                    exam_name=r.get("exam_name", ""),
                    subject=r.get("subject"),
                    date=r.get("date"),
                    marks_obtained=float(r.get("marks_obtained") or 0),
                    total_marks=float(r.get("total_marks") or 0),
                    percentage=float(r.get("percentage") or 0),
                    grade=r.get("grade"),
                )
                for r in body.get("results", [])
            ]
            return schemas.ResultsResponse(results=items)
        except OdooUnavailable:
            logger.info("Odoo unavailable — serving results from mirror for student %s", student_id)
        finally:
            client.close()

    rows = (
        db.query(models.EmsExamResult)
        .filter(models.EmsExamResult.student_odoo_id == student_id)
        .order_by(models.EmsExamResult.date.desc().nullslast())
        .all()
    )
    items = [
        schemas.ExamResultItem(
            id=r.odoo_id,
            student_odoo_id=r.student_odoo_id,
            exam_id=r.exam_id,
            exam_name=r.exam_name,
            subject=r.subject,
            date=r.date,
            marks_obtained=r.marks_obtained,
            total_marks=r.total_marks,
            percentage=r.percentage,
            grade=r.grade,
        )
        for r in rows
    ]
    return schemas.ResultsResponse(results=items)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _attendance_stats(items: list[schemas.AttendanceItem]) -> dict:
    total = len(items)
    present = sum(1 for i in items if i.status == "present")
    absent = sum(1 for i in items if i.status == "absent")
    late = sum(1 for i in items if i.status == "late")
    excused = sum(1 for i in items if i.status == "excused")
    return {"total": total, "present": present, "absent": absent, "late": late, "excused": excused}
