from fastapi import APIRouter

from . import auth, me, children, invoices, devices, config, sync

router = APIRouter(prefix="/v1")
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(me.router, prefix="/me", tags=["me"])
router.include_router(children.router, prefix="/children", tags=["children"])
router.include_router(invoices.router, prefix="/invoices", tags=["invoices"])
router.include_router(devices.router, prefix="/devices", tags=["devices"])
router.include_router(config.router, prefix="/config", tags=["config"])
router.include_router(sync.router, prefix="/sync", tags=["sync"])
