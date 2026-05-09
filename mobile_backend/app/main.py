"""FastAPI app entry point."""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import admin as admin_pkg
from .api import integrations as integrations_pkg
from .api.v1 import router as v1_router
from .core.settings import get_settings

logging.basicConfig(level=logging.INFO)


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="Altatheeb Mobile Backend",
        version="0.1.0",
        description=(
            "Public API for the Flutter app + admin BFF + Odoo gateway "
            "webhook receiver."
        ),
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(v1_router)
    app.include_router(admin_pkg.router)
    app.include_router(integrations_pkg.router)

    @app.get("/healthz")
    def healthz() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
