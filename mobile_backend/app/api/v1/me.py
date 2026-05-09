"""/v1/me — profile + linked students summary."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ... import models, schemas
from ...db.session import get_db
from ...services.odoo_gateway import OdooGatewayClient
from ..deps import require_parent

router = APIRouter()


@router.get("", response_model=schemas.MeResponse)
def me(
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.MeResponse:
    if not (user.ems_parent_id and user.odoo_user_id):
        return schemas.MeResponse(
            parent=schemas.ParentSummary(
                id=user.id, name=user.full_name, email=user.email, phone=None
            ),
            students=[],
            app_role=user.role.value,
        )
    client = OdooGatewayClient()
    try:
        body = client.me(user.ems_parent_id, user.odoo_user_id)
    finally:
        client.close()
    parent = body.get("parent") or {}
    students = [
        schemas.StudentSummary(
            id=s["id"],
            name=s.get("name") or "",
            name_en=s.get("name_en"),
            student_number=s.get("student_number"),
            grade=(s.get("grade") or {}).get("name"),
            division=(s.get("division") or {}).get("name"),
            school_id=(s.get("school") or {}).get("id"),
            state=s.get("state"),
        )
        for s in body.get("students", [])
    ]
    return schemas.MeResponse(
        parent=schemas.ParentSummary(
            id=parent.get("id"),
            name=parent.get("name"),
            email=parent.get("email"),
            phone=parent.get("phone"),
            preferred_language=parent.get("preferred_language"),
        ),
        students=students,
        app_role=user.role.value,
    )
