"""Pytest fixtures: in-memory SQLite DB + FastAPI TestClient."""

import os

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret")
os.environ.setdefault("ODOO_INBOUND_HMAC_SECRET", "test-webhook-secret")
os.environ.setdefault("USER_CONTEXT_SECRET", "test-user-ctx")
os.environ.setdefault("ODOO_SERVICE_TOKEN", "test-service-token")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.db import session as db_session
from app.main import create_app


@pytest.fixture(scope="session")
def engine():
    eng = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        future=True,
    )
    Base.metadata.create_all(eng)
    return eng


@pytest.fixture
def db(engine):
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False, expire_on_commit=False)
    db_session.SessionLocal = TestingSession  # patch
    s = TestingSession()
    try:
        yield s
    finally:
        s.close()


@pytest.fixture
def client(db):
    app = create_app()
    with TestClient(app) as c:
        yield c
