from fastapi import APIRouter

from . import odoo_webhooks

router = APIRouter(prefix="/integrations/odoo/v1")
router.include_router(odoo_webhooks.router, tags=["webhooks"])
