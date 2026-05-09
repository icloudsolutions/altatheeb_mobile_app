"""Declarative base shared by all ORM models."""

from sqlalchemy.orm import DeclarativeBase, declared_attr


class Base(DeclarativeBase):
    @declared_attr.directive
    def __tablename__(cls) -> str:  # type: ignore[override]
        # ClassName -> snake_case
        out: list[str] = []
        for i, ch in enumerate(cls.__name__):
            if ch.isupper() and i:
                out.append("_")
            out.append(ch.lower())
        return "".join(out)
