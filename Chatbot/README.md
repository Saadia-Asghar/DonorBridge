# DonorBridge — Healthcare Resource Chatbot

A rule-based SQL chatbot for the **DonorBridge** healthcare resource optimization
system. It uses the same **PostgreSQL** database as the parent DonorBridge project
(this repo is often nested at `DonorBridge/Chatbot`).

No LLM: regex intent matching, parameterized **SELECT** queries, and formatted
replies. Sessions are logged to **`chat_session`**, **`chat_message`**,
**`intent_detection`**, and **`query_execution_log`** (PostgreSQL DDL in the
main repo’s `database/schema.sql`).

## Quick start (PostgreSQL)

Prerequisites: a running Postgres instance with DonorBridge DDL, seed data, and
chatbot template seeds applied from the **repository root** (`DonorBridge/`):

1. `database/schema.sql`
2. `database/seed.sql`
3. `database/queries_reports.sql` (optional for reports / Streamlit parity)
4. **`database/chatbot_sql_template_seed.sql`** (required for audit `template_id` lookups)

Configure the connection string (same as the Streamlit prototype):

- Set **`DATABASE_URL`** (or **`DONORBRIDGE_DATABASE_URL`**) in the environment, or
- Place **`prototype/.env`** in the sibling folder `../prototype/.env` relative
  to `Chatbot/` (the backend auto-loads that path).

```powershell
python -m venv venv
venv\Scripts\Activate.ps1
pip install -r requirements.txt
python api.py
```

Then open [http://127.0.0.1:5000/](http://127.0.0.1:5000/).

### Alternative UIs

```bash
python chatbot_backend.py
streamlit run app.py
```

### Smoke test

From `Chatbot/` with `DATABASE_URL` set:

```bash
python smoke_test.py
```

## Offline SQLite demo (legacy)

`schema.sql`, `init_db.py`, and `donorbridge.db` remain for a **standalone**
SQLite demo matching an older snapshot. Production answers against your real
campus data **require PostgreSQL** as above—not `python init_db.py`.

## Project layout

| File / folder                         | Purpose                                               |
|---------------------------------------|-------------------------------------------------------|
| `chatbot_backend.py`                  | Intents, PostgreSQL SQL templates, formatting, audit  |
| `api.py`                              | Flask REST API + static UI                            |
| `app.py`                              | Streamlit UI                                          |
| `smoke_test.py`                       | Intent + audit regression smoke                       |
| `schema.sql` / `init_db.py`           | Legacy SQLite bootstrap only                          |

## Schema (PostgreSQL, DonorBridge)

Operational tables use **lowercase** identifiers (`hospital`, `patient`, `request`,
`blood_unit`, …). Aggregate “inventory” in answers is **`COUNT(*) of AVAILABLE
blood_unit`** units attributed to donors registered at a hospital—not a legacy
denormalized `BLOOD_INVENTORY` summary table.

### Chatbot audit subsystem

| Table                 | Purpose |
|-----------------------|---------|
| `chat_session`        | Conversation scope (`hospital_id`, `user_role`)       |
| `chat_message`        | Each user/bot utterance                               |
| `sql_template`        | Canonical template rows (seed **`chatbot_sql_template_seed.sql`**) |
| `intent_detection`    | FK to `sql_template`; one row per classified user message |
| `query_execution_log` | `intent_id`, `param_json`, `execution_status`, `rows_returned` |

## Intent map

| Keywords / question type | Intent ID | Data source |
|--------------------------|-----------|-------------|
| why / explain / at risk  | `EXPLAIN_ALERT` | Aggregated `blood_unit` supply vs open `blood_request_details` |
| inventory / blood stock | `CHECK_INVENTORY` | `blood_unit` → `blood_donation` → `donor` by hospital |
| high-risk patients      | `GET_HIGH_RISK_PATIENTS` | `patient` ⋈ `medical_record` |
| transplant queue        | `GET_TRANSPLANT_PRIORITY` | `request` ⋈ `organ_request_details` |
| eligible donors         | `GET_DONORS` | `donor` |
| pending / open requests | `GET_PENDING_REQUESTS` | `request` with `status ILIKE '%OPEN%'` |
| match candidates        | `GET_MATCH_CANDIDATES` | `match_candidate` ⋈ `request` |
| expiring units          | `GET_EXPIRING_UNITS` | `blood_unit` (`AVAILABLE`) by `expiry_date` |
| transplant history      | `GET_TRANSPLANT_HISTORY` | `transplant` ⋈ chain to `patient` |

## Safety

- **SQL-injection safe** — parameters use **`%s`** placeholders only.
- **Bounded output** — listing queries use **`LIMIT 10`**.
- **SELECT-only** for operational data — `_assert_select_only()` on intent SQL.
- **Audit** — inserts only into chat/audit tables, not into operational entities.

## REST API

| Endpoint                    | Method | Purpose                          |
|-----------------------------|--------|----------------------------------|
| `/api/health`               | GET    | Health + DB configuration hint   |
| `/api/hospitals`            | GET    | Hospital dropdown                |
| `/api/intents`              | GET    | Example questions                |
| `/api/session`              | POST   | New `chat_session`               |
| `/api/chat`                 | POST   | User message → reply             |
| `/api/history/<session_id>` | GET    | Message history                  |

## Adding a new intent

1. Add patterns to `INTENT_PATTERNS`.
2. Add a `SELECT` with `%s` to `INTENT_TO_SQL` and a row in
   `database/chatbot_sql_template_seed.sql` with matching `intent_code`.
3. Register a `FORMATTERS` entry.
