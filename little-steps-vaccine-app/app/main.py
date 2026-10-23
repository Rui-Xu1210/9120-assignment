"""REST API for the Pediatric Vaccination Tracker."""

from datetime import date
from pathlib import Path
import logging

import psycopg
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from psycopg.errors import ForeignKeyViolation, UniqueViolation

from app.db import get_connection
from app.schemas import (
    ChildCreate,
    ParentCreate,
    RecordCreate,
    ReminderUpdate,
    ScheduleUpdate,
    VaccineCreate,
)

app = FastAPI(
    title="Pediatric Vaccination Tracker API",
    description="Database-backed API for children, vaccine schedules, records and reminders.",
    version="1.0.0",
)


# Serve the phone UI from the same origin as the existing REST API: no CORS
# wildcard and no second frontend server are needed for a Wi-Fi demo.
FRONTEND = Path(__file__).resolve().parents[1] / "frontend"
app.mount("/static", StaticFiles(directory=FRONTEND), name="static")

@app.get("/", include_in_schema=False)
def frontend():
    return FileResponse(FRONTEND / "index.html", headers={"Cache-Control": "no-store"})

@app.exception_handler(psycopg.Error)
async def database_error(request: Request, exc: psycopg.Error):
    logging.getLogger(__name__).error("Database operation failed: %s", type(exc).__name__)
    return JSONResponse(status_code=503, content={"detail": "Database unavailable. Please check the local PostgreSQL service and configuration."})

@app.exception_handler(RuntimeError)
async def configuration_error(request: Request, exc: RuntimeError):
    return JSONResponse(status_code=503, content={"detail": "Database is not configured. Complete the local .env file and run the database setup script."})


def fetch_all(sql: str, params: tuple = ()):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchall()


def fetch_one(sql: str, params: tuple = ()):
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def ensure_row(row, detail: str):
    if row is None:
        raise HTTPException(status_code=404, detail=detail)
    return row


@app.get("/health")
def health():
    """Check both API availability and database connectivity."""
    try:
        row = fetch_one("SELECT current_database() AS database, CURRENT_TIMESTAMP AS connected_at")
        return {"status": "ok", **row}
    except (psycopg.Error, RuntimeError) as exc:
        raise HTTPException(status_code=503, detail="Database unavailable. Check the local .env file and PostgreSQL service.") from exc


@app.post("/parents", status_code=201)
def create_parent(payload: ParentCreate):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO parent (name) VALUES (%s) RETURNING parent_id, name", (payload.name.strip(),))
        return cur.fetchone()


@app.get("/parents")
def list_parents():
    return fetch_all(
        "SELECT p.parent_id, p.name, COUNT(c.child_id)::int AS child_count "
        "FROM parent p LEFT JOIN child c USING (parent_id) "
        "GROUP BY p.parent_id, p.name ORDER BY p.name, p.parent_id"
    )


@app.get("/parents/{parent_id}")
def get_parent(parent_id: str):
    parent = ensure_row(fetch_one("SELECT parent_id, name FROM parent WHERE parent_id=%s", (parent_id,)), "Parent not found")
    parent["children"] = fetch_all(
        "SELECT child_id, name, date_of_birth, age FROM child_with_age WHERE parent_id=%s ORDER BY name",
        (parent_id,),
    )
    return parent


@app.post("/children", status_code=201)
def create_child(payload: ChildCreate):
    if payload.date_of_birth > date.today():
        raise HTTPException(status_code=422, detail="date_of_birth cannot be in the future")
    try:
        with get_connection() as conn, conn.cursor() as cur:
            cur.execute(
                "INSERT INTO child (name, date_of_birth, parent_id) VALUES (%s,%s,%s) "
                "RETURNING child_id, name, date_of_birth, parent_id",
                (payload.name.strip(), payload.date_of_birth, payload.parent_id),
            )
            child = cur.fetchone()
            # PostgreSQL trigger creates schedules and reminders in this same transaction.
            cur.execute("SELECT COUNT(*)::int AS schedules_created FROM vaccine_schedule_id WHERE child_id=%s", (child["child_id"],))
            child["schedules_created"] = cur.fetchone()["schedules_created"]
            return child
    except ForeignKeyViolation as exc:
        raise HTTPException(status_code=404, detail="Parent not found") from exc


