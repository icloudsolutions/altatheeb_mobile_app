"""HMAC verification + idempotency tests on /integrations/odoo/v1/webhooks."""

import hashlib
import hmac
import json
import time


def _sign(body: bytes, secret: str) -> tuple[str, int]:
    ts = int(time.time())
    sig = hmac.new(
        secret.encode("utf-8"),
        f"v1.{ts}.".encode("utf-8") + body,
        hashlib.sha256,
    ).hexdigest()
    return f"t={ts},v1={sig}", ts


def _envelope(event="student.created"):
    return {
        "integration_contract_version": "1.0",
        "delivery_id": "abc-123",
        "event": event,
        "resource": "ics.student",
        "ids": [42],
        "school_id": 1,
        "data": {"name": "Test", "state": "active", "write_date": "2026-05-09T00:00:00"},
    }


def test_reject_missing_signature(client):
    body = json.dumps(_envelope()).encode("utf-8")
    r = client.post("/integrations/odoo/v1/webhooks", content=body)
    assert r.status_code == 401


def test_reject_bad_signature(client):
    body = json.dumps(_envelope()).encode("utf-8")
    r = client.post(
        "/integrations/odoo/v1/webhooks",
        content=body,
        headers={"X-EMS-Signature": "t=0,v1=deadbeef", "Content-Type": "application/json"},
    )
    assert r.status_code == 401


def test_accept_signed_and_idempotent(client):
    body = json.dumps(_envelope()).encode("utf-8")
    sig, _ = _sign(body, "test-webhook-secret")
    r1 = client.post(
        "/integrations/odoo/v1/webhooks",
        content=body,
        headers={"X-EMS-Signature": sig, "Content-Type": "application/json"},
    )
    assert r1.status_code == 200, r1.text
    assert r1.json().get("status") == "processed"

    sig2, _ = _sign(body, "test-webhook-secret")
    r2 = client.post(
        "/integrations/odoo/v1/webhooks",
        content=body,
        headers={"X-EMS-Signature": sig2, "Content-Type": "application/json"},
    )
    assert r2.status_code == 200
    assert r2.json().get("status") == "duplicate"


def test_replay_attack_rejected(client):
    body = json.dumps(_envelope()).encode("utf-8")
    # Force a stale timestamp
    secret = "test-webhook-secret"
    ts = int(time.time()) - 9999
    sig = hmac.new(
        secret.encode("utf-8"), f"v1.{ts}.".encode("utf-8") + body, hashlib.sha256
    ).hexdigest()
    r = client.post(
        "/integrations/odoo/v1/webhooks",
        content=body,
        headers={"X-EMS-Signature": f"t={ts},v1={sig}", "Content-Type": "application/json"},
    )
    assert r.status_code == 401
