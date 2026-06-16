from datetime import date as Date
from typing import Optional

from pydantic import BaseModel


class AttendanceItem(BaseModel):
    id: int
    student_odoo_id: int
    date: Optional[Date] = None
    status: str  # present | absent | late | excused
    remarks: Optional[str] = None


class AttendanceResponse(BaseModel):
    attendance: list[AttendanceItem]
    total: int = 0
    present: int = 0
    absent: int = 0
    late: int = 0
    excused: int = 0
