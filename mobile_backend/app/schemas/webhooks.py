from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class WebhookEnvelope(BaseModel):
    integration_contract_version: str = Field(..., examples=["1.0"])
    delivery_id: str
    event: str
    resource: str
    ids: list[int]
    school_id: int | None = None
    occurred_at: str | None = None
    write_date: str | None = None
    data: dict[str, Any] = {}
