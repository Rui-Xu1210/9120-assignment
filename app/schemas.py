"""HTTP request models and validation."""

from datetime import date, datetime
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

Name = Annotated[str, Field(min_length=1, max_length=100)]
VaccineName = Annotated[str, Field(min_length=1, max_length=50)]
Provider = Annotated[str | None, Field(default=None, max_length=50)]


class ParentCreate(BaseModel):
    name: Name


class ChildCreate(BaseModel):
    name: Name
    date_of_birth: date
    parent_id: Annotated[str, Field(pattern=r"^P\d{5}$")]


class VaccineCreate(BaseModel):
    vaccine_name: VaccineName
    vaccine_type: Annotated[str | None, Field(default=None, max_length=25)] = None
    manufacturer: Annotated[str | None, Field(default=None, max_length=100)] = None
    description: str | None = None


class ScheduleUpdate(BaseModel):
    scheduled_date: date
    provider: Provider = None
    status: str = Field(default="pending", pattern=r"^(pending|completed)$")


class RecordCreate(BaseModel):
    child_id: Annotated[str, Field(pattern=r"^C\d{5}$")]
    vaccine_id: Annotated[str, Field(pattern=r"^V\d{5}$")]
    dose_number: Annotated[int, Field(gt=0, le=32767)]
    vaccination_date: datetime
    provider: Provider = None


class ReminderUpdate(BaseModel):
    reminder_status: str = Field(pattern=r"^(pending|completed)$")


class VaccineOut(BaseModel):
    model_config = ConfigDict(extra="allow")

