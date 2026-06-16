"""/v1/announcements — school announcements from the mirror DB."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from ... import models, schemas
from ...db.session import get_db
from ..deps import require_parent

router = APIRouter()


@router.get("", response_model=schemas.AnnouncementsResponse)
def list_announcements(
    school_id: Optional[int] = Query(None),
    limit: int = Query(30, ge=1, le=100),
    user: models.AppUser = Depends(require_parent),
    db: Session = Depends(get_db),
) -> schemas.AnnouncementsResponse:
    q = db.query(models.EmsAnnouncement)
    if school_id:
        q = q.filter(models.EmsAnnouncement.school_id == school_id)
    rows = q.order_by(models.EmsAnnouncement.published_at.desc().nullslast()).limit(limit).all()
    items = [
        schemas.AnnouncementItem(
            id=r.odoo_id,
            title=r.title,
            body=r.body,
            school_id=r.school_id,
            audience=r.audience,
            published_at=r.published_at,
        )
        for r in rows
    ]
    return schemas.AnnouncementsResponse(announcements=items)
