from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class AnnouncementItem(BaseModel):
    id: int
    title: str
    body: Optional[str] = None
    school_id: Optional[int] = None
    audience: Optional[str] = None
    published_at: Optional[datetime] = None


class AnnouncementsResponse(BaseModel):
    announcements: list[AnnouncementItem]
