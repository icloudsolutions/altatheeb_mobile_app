from datetime import date as Date
from typing import Optional

from pydantic import BaseModel


class ExamResultItem(BaseModel):
    id: int
    student_odoo_id: int
    exam_id: int
    exam_name: str
    subject: Optional[str] = None
    date: Optional[Date] = None
    marks_obtained: float = 0.0
    total_marks: float = 0.0
    percentage: float = 0.0
    grade: Optional[str] = None


class ResultsResponse(BaseModel):
    results: list[ExamResultItem]