@app.get("/children")
def list_children(parent_id: str | None = None):
    return fetch_all(
        "SELECT child_id, name, date_of_birth, parent_id, age FROM child_with_age "
        "WHERE (%s::char(6) IS NULL OR parent_id=%s) ORDER BY name, child_id",
        (parent_id, parent_id),
    )


@app.get("/children/{child_id}")
def get_child(child_id: str):
    child = ensure_row(
        fetch_one(
            "SELECT c.child_id,c.name,c.date_of_birth,c.parent_id,v.age,p.name AS parent_name "
            "FROM child_with_age v JOIN child c USING(child_id) JOIN parent p ON p.parent_id=c.parent_id WHERE c.child_id=%s",
            (child_id,),
        ),
        "Child not found",
    )
    child["vaccination_history"] = fetch_all(
        "SELECT r.record_id,r.vaccine_id,v.vaccine_name,r.dose_number,r.vaccination_date,r.provider "
        "FROM vaccine_record r JOIN vaccine v USING(vaccine_id) WHERE r.child_id=%s ORDER BY r.vaccination_date DESC",
        (child_id,),
    )
    child["upcoming_schedules"] = fetch_all(
        "SELECT s.schedule_id,i.vaccine_id,v.vaccine_name,i.dose_number,s.scheduled_date,s.provider,s.status "
        "FROM vaccine_schedule_id i JOIN vaccine_schedule s USING(schedule_id) "
        "JOIN vaccine v USING(vaccine_id) WHERE i.child_id=%s ORDER BY s.scheduled_date",
        (child_id,),
    )
    return child


@app.get("/vaccines")
def list_vaccines(search: str | None = None, disease: str | None = None):
    return fetch_all(
        "SELECT v.vaccine_id,v.vaccine_name,v.vaccine_type,v.manufacturer,v.description, "
        "COALESCE(array_agg(DISTINCT d.disease_name) FILTER (WHERE d.disease_name IS NOT NULL), ARRAY[]::varchar[]) AS diseases "
        "FROM vaccine v LEFT JOIN prevented_disease d USING(vaccine_id) "
        "WHERE (%s::text IS NULL OR v.vaccine_name ILIKE '%%' || %s || '%%' OR v.vaccine_type ILIKE '%%' || %s || '%%') "
        "AND (%s::text IS NULL OR EXISTS (SELECT 1 FROM prevented_disease pd WHERE pd.vaccine_id=v.vaccine_id AND pd.disease_name ILIKE '%%' || %s || '%%')) "
        "GROUP BY v.vaccine_id ORDER BY v.vaccine_name",
        (search, search, search, disease, disease),
    )


@app.post("/vaccines", status_code=201)
def create_vaccine(payload: VaccineCreate):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO vaccine (vaccine_name,vaccine_type,manufacturer,description) VALUES (%s,%s,%s,%s) "
            "RETURNING vaccine_id,vaccine_name,vaccine_type,manufacturer,description",
            (payload.vaccine_name.strip(), payload.vaccine_type, payload.manufacturer, payload.description),
        )
        return cur.fetchone()


@app.get("/schedules/recommended")
def recommended_schedule(vaccine_id: str | None = None):
    return fetch_all(
        "SELECT r.vaccine_id,v.vaccine_name,r.dose_number,r.recommended_age, "
        "(EXTRACT(YEAR FROM r.recommended_age)*12 + EXTRACT(MONTH FROM r.recommended_age))::int AS recommended_months, "
        "EXTRACT(DAY FROM r.recommended_age)::int AS recommended_days "
        "FROM recommended_schedule r JOIN vaccine v USING(vaccine_id) "
        "WHERE (%s::char(6) IS NULL OR r.vaccine_id=%s) ORDER BY v.vaccine_name,r.dose_number",
        (vaccine_id, vaccine_id),
    )


