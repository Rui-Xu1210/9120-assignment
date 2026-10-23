"""Request validation for the original coursework API and mobile forms."""
from datetime import date
from typing import Annotated
from pydantic import BaseModel, ConfigDict, Field, NaiveDatetime, StringConstraints, field_validator, model_validator

Name = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=100)]
VaccineName = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=50)]
Provider = Annotated[str | None, Field(max_length=50)]

class ParentCreate(BaseModel):
    name: Name

class ChildCreate(BaseModel):
    name: Name
    date_of_birth: date
    parent_id: Annotated[str, Field(pattern=r"^P\d{5}$")]

class VaccineCreate(BaseModel):
    vaccine_name: VaccineName
    vaccine_type: Annotated[str | None, Field(max_length=25)] = None
    manufacturer: Annotated[str | None, Field(max_length=100)] = None
    description: str | None = None

class ScheduleUpdate(BaseModel):
    scheduled_date: date
    provider: Provider = None
    status: str = Field(default="pending", pattern=r"^(pending|completed)$")

class RecordCreate(BaseModel):
    child_id: Annotated[str, Field(pattern=r"^C\d{5}$")]
    vaccine_id: Annotated[str, Field(pattern=r"^V\d{5}$")]
    dose_number: Annotated[int, Field(gt=0, le=32767)]
    # Source schema uses TIMESTAMP WITHOUT TIME ZONE; UI sends local wall time.
    vaccination_date: NaiveDatetime
    provider: Provider = None

    @field_validator("vaccination_date")
    @classmethod
    def not_future(cls, value):
        if value.date() > date.today():
            raise ValueError("Vaccination date cannot be in the future")
        return value

class ReminderUpdate(BaseModel):
    reminder_status: str | None = Field(default=None, pattern=r"^(pending|completed)$")
    reminder_date: NaiveDatetime | None = None

    @model_validator(mode="after")
    def at_least_one_change(self):
        if self.reminder_status is None and self.reminder_date is None:
            raise ValueError("Provide a reminder date or status")
        return self

class VaccineOut(BaseModel):
    model_config = ConfigDict(extra="allow")
