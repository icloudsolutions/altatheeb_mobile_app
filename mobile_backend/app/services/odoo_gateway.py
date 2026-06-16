"""HTTP client for the Odoo `ics_ems_mobile_gateway` addon.

When Odoo is not configured or unreachable, methods raise ``OdooUnavailable``
so callers can fall back to the local mirror DB.
"""

import logging
from contextlib import contextmanager
from typing import Any, Dict, Generator, Optional

import httpx

from ..core.security import build_user_context_headers
from ..core.settings import get_settings

logger = logging.getLogger(__name__)


class OdooUnavailable(Exception):
    """Raised when Odoo cannot be reached or is not configured."""


class OdooGatewayClient:
    def __init__(self, base_url: Optional[str] = None) -> None:
        self.settings = get_settings()
        self.base_url = (base_url or self.settings.odoo_base_url).rstrip("/")
        self._client = httpx.Client(timeout=15.0)

    def close(self) -> None:
        self._client.close()

    def is_configured(self) -> bool:
        return self.settings.odoo_configured

    # --- Auth ---------------------------------------------------------
    def auth_verify(self, username: str, password: str) -> Dict[str, Any]:
        if not self.is_configured():
            raise OdooUnavailable("Odoo not configured")
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
        try:
            r = self._client.post(url, json=payload, headers=headers)
            r.raise_for_status()
            body = r.json()
            return (body or {}).get("result") or {}
        except (httpx.ConnectError, httpx.TimeoutException, httpx.NetworkError) as exc:
            logger.warning("Odoo auth_verify unreachable: %s", exc)
            raise OdooUnavailable(str(exc)) from exc

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

    def child_attendance(self, parent_id: int, odoo_user_id: int, student_id: int,
                         from_date: Optional[str] = None, to_date: Optional[str] = None) -> Dict[str, Any]:
        params: Dict[str, Any] = {}
        if from_date:
            params["from"] = from_date
        if to_date:
            params["to"] = to_date
        return self._get(
            f"/ems/integration/v1/children/{student_id}/attendance",
            parent_id,
            odoo_user_id,
            params=params,
        )

    def child_results(self, parent_id: int, odoo_user_id: int, student_id: int) -> Dict[str, Any]:
        return self._get(
            f"/ems/integration/v1/children/{student_id}/results",
            parent_id,
            odoo_user_id,
        )

    def reconcile(self, resource: str, since: str) -> Dict[str, Any]:
        if not self.is_configured():
            raise OdooUnavailable("Odoo not configured")
        url = f"{self.base_url}/ems/integration/v1/reconcile"
        headers = {"Authorization": f"Bearer {self.settings.odoo_service_token}"}
        try:
            r = self._client.get(
                url, params={"resource": resource, "since": since}, headers=headers
            )
            r.raise_for_status()
            return r.json()
        except (httpx.ConnectError, httpx.TimeoutException, httpx.NetworkError) as exc:
            raise OdooUnavailable(str(exc)) from exc

    # --- Internals ---------------------------------------------------
    def _get(self, path: str, parent_id: int, odoo_user_id: int,
             params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not self.is_configured():
            raise OdooUnavailable("Odoo not configured")
        headers = build_user_context_headers(parent_id, odoo_user_id)
        url = f"{self.base_url}{path}"
        try:
            r = self._client.get(url, headers=headers, params=params)
            r.raise_for_status()
            return r.json()
        except (httpx.ConnectError, httpx.TimeoutException, httpx.NetworkError) as exc:
            logger.warning("Odoo GET %s unreachable: %s", path, exc)
            raise OdooUnavailable(str(exc)) from exc


@contextmanager
def odoo_client() -> Generator[OdooGatewayClient, None, None]:
    """Context manager that always closes the client."""
    client = OdooGatewayClient()
    try:
        yield client
    finally:
        client.close()
