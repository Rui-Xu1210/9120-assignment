"""PostgreSQL connection helpers. Credentials are never bundled in the frontend."""
import os
from pathlib import Path
from contextlib import contextmanager
import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

load_dotenv(Path(__file__).resolve().parents[1] / ".env", override=False)

def connection_kwargs() -> dict:
    required = ("DB_NAME", "DB_USER", "DB_PASSWORD")
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing database configuration: {', '.join(missing)}")
    if os.environ['DB_NAME'] != '9120assignment_demo':
        raise RuntimeError('DB_NAME must be 9120assignment_demo. Other databases must not be modified.')
    return {
        "host": os.getenv("DB_HOST", "127.0.0.1"),
        "port": int(os.getenv("DB_PORT", "5432")),
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "row_factory": dict_row,
        "connect_timeout": 5,
        "options": "-c timezone=Australia/Sydney",
    }

@contextmanager
def get_connection():
    # Psycopg starts a PostgreSQL transaction on the first statement.
    conn = psycopg.connect(**connection_kwargs())
    try:
        yield conn
        conn.commit()       # COMMIT: save all statements and trigger changes.
    except BaseException:
        conn.rollback()     # ROLLBACK: undo all changes if any step fails.
        raise
    finally:
        conn.close()
