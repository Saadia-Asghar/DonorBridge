"""PostgreSQL helpers for DonorBridge Streamlit prototype (parameterized queries only)."""

from __future__ import annotations

import os
from contextlib import contextmanager

import psycopg2
from psycopg2.extras import RealDictCursor

try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass


def database_url() -> str:
    url = os.environ.get("DATABASE_URL") or os.environ.get("DONORBRIDGE_DATABASE_URL")
    if not url:
        raise RuntimeError(
            "Set DATABASE_URL (or DONORBRIDGE_DATABASE_URL), e.g. "
            "postgresql://postgres:yourpassword@localhost:5432/donorbridge"
        )
    return url


def test_connection() -> str:
    with get_connection():
        pass
    return "OK"


@contextmanager
def get_connection():
    conn = psycopg2.connect(database_url())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def fetch_all(sql: str, params: tuple | None = None) -> list[dict]:
    params = params or ()
    with get_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(sql, params)
            return [dict(row) for row in cur.fetchall()]


def fetch_one(sql: str, params: tuple | None = None) -> dict | None:
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def execute(sql: str, params: tuple | None = None) -> int:
    params = params or ()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.rowcount
