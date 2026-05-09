"""FastAPI dependencies: DB session, current user (JWT)."""

from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from .. import models
from ..core.security import decode_token
from ..db.session import get_db

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    request: Request,
    db: Session = Depends(get_db),
    creds=Depends(bearer_scheme),
) -> models.AppUser:
    if creds is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="missing_token")
    payload = decode_token(creds.credentials)
    if not payload or payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="invalid_token")
    user_id = int(payload.get("sub") or 0)
    user = db.get(models.AppUser, user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="user_disabled")
    return user


def require_parent(user: models.AppUser = Depends(get_current_user)) -> models.AppUser:
    if user.role != models.AppRole.parent:
        raise HTTPException(status_code=403, detail="role_not_allowed")
    return user