@app.get("/schedules")
def list_schedules(
    child_id: str | None = None,
    status: str | None = Query(default=None, pattern="^(pending|completed)$"),
    overdue: bool = False,
):
    return fetch_all(
        "SELECT i.schedule_id,i.child_id,c.name AS child_name,i.vaccine_id,v.vaccine_name,i.dose_number, "
        "s.scheduled_date,s.provider,s.status,(s.status='pending' AND s.scheduled_date<CURRENT_DATE) AS is_overdue "
        "FROM vaccine_schedule_id i JOIN child c USING(child_id) JOIN vaccine v USING(vaccine_id) "
        "JOIN vaccine_schedule s USING(schedule_id) "
        "WHERE (%s::char(6) IS NULL OR i.child_id=%s) AND (%s::text IS NULL OR s.status=%s) "
        "AND (NOT %s OR (s.status='pending' AND s.scheduled_date<CURRENT_DATE)) "
        "ORDER BY s.scheduled_date, c.name, v.vaccine_name, i.dose_number",
        (child_id, child_id, status, status, overdue),
    )


@app.patch("/schedules/{schedule_id}")
def update_schedule(schedule_id: str, payload: ScheduleUpdate):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute(
            "SELECT s.*,c.date_of_birth FROM vaccine_schedule s "
            "JOIN vaccine_schedule_id i USING(schedule_id) JOIN child c USING(child_id) "
            "WHERE s.schedule_id=%s FOR UPDATE OF s", (schedule_id,))
        current = ensure_row(cur.fetchone(), "Schedule not found")
        if payload.scheduled_date < current["date_of_birth"]:
            raise HTTPException(422, "Planned date cannot be before the child's birth")
        if payload.status != current["status"]:
            raise HTTPException(409, "Record a vaccination to complete a dose. A recorded dose cannot be reset here.")
        cur.execute(
            "UPDATE vaccine_schedule SET scheduled_date=%s,provider=%s WHERE schedule_id=%s "
            "RETURNING schedule_id,scheduled_date,provider,status",
            (payload.scheduled_date, payload.provider, schedule_id))
        return cur.fetchone()


@app.post("/records", status_code=201)
def create_vaccination_record(payload: RecordCreate):
    try:
        with get_connection() as conn, conn.cursor() as cur:
            # Lock the child's row so date checks and the record insert share a transaction.
            cur.execute("SELECT date_of_birth FROM child WHERE child_id=%s FOR UPDATE", (payload.child_id,))
            child = ensure_row(cur.fetchone(), "Child not found")
            if payload.vaccination_date.date() < child["date_of_birth"]:
                raise HTTPException(422, "Vaccination date cannot be before the child's birth")
            cur.execute(
                "INSERT INTO vaccine_record (child_id,vaccine_id,dose_number,vaccination_date,provider) "
                "VALUES (%s,%s,%s,%s,%s) RETURNING record_id,child_id,vaccine_id,dose_number,vaccination_date,provider",
                (payload.child_id, payload.vaccine_id, payload.dose_number, payload.vaccination_date, payload.provider),
            )
            record = cur.fetchone()
            # Database trigger completes the matching schedule and all its reminders.
            cur.execute(
                "SELECT s.schedule_id,s.status FROM vaccine_schedule_id i "
                "JOIN vaccine_schedule s USING(schedule_id) "
                "WHERE i.child_id=%s AND i.vaccine_id=%s AND i.dose_number=%s",
                (payload.child_id, payload.vaccine_id, payload.dose_number),
            )
            record["schedule"] = cur.fetchone()
            return record
    except UniqueViolation as exc:
        raise HTTPException(status_code=409, detail="This child already has a record for that vaccine dose") from exc
    except ForeignKeyViolation as exc:
        raise HTTPException(status_code=422, detail="Child, vaccine, or recommended dose does not exist") from exc


