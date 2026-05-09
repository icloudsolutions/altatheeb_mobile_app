"""HTTP client for the Odoo `ics_ems_mobile_gateway` addon."""

from typing import Any, Dict, Optional

import httpx

from ..core.security import build_user_context_headers
from ..core.settings import get_settings


class OdooGatewayClient:
    def __init__(self, base_url: Optional[str] = None) -> None:
        self.settings = get_settings()
        self.base_url = (base_url or self.settings.odoo_base_url).rstrip("/")
        self._client = httpx.Client(timeout=15.0)

    def close(self) -> None:
        self._client.close()

    # --- Auth ---------------------------------------------------------
    def auth_verify(self, username: str, password: str) -> Dict[str, Any]:
        url = f"{self.base_url}/ems/integration/v1/auth/verify"
        headers = {
            "Authorization": f"Bearer {self.settings.odoo_service_token}",
            "Content-Type": "application/json",
        }
        payload = {
            "jsonrpc": "2.0",
            "method": "call",
            "params": {"username": username, "password": password},
        }
        r = self._client.post(url, json=payload, headers=headers)
        r.raise_for_status()
        body = r.json()
        return (body or {}).get("result") or {}

    # --- User-scoped reads -------------------------------------------
    def me(self, parent_id: int, odoo_user_id: int) -> Dict[str, Any]:
        return self._get("/ems/integration/v1/me", parent_id, odoo_user_id)

    def children(self, parent_id: int, odoo_user_id: int) -> Dict[str, Any]:
        return self._get("/ems/integration/v1/children", parent_id, odoo_user_id)

    def child_invoices(self, parent_id: int, odoo_user_id: int, student_id: int) -> Dict[str, Any]:
        return self._get(
            f"/ems/integration/v1/children/{student_id}/invoices",
            parent_id,
            odoo_user_id,
        )

    def reconcile(self, resource: str, since: str) -> Dict[str, Any]:
        url = f"{self.base_url}/ems/integration/v1/reconcile"
        headers = {"Authorization": f"Bearer {self.settings.odoo_service_token}"}
        r = self._client.get(
            url, params={"resource": resource, "since": since}, headers=headers
        )
        r.raise_for_status()
        return r.json()

    # --- Internals ---------------------------------------------------
    def _get(self, path: str, parent_id: int, odoo_user_id: int) -> Dict[str, Any]:
        headers = build_user_context_headers(parent_id, odoo_user_id)
        url = f"{self.base_url}{path}"
        r = self._client.get(url, headers=headers)
        r.raise_for_status()
        return r.json()
