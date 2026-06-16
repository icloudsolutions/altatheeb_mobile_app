"""/v1/auth — login, refresh, logout, password reset bridges."""

import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ... import models, schemas
from ...core.security import decode_token, hash_password, issue_tokens, verify_password
from ...db.session import get_db
from ...services.odoo_gateway import OdooGatewayClient, OdooUnavailable

router = APIRouter()
logger = logging.getLogger(__name__)


def _issue_for_user(user: models.AppUser, school_ids: list) -> schemas.LoginResponse:
    access, refresh = issue_tokens(
        subject=str(user.id),
        claims={
            "role": user.role.value,
            "odoo_user_id": user.odoo_user_id,
            "ems_parent_id": user.ems_parent_id,
        },
    )
    return schemas.LoginResponse(
        access=access,
        refresh=refresh,
        user_id=user.id,
        app_role=user.role.value,
        odoo_user_id=user.odoo_user_id,
        ems_parent_id=user.ems_parent_id,
        school_ids=school_ids,
        name=user.full_name,
    )


@router.post("/login", response_model=schemas.LoginResponse)
def login(body: schemas.LoginRequest, db: Session = Depends(get_db)) -> schemas.LoginResponse:
    client = OdooGatewayClient()
    odoo_available = True
    verified: dict = {}
    try:
        verified = client.auth_verify(body.username, body.password)
    except OdooUnavailable:
        odoo_available = False
        logger.info("Odoo unavailable — attempting local auth fallback for %s", body.username)
    finally:
        client.close()

    if odoo_available:
        if not verified.get("success"):
            raise HTTPException(status_code=401, detail="invalid_credentials")
        if verified.get("app_role") != "parent":
            raise HTTPException(status_code=403, detail="role_not_allowed")

        odoo_user_id = int(verified["user_id"])
        parent_id = int(verified.get("parent_id") or 0) or None

        user = (
            db.query(models.AppUser)
            .filter(models.AppUser.odoo_user_id == odoo_user_id)
            .one_or_none()
        )
        if not user:
            user = models.AppUser(
                login=body.username,
                email=verified.get("email") or None,
                full_name=verified.get("name") or None,
                role=models.AppRole.parent,
                odoo_user_id=odoo_user_id,
                ems_parent_id=parent_id,
            )
            db.add(user)
        else:
            user.email = verified.get("email") or user.email
            user.full_name = verified.get("name") or user.full_name
            user.ems_parent_id = parent_id or user.ems_parent_id

        # Keep a local password hash so offline login works next time.
        user.password_hash = hash_password(body.password)
        user.last_login_at = datetime.utcnow()
        db.commit()
        db.refresh(user)
        return _issue_for_user(user, verified.get("school_ids") or [])

    # --- Odoo offline: fall back to locally-stored credentials ---
    user = (
        db.query(models.AppUser)
        .filter(models.AppUser.login == body.username)
        .one_or_none()
    )
    if not user or not user.password_hash:
        raise HTTPException(status_code=503, detail="odoo_unavailable_no_local_credentials")
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="invalid_credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="user_disabled")
    user.last_login_at = datetime.utcnow()
    db.commit()
    logger.info("Local auth fallback succeeded for user %s", user.id)
    return _issue_for_user(user, [])


@router.post("/refresh", response_model=schemas.TokenPair)
def refresh(body: schemas.RefreshRequest, db: Session = Depends(get_db)) -> schemas.TokenPair:
    payload = decode_token(body.refresh)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="invalid_refresh")
    user = db.get(models.AppUser, int(payload.get("sub") or 0))
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="user_disabled")
    access, refresh_token = issue_tokens(
        subject=str(user.id),
        claims={
            "role": user.role.value,
            "odoo_user_id": user.odoo_user_id,
            "ems_parent_id": user.ems_parent_id,
        },
    )
    return schemas.TokenPair(access=access, refresh=refresh_token)


@router.post("/logout", response_model=schemas.OkResponse)
def logout() -> schemas.OkResponse:
    # Stateless JWT: client drops the token. (Refresh-token denylist comes
    # later if we adopt server-side revocation.)
    return schemas.OkResponse()


@router.post("/forgot-password", response_model=schemas.OkResponse)
def forgot_password() -> schemas.OkResponse:
    # Always-200 to avoid enumeration; backend will send an email link if
    # the address exists. Implementation arrives in sprint 2.
    return schemas.OkResponse()


@router.post("/reset-password", response_model=schemas.OkResponse)
def reset_password() -> schemas.OkResponse:
    return schemas.OkResponse()
