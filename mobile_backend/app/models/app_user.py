"""Platform users (parents, later other roles) and their devices."""

import enum
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..db.base import Base


class AppRole(str, enum.Enum):
    parent = "parent"
    student = "student"
    teacher = "teacher"
    office = "office"
    admin = "admin"


class AppUser(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    login: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    full_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    role: Mapped[AppRole] = mapped_column(
        Enum(AppRole, name="app_role"), default=AppRole.parent, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Federation to Odoo
    odoo_user_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    odoo_partner_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)
    ems_parent_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, index=True)

    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    devices: Mapped[list["AppDevice"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class AppDevice(Base):
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("app_user.id", ondelete="CASCADE"), index=True)
    platform: Mapped[str] = mapped_column(String(16), nullable=False)  # ios|android
    device_id: Mapped[str] = mapped_column(String(255), nullable=False)
    fcm_token: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    app_version: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    os_version: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    locale: Mapped[Optional[str]] = mapped_column(String(16), nullable=True)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped[AppUser] = relationship(back_populates="devices")

    __table_args__ = (UniqueConstraint("user_id", "device_id", name="uq_app_device_user_device"),)
