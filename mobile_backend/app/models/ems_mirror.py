"""Read-optimised mirrors of Odoo EMS data, fed by signed webhooks."""

from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    JSON,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from ..db.base import Base


class EmsStudent(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    odoo_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255))
    name_en: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    student_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)
    grade_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    grade_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    division_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    division_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    school_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    state: Mapped[Optional[str]] = mapped_column(String(32), nullable=True, index=True)
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True, index=True)
    raw: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)


class EmsStudentParent(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_odoo_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    parent_odoo_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    relation: Mapped[str] = mapped_column(String(32), default="guardian")
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    __table_args__ = (
        UniqueConstraint(
            "student_odoo_id", "parent_odoo_id", "relation",
            name="uq_ems_student_parent",
        ),
    )


class EmsInvoice(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    odoo_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(64), index=True)
    state: Mapped[str] = mapped_column(String(32), default="draft", index=True)
    payment_state: Mapped[Optional[str]] = mapped_column(String(32), nullable=True, index=True)
    amount_total: Mapped[float] = mapped_column(Float, default=0.0)
    amount_residual: Mapped[float] = mapped_column(Float, default=0.0)
    currency: Mapped[Optional[str]] = mapped_column(String(8), nullable=True)
    invoice_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    invoice_date_due: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    student_odoo_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    school_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    raw: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)


class EmsAttendance(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    odoo_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    student_odoo_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(16), index=True)
    remarks: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    __table_args__ = (Index("ix_attendance_student_date", "student_odoo_id", "date"),)


class EmsExamResult(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    odoo_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    student_odoo_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    exam_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    exam_name: Mapped[str] = mapped_column(String(255))
    subject: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    marks_obtained: Mapped[float] = mapped_column(Float, default=0.0)
    total_marks: Mapped[float] = mapped_column(Float, default=0.0)
    percentage: Mapped[float] = mapped_column(Float, default=0.0)
    grade: Mapped[Optional[str]] = mapped_column(String(8), nullable=True)
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class EmsAnnouncement(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    odoo_id: Mapped[int] = mapped_column(Integer, unique=True, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(255))
    body: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    school_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    audience: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True, index=True)
    write_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
