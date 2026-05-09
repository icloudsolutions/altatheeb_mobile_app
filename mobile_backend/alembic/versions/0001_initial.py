"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-05-09 00:00:00
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ENUM


revision: str = "0001_initial"
down_revision: Union[str, None] = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    app_role = ENUM(
        "parent",
        "student",
        "teacher",
        "office",
        "admin",
        name="app_role",
        create_type=False,
    )
    app_role.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "app_user",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("login", sa.String(255), unique=True, index=True, nullable=False),
        sa.Column("email", sa.String(255), nullable=True, index=True),
        sa.Column("full_name", sa.String(255), nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("role", app_role, nullable=False, server_default="parent"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("odoo_user_id", sa.Integer, nullable=True, index=True),
        sa.Column("odoo_partner_id", sa.Integer, nullable=True, index=True),
        sa.Column("ems_parent_id", sa.Integer, nullable=True, index=True),
        sa.Column("last_login_at", sa.DateTime, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "app_device",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("app_user.id", ondelete="CASCADE"),
                  index=True, nullable=False),
        sa.Column("platform", sa.String(16), nullable=False),
        sa.Column("device_id", sa.String(255), nullable=False),
        sa.Column("fcm_token", sa.String(255), nullable=True),
        sa.Column("app_version", sa.String(64), nullable=True),
        sa.Column("os_version", sa.String(64), nullable=True),
        sa.Column("locale", sa.String(16), nullable=True),
        sa.Column("last_seen_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "device_id", name="uq_app_device_user_device"),
    )

    op.create_table(
        "ems_student",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("odoo_id", sa.Integer, unique=True, index=True, nullable=False),
        sa.Column("name", sa.String(255)),
        sa.Column("name_en", sa.String(255), nullable=True),
        sa.Column("student_number", sa.String(64), nullable=True, index=True),
        sa.Column("grade_id", sa.Integer, nullable=True, index=True),
        sa.Column("grade_name", sa.String(128), nullable=True),
        sa.Column("division_id", sa.Integer, nullable=True, index=True),
        sa.Column("division_name", sa.String(128), nullable=True),
        sa.Column("school_id", sa.Integer, nullable=True, index=True),
        sa.Column("state", sa.String(32), nullable=True, index=True),
        sa.Column("write_date", sa.DateTime, nullable=True, index=True),
        sa.Column("raw", sa.JSON, nullable=True),
    )

    op.create_table(
        "ems_student_parent",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("student_odoo_id", sa.Integer, index=True, nullable=False),
        sa.Column("parent_odoo_id", sa.Integer, index=True, nullable=False),
        sa.Column("relation", sa.String(32), nullable=False, server_default="guardian"),
        sa.Column("write_date", sa.DateTime, nullable=True),
        sa.UniqueConstraint("student_odoo_id", "parent_odoo_id", "relation",
                             name="uq_ems_student_parent"),
    )

    op.create_table(
        "ems_invoice",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("odoo_id", sa.Integer, unique=True, index=True, nullable=False),
        sa.Column("name", sa.String(64), index=True, nullable=False),
        sa.Column("state", sa.String(32), index=True, server_default="draft"),
        sa.Column("payment_state", sa.String(32), nullable=True, index=True),
        sa.Column("amount_total", sa.Float, server_default="0"),
        sa.Column("amount_residual", sa.Float, server_default="0"),
        sa.Column("currency", sa.String(8), nullable=True),
        sa.Column("invoice_date", sa.Date, nullable=True),
        sa.Column("invoice_date_due", sa.Date, nullable=True),
        sa.Column("student_odoo_id", sa.Integer, nullable=True, index=True),
        sa.Column("school_id", sa.Integer, nullable=True, index=True),
        sa.Column("write_date", sa.DateTime, nullable=True),
        sa.Column("raw", sa.JSON, nullable=True),
    )

    op.create_table(
        "ems_attendance",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("odoo_id", sa.Integer, unique=True, index=True, nullable=False),
        sa.Column("student_odoo_id", sa.Integer, index=True, nullable=False),
        sa.Column("date", sa.Date, index=True, nullable=False),
        sa.Column("status", sa.String(16), index=True, nullable=False),
        sa.Column("remarks", sa.String(512), nullable=True),
        sa.Column("write_date", sa.DateTime, nullable=True),
    )
    op.create_index("ix_attendance_student_date", "ems_attendance", ["student_odoo_id", "date"])

    op.create_table(
        "ems_exam_result",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("odoo_id", sa.Integer, unique=True, index=True, nullable=False),
        sa.Column("student_odoo_id", sa.Integer, index=True, nullable=False),
        sa.Column("exam_id", sa.Integer, index=True, nullable=False),
        sa.Column("exam_name", sa.String(255), nullable=False),
        sa.Column("subject", sa.String(255), nullable=True),
        sa.Column("date", sa.Date, nullable=True),
        sa.Column("marks_obtained", sa.Float, server_default="0"),
        sa.Column("total_marks", sa.Float, server_default="0"),
        sa.Column("percentage", sa.Float, server_default="0"),
        sa.Column("grade", sa.String(8), nullable=True),
        sa.Column("write_date", sa.DateTime, nullable=True),
    )

    op.create_table(
        "ems_announcement",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("odoo_id", sa.Integer, unique=True, index=True, nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("body", sa.Text, nullable=True),
        sa.Column("school_id", sa.Integer, nullable=True, index=True),
        sa.Column("audience", sa.String(64), nullable=True),
        sa.Column("published_at", sa.DateTime, nullable=True, index=True),
        sa.Column("write_date", sa.DateTime, nullable=True),
    )

    op.create_table(
        "audit_log",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("actor_user_id", sa.Integer, nullable=True, index=True),
        sa.Column("actor_role", sa.String(32), nullable=True),
        sa.Column("action", sa.String(128), index=True, nullable=False),
        sa.Column("target", sa.String(255), nullable=True),
        sa.Column("ip_address", sa.String(64), nullable=True),
        sa.Column("user_agent", sa.String(512), nullable=True),
        sa.Column("detail", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now(), index=True),
    )

    op.create_table(
        "feature_flag",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("key", sa.String(128), unique=True, index=True, nullable=False),
        sa.Column("value_bool", sa.Boolean, server_default=sa.false()),
        sa.Column("value_json", sa.JSON, nullable=True),
        sa.Column("description", sa.String(512), nullable=True),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "min_app_version",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("platform", sa.String(16), unique=True, nullable=False),
        sa.Column("min_version", sa.String(32), nullable=False),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "maintenance_banner",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("enabled", sa.Boolean, server_default=sa.false()),
        sa.Column("title_ar", sa.String(255), nullable=True),
        sa.Column("title_en", sa.String(255), nullable=True),
        sa.Column("body_ar", sa.Text, nullable=True),
        sa.Column("body_en", sa.Text, nullable=True),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "webhook_delivery_log",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("delivery_id", sa.String(64), unique=True, index=True, nullable=False),
        sa.Column("event", sa.String(128), index=True, nullable=False),
        sa.Column("resource", sa.String(128), nullable=True),
        sa.Column("contract_version", sa.String(16), nullable=True),
        sa.Column("status", sa.String(32), server_default="received"),
        sa.Column("error", sa.String(2048), nullable=True),
        sa.Column("payload", sa.JSON, nullable=True),
        sa.Column("received_at", sa.DateTime, nullable=False, server_default=sa.func.now(), index=True),
        sa.Column("processed_at", sa.DateTime, nullable=True),
    )

    op.create_table(
        "idempotency_key",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, index=True, nullable=False),
        sa.Column("key", sa.String(128), index=True, nullable=False),
        sa.Column("response_json", sa.JSON, nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("user_id", "key", name="uq_idem_user_key"),
    )

    op.create_table(
        "outbox_operation",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, index=True, nullable=False),
        sa.Column("client_operation_id", sa.String(128), unique=True, index=True, nullable=False),
        sa.Column("operation", sa.String(64), nullable=False),
        sa.Column("status", sa.String(32), index=True, server_default="queued"),
        sa.Column("attempt", sa.Integer, server_default="0"),
        sa.Column("payload", sa.JSON, nullable=True),
        sa.Column("response", sa.JSON, nullable=True),
        sa.Column("error", sa.String(2048), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime, nullable=False, server_default=sa.func.now()),
    )


def downgrade() -> None:
    for tbl in [
        "outbox_operation",
        "idempotency_key",
        "webhook_delivery_log",
        "maintenance_banner",
        "min_app_version",
        "feature_flag",
        "audit_log",
        "ems_announcement",
        "ems_exam_result",
        "ems_attendance",
        "ems_invoice",
        "ems_student_parent",
        "ems_student",
        "app_device",
        "app_user",
    ]:
        op.drop_table(tbl)
    op.execute("DROP TYPE IF EXISTS app_role")