@app.get("/records")
def list_records(child_id: str | None = None, vaccine_id: str | None = None):
    return fetch_all(
        "SELECT r.record_id,r.child_id,c.name AS child_name,r.vaccine_id,v.vaccine_name,r.dose_number,r.vaccination_date,r.provider "
        "FROM vaccine_record r JOIN child c USING(child_id) JOIN vaccine v USING(vaccine_id) "
        "WHERE (%s::char(6) IS NULL OR r.child_id=%s) AND (%s::char(6) IS NULL OR r.vaccine_id=%s) "
        "ORDER BY r.vaccination_date DESC",
        (child_id, child_id, vaccine_id, vaccine_id),
    )


@app.get("/reminders")
def list_reminders(child_id: str | None = None, status: str | None = Query(default=None, pattern="^(pending|completed)$")):
    return fetch_all(
        "SELECT r.reminder_id,r.schedule_id,i.child_id,c.name AS child_name,v.vaccine_name,i.dose_number, "
        "r.reminder_date,r.reminder_status FROM vaccine_reminder r "
        "JOIN vaccine_schedule_id i USING(schedule_id) JOIN child c USING(child_id) JOIN vaccine v USING(vaccine_id) "
        "WHERE (%s::char(6) IS NULL OR i.child_id=%s) AND (%s::text IS NULL OR r.reminder_status=%s) "
        "ORDER BY r.reminder_date",
        (child_id, child_id, status, status),
    )


@app.patch("/reminders/{reminder_id}")
def update_reminder(reminder_id: str, payload: ReminderUpdate):
    with get_connection() as conn, conn.cursor() as cur:
        # Lock schedule before reminder to match the record completion trigger's lock order.
        cur.execute(
            "SELECT s.status FROM vaccine_reminder r JOIN vaccine_schedule s USING(schedule_id) "
            "WHERE r.reminder_id=%s FOR UPDATE OF s", (reminder_id,))
        schedule = ensure_row(cur.fetchone(), "Reminder not found")
        if schedule["status"] == "completed" and payload.reminder_status == "pending":
            raise HTTPException(409, "A recorded dose must keep its reminder completed")
        cur.execute(
            "UPDATE vaccine_reminder SET reminder_status=COALESCE(%s,reminder_status), "
            "reminder_date=COALESCE(%s,reminder_date) WHERE reminder_id=%s "
            "RETURNING reminder_id,schedule_id,reminder_date,reminder_status",
            (payload.reminder_status, payload.reminder_date, reminder_id))
        return cur.fetchone()


@app.get("/dashboard")
def dashboard():
    return fetch_one(
        "SELECT (SELECT COUNT(*)::int FROM parent) AS parents, "
        "(SELECT COUNT(*)::int FROM child) AS children, "
        "(SELECT COUNT(*)::int FROM vaccine) AS vaccines, "
        "(SELECT COUNT(*)::int FROM vaccine_record) AS vaccinations_recorded, "
        "(SELECT COUNT(*)::int FROM vaccine_schedule s WHERE s.status='pending') AS pending_schedules, "
        "(SELECT COUNT(*)::int FROM vaccine_schedule s WHERE s.status='pending' AND s.scheduled_date<CURRENT_DATE) AS overdue_schedules, "
        "(SELECT COUNT(*)::int FROM vaccine_reminder WHERE reminder_status='pending') AS pending_reminders"
    )


# Each endpoint uses one transaction. Returning from this block commits before
# the HTTP response is sent; any exception causes get_connection to roll back.
@app.delete("/children/{child_id}")
def remove_child(child_id: str):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("SELECT delete_child(%s) AS deleted", (child_id,))
        if not cur.fetchone()["deleted"]:
            raise HTTPException(404, "Child not found")
    return {"deleted": True, "child_id": child_id}


@app.delete("/records/{record_id}")
def remove_record(record_id: str):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("SELECT delete_vaccination_record(%s) AS deleted", (record_id,))
        if not cur.fetchone()["deleted"]:
            raise HTTPException(404, "Vaccination record not found")
    return {"deleted": True, "record_id": record_id}


@app.delete("/parents/{parent_id}")
def remove_parent(parent_id: str):
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("SELECT delete_parent(%s) AS deleted", (parent_id,))
        if not cur.fetchone()["deleted"]:
            raise HTTPException(404, "Parent not found")
    return {"deleted": True, "parent_id": parent_id}
