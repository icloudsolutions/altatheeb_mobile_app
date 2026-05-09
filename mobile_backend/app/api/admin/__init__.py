from fastapi import APIRouter

from . import users, feature_flags, min_app_version, webhook_deliveries, audit, login

router = APIRouter(prefix="/admin/v1")
router.include_router(login.router, prefix="/auth", tags=["admin-auth"])
router.include_router(users.router, prefix="/users", tags=["admin-users"])
router.include_router(feature_flags.router, prefix="/feature-flags", tags=["admin-flags"])
router.include_router(min_app_version.router, prefix="/min-app-version", tags=["admin-version"])
router.include_router(
    webhook_deliveries.router, prefix="/webhook-deliveries", tags=["admin-webhooks"]
)
router.include_router(audit.router, prefix="/audit", tags=["admin-audit"])
