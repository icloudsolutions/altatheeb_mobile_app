"""Map webhook events to FCM notifications."""

from typing import Optional, Tuple

from sqlalchemy.orm import Session

from .. import models
from ..schemas import WebhookEnvelope
from .fcm import FcmService

NOTIFY_TEMPLATES: dict[str, dict[str, str]] = {
    "fee.invoice.posted": {
        "title_en": "New invoice issued",
        "title_ar": "تم إصدار فاتورة جديدة",
        "body_en": "An invoice has been issued for your child.",
        "body_ar": "تم إصدار فاتورة جديدة لابنك / ابنتك.",
    },
    "fee.invoice.paid": {
        "title_en": "Payment received",
        "title_ar": "تم استلام الدفعة",
        "body_en": "Thank you, your payment has been received.",
        "body_ar": "شكراً، تم استلام الدفعة.",
    },
    "attendance.recorded": {
        "title_en": "Attendance update",
        "title_ar": "تحديث الحضور",
        "body_en": "Today's attendance has been recorded.",
        "body_ar": "تم تسجيل حضور اليوم.",
    },
    "exam.result.published": {
        "title_en": "Exam result published",
        "title_ar": "تم نشر نتيجة الاختبار",
        "body_en": "A new exam result is available.",
        "body_ar": "تتوفر نتيجة اختبار جديدة.",
    },
}


def _parents_for_student(db: Session, student_odoo_id: int) -> list[models.AppUser]:
    """Find AppUsers whose ems_parent_id is in the student-parent mirror."""
    parent_ids = (
        db.query(models.EmsStudentParent.parent_odoo_id)
        .filter(models.EmsStudentParent.student_odoo_id == student_odoo_id)
        .all()
    )
    flat = [pid for (pid,) in parent_ids]
    if not flat:
        return []
    return (
        db.query(models.AppUser)
        .filter(models.AppUser.ems_parent_id.in_(flat))
        .all()
    )


def maybe_notify(db: Session, env: WebhookEnvelope) -> int:
    tpl = NOTIFY_TEMPLATES.get(env.event)
    if not tpl:
        return 0
    student_odoo_id = (env.data or {}).get("student_id")
    if not student_odoo_id:
        # invoices: lookup mirror to find student
        if env.resource == "account.move" and env.ids:
            mirror = db.query(models.EmsInvoice).filter_by(odoo_id=env.ids[0]).one_or_none()
            student_odoo_id = mirror.student_odoo_id if mirror else None
    if not student_odoo_id:
        return 0
    users = _parents_for_student(db, int(student_odoo_id))
    if not users:
        return 0
    fcm = FcmService()
    sent = 0
    for u in users:
        for d in u.devices:
            if not d.fcm_token:
                continue
            lang = (d.locale or "ar").split("-")[0]
            title = tpl.get(f"title_{lang}") or tpl["title_en"]
            body = tpl.get(f"body_{lang}") or tpl["body_en"]
            fcm.send_to_token(
                d.fcm_token,
                title,
                body,
                data={"event": env.event, "delivery_id": env.delivery_id},
            )
            sent += 1
    return sent
