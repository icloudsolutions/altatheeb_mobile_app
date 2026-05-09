"""Security primitives: JWT issue/verify, HMAC helpers, password hashing."""

import hashlib
import hmac
import secrets
import time
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple

from jose import JWTError, jwt
from passlib.context import CryptContext

from .settings import get_settings

_pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ---------------- Passwords ----------------
def hash_password(plain: str) -> str:
    return _pwd_ctx.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return _pwd_ctx.verify(plain, hashed)
    except Exception:
        return False


# ---------------- JWT ----------------
def issue_tokens(subject: str, claims: Dict[str, Any]) -> Tuple[str, str]:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    access_payload = {
        "sub": subject,
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=settings.jwt_access_ttl)).timestamp()),
        **claims,
    }
    refresh_payload = {
        "sub": subject,
        "type": "refresh",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=settings.jwt_refresh_ttl)).timestamp()),
        "jti": secrets.token_hex(16),
    }
    access = jwt.encode(access_payload, settings.jwt_secret, algorithm=settings.jwt_alg)
    refresh = jwt.encode(refresh_payload, settings.jwt_secret, algorithm=settings.jwt_alg)
    return access, refresh


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_alg])
    except JWTError:
        return None


# ---------------- HMAC: webhooks IN from Odoo ----------------
WEBHOOK_REPLAY_WINDOW_SECONDS = 300


def parse_signature_header(header: str) -> Optional[Tuple[int, str]]:
    """Parses 'X-EMS-Signature: t=<unix_ts>,v1=<hex>'."""
    if not header:
        return None
    parts = {}
    for piece in header.split(","):
        if "=" in piece:
            k, v = piece.split("=", 1)
            parts[k.strip()] = v.strip()
    try:
        return int(parts["t"]), parts["v1"]
    except (KeyError, ValueError):
        return None


def verify_webhook_signature(
    raw_body: bytes,
    signature_header: str,
    secret: str,
) -> bool:
    parsed = parse_signature_header(signature_header)
    if not parsed:
        return False
    ts, sig_hex = parsed
    if abs(int(time.time()) - ts) > WEBHOOK_REPLAY_WINDOW_SECONDS:
        return False
    expected = hmac.new(
        secret.encode("utf-8"),
        f"v1.{ts}.".encode("utf-8") + raw_body,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, sig_hex)


# ---------------- HMAC: user context OUT to Odoo ----------------
def build_user_context_headers(parent_id: int, odoo_user_id: int) -> Dict[str, str]:
    settings = get_settings()
    ts = str(int(time.time()))
    raw = f"{parent_id}|{odoo_user_id}|{ts}"
    sig = hmac.new(settings.user_context_secret.encode("utf-8"),
                   raw.encode("utf-8"), hashlib.sha256).hexdigest()
    return {
        "X-EMS-User-Context": raw,
        "X-EMS-User-Signature": sig,
        "Authorization": f"Bearer {settings.odoo_service_token}",
    }


def constant_time_eq(a: str, b: str) -> bool:
    return hmac.compare_digest(a, b)
