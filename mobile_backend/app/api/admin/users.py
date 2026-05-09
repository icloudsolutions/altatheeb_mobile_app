from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...db.session import get_db
from .deps import require_admin

router = APIRouter()


class UserOut(BaseModel):
    id: int
    login: str
    email: str | None
    full_name: str | None
    role: str
    is_active: bool
    odoo_user_id: int | None
    ems_parent_id: int | None


class InviteRequest(BaseModel):
    email: str
    full_name: str
    role: str = "parent"


class RoleUpdate(BaseModel):
    role: str


@router.get("", response_model=list[UserOut])
def list_users(
    _: models.AppUser = Depends(require_admin), db: Session = Depends(get_db)
) -> list[UserOut]:
    return [
        UserOut(
            id=u.id,
            login=u.login,
            email=u.email,
            full_name=u.full_name,
            role=u.role.value,
            is_active=u.is_active,
            odoo_user_id=u.odoo_user_id,
            ems_parent_id=u.ems_parent_id,
        )
        for u in db.query(models.AppUser).order_by(models.AppUser.id).all()
    ]


@router.post("/invite", response_model=UserOut)
def invite(
    body: InviteRequest,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserOut:
    role = models.AppRole(body.role)
    user = models.AppUser(
        login=body.email,
        email=body.email,
        full_name=body.full_name,
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserOut(
        id=user.id,
        login=user.login,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        is_active=user.is_active,
        odoo_user_id=user.odoo_user_id,
        ems_parent_id=user.ems_parent_id,
    )


@router.post("/{user_id}/role", response_model=UserOut)
def set_role(
    user_id: int,
    body: RoleUpdate,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserOut:
    user = db.get(models.AppUser, user_id)
    if not user:
        raise HTTPException(404, "not_found")
    user.role = models.AppRole(body.role)
    db.commit()
    db.refresh(user)
    return UserOut(
        id=user.id,
        login=user.login,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        is_active=user.is_active,
        odoo_user_id=user.odoo_user_id,
        ems_parent_id=user.ems_parent_id,
    )


@router.post("/{user_id}/disable", response_model=UserOut)
def disable(
    user_id: int,
    _: models.AppUser = Depends(require_admin),
    db: Session = Depends(get_db),
) -> UserOut:
    user = db.get(models.AppUser, user_id)
    if not user:
        raise HTTPException(404, "not_found")
    user.is_active = False
    db.commit()
    db.refresh(user)
    return UserOut(
        id=user.id,
        login=user.login,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        is_active=user.is_active,
        odoo_user_id=user.odoo_user_id,
        ems_parent_id=user.ems_parent_id,
    )
