"""PostgreSQL connection helpers."""

import os
from contextlib import contextmanager

import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

load_dotenv()


def connection_kwargs() -> dict:
    """Read connection settings from the environment (or local .env file)."""
    required = ("DB_NAME", "DB_USER", "DB_PASSWORD")
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise RuntimeError(f"Missing database configuration: {', '.join(missing)}")
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "5432")),
        "dbname": os.environ["DB_NAME"],
        "user": os.environ["DB_USER"],
        "password": os.environ["DB_PASSWORD"],
        "row_factory": dict_row,
        "connect_timeout": 5,
    }


@contextmanager
def get_connection():
    """Yield a connection; commit on success and roll back on errors."""
    with psycopg.connect(**connection_kwargs()) as conn:
        yield conn
