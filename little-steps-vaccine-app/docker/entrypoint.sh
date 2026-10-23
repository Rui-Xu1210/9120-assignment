#!/bin/sh
set -eu

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
until python - <<'PY'
import os, psycopg
with psycopg.connect(host=os.environ["DB_HOST"], port=int(os.environ["DB_PORT"]), dbname=os.environ["DB_NAME"], user=os.environ["DB_USER"], password=os.environ["DB_PASSWORD"], connect_timeout=3):
    pass
PY
do sleep 2; done

if python - <<'PY'
import os, psycopg
with psycopg.connect(host=os.environ["DB_HOST"], port=int(os.environ["DB_PORT"]), dbname=os.environ["DB_NAME"], user=os.environ["DB_USER"], password=os.environ["DB_PASSWORD"], connect_timeout=3) as conn:
    exists = conn.execute("SELECT to_regclass('public.parent') IS NOT NULL").fetchone()[0]
raise SystemExit(0 if exists else 1)
PY
then
  echo "Existing 9120assignment_demo schema found; applying only additive migrations."
  python scripts/setup_db.py --migrate-only
else
  echo "Empty 9120assignment_demo database found; applying schema and seed data."
  python scripts/setup_db.py
fi
exec uvicorn app.main:app --host 0.0.0.0 --port "${APP_PORT:-8000}"
