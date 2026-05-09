from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(min_length=1)
    password: str = Field(min_length=1)
    device_id: str | None = None
    platform: str | None = None
    app_version: str | None = None


class TokenPair(BaseModel):
    access: str
    refresh: str


class LoginResponse(BaseModel):
    access: str
    refresh: str
    user_id: int
    app_role: str
    odoo_user_id: int | None = None
    ems_parent_id: int | None = None
    school_ids: list[int] = []
    name: str | None = None


class RefreshRequest(BaseModel):
    refresh: str
