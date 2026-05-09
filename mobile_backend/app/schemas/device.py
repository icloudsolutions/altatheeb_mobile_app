from pydantic import BaseModel


class DeviceRegisterRequest(BaseModel):
    device_id: str
    platform: str  # ios|android
    fcm_token: str | None = None
    app_version: str | None = None
    os_version: str | None = None
    locale: str | None = None


class DeviceRegisterResponse(BaseModel):
    id: int
    ok: bool = True
