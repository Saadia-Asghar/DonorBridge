"""Shared PostgreSQL helpers for backend services (reuse DATABASE_URL Streamlit/.env convention)."""

from __future__ import annotations

import os
from contextlib import contextmanager

import psycopg2
from psycopg2.extras import RealDictCursor

try:
    from dotenv import load_dotenv

    load_dotenv()
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", "prototype", ".env"))
except ImportError:
    pass


def database_url() -> str:
    url = os.environ.get("DATABASE_URL") or os.environ.get("DONORBRIDGE_DATABASE_URL")
    if not url:
        raise RuntimeError(
            "Set DATABASE_URL — same URI as prototype Streamlit (see prototype/.env.example)."
        )
    return url


@contextmanager
def get_cursor(dict_rows=True):
    conn = psycopg2.connect(database_url())
    try:
        kw = dict(cursor_factory=RealDictCursor) if dict_rows else {}
        cur = conn.cursor(**kw)
        try:
            yield cur
            conn.commit()
        finally:
            cur.close()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def fetch_all(sql: str, params: tuple | dict | None = None) -> list[dict]:
    params = params or ()
    with get_cursor(True) as cur:
        cur.execute(sql, params)
        return [dict(r) for r in cur.fetchall()]
