"""Admin auth (separate from app auth: an AppUser with role=admin)."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ... import models
from ...core.security import issue_tokens, verify_password
from ...db.session import get_db

router = APIRouter()


class AdminLogin(BaseModel):
    login: str
    password: str


class AdminLoginResponse(BaseModel):
    access: str
    refresh: str
    user_id: int


@router.post("/login", response_model=AdminLoginResponse)
def login(body: AdminLogin, db: Session = Depends(get_db)) -> AdminLoginResponse:
    user = (
        db.query(models.AppUser)
        .filter(models.AppUser.login == body.login, models.AppUser.role == models.AppRole.admin)
        .one_or_none()
    )
    if not user or not user.password_hash or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "invalid_credentials")
    if not user.is_active:
        raise HTTPException(403, "user_disabled")
    access, refresh = issue_tokens(
        subject=str(user.id), claims={"role": "admin"}
    )
    return AdminLoginResponse(access=access, refresh=refresh, user_id=user.id)
