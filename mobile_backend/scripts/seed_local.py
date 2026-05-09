"""Seed local-dev data: admin user, feature flag, min app version, banner."""

import os

from app.core.security import hash_password
from app.db.session import SessionLocal
from app import models


def main() -> None:
    admin_login = os.environ.get("INITIAL_ADMIN_LOGIN", "admin@local").strip()
    admin_password = os.environ.get("INITIAL_ADMIN_PASSWORD", "admin")
    admin_email = os.environ.get("INITIAL_ADMIN_EMAIL", admin_login).strip() or admin_login
    admin_name = os.environ.get("INITIAL_ADMIN_FULL_NAME", "EMS Admin").strip() or "EMS Admin"

    db = SessionLocal()
    try:
        admin = (
            db.query(models.AppUser)
            .filter(models.AppUser.login == admin_login)
            .one_or_none()
        )
        if not admin:
            admin = models.AppUser(
                login=admin_login,
                email=admin_email,
                full_name=admin_name,
                role=models.AppRole.admin,
                password_hash=hash_password(admin_password),
            )
            db.add(admin)

        for platform, ver in [("android", "1.0.0"), ("ios", "1.0.0")]:
            row = db.query(models.MinAppVersion).filter_by(platform=platform).one_or_none()
            if not row:
                db.add(models.MinAppVersion(platform=platform, min_version=ver))

        for key, value, desc in [
            ("feature.store_enabled", False, "Store catalog feature"),
            ("feature.payments_enabled", True, "Hosted-checkout enabled"),
        ]:
            flag = db.query(models.FeatureFlag).filter_by(key=key).one_or_none()
            if not flag:
                db.add(models.FeatureFlag(key=key, value_bool=value, description=desc))

        if not db.query(models.MaintenanceBanner).first():
            db.add(models.MaintenanceBanner(enabled=False))

        db.commit()
        print(f"Seed OK. Admin login: {admin_login}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
