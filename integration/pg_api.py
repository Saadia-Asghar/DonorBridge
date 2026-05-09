"""
DonorBridge read API for chatbot / external assistants.

Expose safe, parameterized selects only — no arbitrary SQL from users.
Uses the same DATABASE_URL as prototype/streamlit (.env loaded from cwd or prototype/.env).

Run from the DonorBridge repo root (so ``integration`` resolves as a package):

  uvicorn integration.pg_api:app --reload --host 127.0.0.1 --port 8787

Chatbot repos typically call URLs as "tools" (OpenAI function calling, LangChain, etc.).
"""

from __future__ import annotations

import re
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from integration.dbconn import fetch_all


app = FastAPI(title="DonorBridge PG API", version="0.1")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)


def _assert_int_pg(v: Optional[int]) -> Optional[int]:
    if v is None:
        return None
    i = int(v)
    return i


def _assert_slug(s: Optional[str]) -> Optional[str]:
    if s is None:
        return None
    text = str(s).strip()
    if not text:
        return None
    if not re.fullmatch(r"[A-Za-z0-9+.\-@% ]+", text.replace("‑", "-")):
        raise HTTPException(400, "Invalid characters in text parameter.")
    return text


@app.get("/health")
def health():
    fetch_all("SELECT 1")
    return {"status": "ok"}


@app.get("/v1/counts-summary")
def counts_summary():
    """Lightweight KPIs for natural-language greetings / dashboards."""
    h = fetch_all("SELECT COUNT(*)::int AS n FROM hospital")[0]["n"]
    p = fetch_all("SELECT COUNT(*)::int AS n FROM patient")[0]["n"]
    r_open = fetch_all(
        "SELECT COUNT(*)::int AS n FROM request WHERE status ILIKE %s",
        ("%OPEN%",),
    )[0]["n"]
    r_match = fetch_all(
        "SELECT COUNT(*)::int AS n FROM request WHERE status ILIKE %s",
        ("%MATCH%",),
    )[0]["n"]
    bu_avail = fetch_all(
        "SELECT COUNT(*)::int AS n FROM blood_unit WHERE unit_status = %s",
        ("AVAILABLE",),
    )[0]["n"]
    mc = fetch_all("SELECT COUNT(*)::int AS n FROM match_candidate")[0]["n"]
    tx = fetch_all("SELECT COUNT(*)::int AS n FROM transplant")[0]["n"]
    return {
        "hospitals": h,
        "patients": p,
        "requests_marked_open": r_open,
        "requests_marked_matched_variant": r_match,
        "blood_units_available": bu_avail,
        "match_candidates": mc,
        "transplants": tx,
    }


@app.get("/v1/blood-units-available")
def blood_units_available(
    hospital_id: int = Query(..., ge=1),
    blood_group: str = Query(..., min_length=1, max_length=8),
):
    """
    Mirrors the seeded INV_BLOOD_STOCK semantic: counts AVAILABLE units tied to donors
    registered at the given registration hospital × ABO.
    """
    bg = _assert_slug(blood_group)
    if not bg:
        raise HTTPException(400, "blood_group required")
    norm_bg = bg.strip().upper()
    rows = fetch_all(
        """
        SELECT blood_group,
               unit_status,
               COUNT(*)::int AS unit_count
          FROM blood_unit bu
          JOIN blood_donation bd ON bd.blood_donation_id = bu.blood_donation_id
          JOIN donor d ON d.donor_id = bd.donor_id
         WHERE d.hospital_id = %s
           AND bu.blood_group = %s
           AND bu.unit_status = %s
         GROUP BY blood_group, unit_status
        """,
        (hospital_id, norm_bg, "AVAILABLE"),
    )
    hospital = fetch_all(
        "SELECT name FROM hospital WHERE hospital_id = %s", (hospital_id,)
    )
    hosp_name = hospital[0]["name"] if hospital else None
    return {
        "hospital_id": hospital_id,
        "hospital_name": hosp_name,
        "blood_group": norm_bg,
        "rows": rows,
    }


@app.get("/v1/open-and-matched-requests")
def open_and_matched_requests(hospital_id: int = Query(..., ge=1)):
    rows = fetch_all(
        """
        SELECT request_id, request_type, urgency_level, status, request_date::text AS request_date_iso
          FROM request
         WHERE hospital_id = %s
           AND (
                 status ILIKE %s OR status ILIKE %s OR status ILIKE %s
               )
         ORDER BY urgency_level DESC NULLS LAST, request_id DESC
        """,
        (hospital_id, "%OPEN%", "%MATCH%", "%FULFILL%"),
    )
    return {"hospital_id": hospital_id, "rows": rows}


@app.get("/v1/report/{view_slug}")
def read_report_view(view_slug: str):
    """Read-only aliases for predefined report_* views (create via database/queries_reports.sql)."""
    allowed = {
        "open-requests-by-hospital": "report_open_requests_by_hospital",
        "blood-units-available-by-site": "report_available_blood_units_by_site",
        "blood-need-vs-supply": "report_blood_need_vs_supply",
        "organ-offer-pipeline": "report_organ_offer_pipeline",
        "match-transplant-status": "report_match_and_transplant_status",
        "assistant-audit-trail": "report_assistant_audit_trail",
    }
    slug = view_slug.lower().strip()
    if slug not in allowed:
        raise HTTPException(400, "Unknown report slug")
    view_sql = allowed[slug]
    if not view_sql.isidentifier():
        raise HTTPException(500, "Unexpected view identifier")
    rows = fetch_all(f"SELECT * FROM {view_sql}")  # nosec identifier whitelisted above
    return {"view": view_sql, "rows": rows}


@app.get("/v1/patients-search")
def patients_search(
    q: str = Query("", max_length=80),
    limit: int = Query(15, ge=1, le=50),
):
    q = q.strip()
    pattern = "%" + q.replace("%", r"\%").replace("_", r"\_") + "%" if q else "%"
    rows = fetch_all(
        """
        SELECT p.patient_id, p.full_name, p.age, p.blood_group, p.risk_score, h.name AS hospital_name
          FROM patient p
          JOIN hospital h ON h.hospital_id = p.hospital_id
         WHERE p.full_name ILIKE %s OR p.contact_info ILIKE %s OR CAST(p.patient_id AS TEXT) = %s
         ORDER BY p.patient_id
         LIMIT %s
        """,
        (pattern, pattern, q, limit),
    )
    return {"query": q, "rows": rows}
