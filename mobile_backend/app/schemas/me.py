from pydantic import BaseModel


class StudentSummary(BaseModel):
    id: int
    name: str
    name_en: str | None = None
    student_number: str | None = None
    grade: str | None = None
    division: str | None = None
    school_id: int | None = None
    state: str | None = None


class ParentSummary(BaseModel):
    id: int | None
    name: str | None
    email: str | None
    phone: str | None
    preferred_language: str | None = None


class MeResponse(BaseModel):
    parent: ParentSummary
    students: list[StudentSummary]
    app_role: str
