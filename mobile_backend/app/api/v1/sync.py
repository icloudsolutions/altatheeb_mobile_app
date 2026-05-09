"""/v1/sync — incremental cursor-based sync (placeholder)."""

from datetime import datetime

from fastapi import APIRouter, Depends

from ... import models
from ..deps import get_current_user

router = APIRouter()


@router.post("")
def sync(payload: dict, user: models.AppUser = Depends(get_current_user)) -> dict:
    # Stub. Sprint 2 wires real cursor/delta logic across the mirror tables.
    return {
        "cursors": payload.get("cursors") or {},
        "deltas": {},
        "server_time": datetime.utcnow().isoformat() + "Z",
    }
