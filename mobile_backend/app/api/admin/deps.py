from fastapi import Depends, HTTPException

from ... import models
from ..deps import get_current_user


def require_admin(user: models.AppUser = Depends(get_current_user)) -> models.AppUser:
    if user.role != models.AppRole.admin:
        raise HTTPException(403, "admin_required")
    return user
