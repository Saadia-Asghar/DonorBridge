"""
DonorBridge prototype — reports, Hospitals / Patients CRUD, and Assistant (chatbot).
Run from this directory: streamlit run streamlit_app.py
"""

from __future__ import annotations

import os
import sys

import streamlit as st
import pandas as pd

import db

_CHATBOT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "Chatbot"))
if os.path.isdir(_CHATBOT_ROOT) and _CHATBOT_ROOT not in sys.path:
    sys.path.insert(0, _CHATBOT_ROOT)

try:
    import chatbot_backend as chatbot_backend  # type: ignore

    _HAS_CHATBOT = True
except ImportError:
    chatbot_backend = None  # type: ignore[assignment]
    _HAS_CHATBOT = False


st.set_page_config(page_title="DonorBridge prototype", layout="wide")


@st.cache_resource
def _assistant_pg_connection():
    if not chatbot_backend:
        raise RuntimeError(
            "Chatbot backend is not importable (missing Chatbot/ folder?)."
        )
    return chatbot_backend.get_connection()

_LARGER_TYPE = """
<style>
/* Global readable typography (tables + prose + sidebar) */
html {
    font-size: 124%;
}
[data-testid="stAppViewContainer"],
[data-testid="stMarkdownContainer"],
[data-testid="stMarkdownContainer"] p,
[data-testid="stMarkdownContainer"] div,
[data-testid="stMarkdownContainer"] span,
[data-testid="stMarkdownContainer"] label {
    font-size: inherit !important;
}
[data-testid="stSidebarContent"] p,
[data-testid="stSidebarContent"] div,
[data-testid="stSidebarContent"] span,
[data-testid="stSidebarNav"] span {
    font-size: inherit !important;
}
[data-testid="stHeadingWithActionElements"] span,
[data-testid="stHeadingWithActionElements"] h1 {
    font-size: 1.85rem !important;
}
[data-testid="stTabs"] [role="tab"] {
    font-size: 1.12rem !important;
    padding-top: 0.45rem !important;
    padding-bottom: 0.45rem !important;
}
[data-testid="baseButton-secondary"],
[data-testid="baseButton-primary"] button,
.stButton button {
    font-size: 1.06rem !important;
    padding: 0.5rem 0.95rem !important;
}
[data-testid="stExpander"] summary {
    font-size: 1.08rem !important;
}
.block-container div[data-testid="stDataFrame"] {
    zoom: 1.08 !important;
}
.main .block-container {
    font-size: 1.04rem !important;
}

/* Care Clarity — tabs & expanders (teal accent) */
[data-testid="stTabs"] [role="tab"][aria-selected="true"] {
    color: #0d9488 !important;
    border-bottom-color: #0d9488 !important;
}
[data-testid="stExpander"] details {
    border: 1px solid #e2e8f0 !important;
    border-radius: 12px !important;
    background: #ffffff !important;
}
[data-testid="stExpander"] summary {
    color: #0f172a !important;
}

/* Form widgets — visible outlines on light backgrounds */
[data-testid="stTextInput"] input[type="text"],
[data-testid="stTextInput"] input:not([type]) {
    border: 1px solid #94a3b8 !important;
    border-radius: 10px !important;
    background-color: #f8fafc !important;
    color: #0f172a !important;
    padding: 0.45rem 0.65rem !important;
}
[data-testid="stTextInput"] input:focus {
    border-color: #0d9488 !important;
    outline: none !important;
    box-shadow: 0 0 0 2px rgba(13, 148, 136, 0.2) !important;
}
[data-testid="stNumberInput"] input {
    border: 1px solid #94a3b8 !important;
    border-radius: 10px !important;
    background-color: #f8fafc !important;
    color: #0f172a !important;
}
[data-testid="stNumberInput"] input:focus {
    border-color: #0d9488 !important;
    outline: none !important;
    box-shadow: 0 0 0 2px rgba(13, 148, 136, 0.2) !important;
}
[data-testid="stNumberInput"] button {
    border: 1px solid #cbd5e1 !important;
    border-radius: 8px !important;
    background: #f1f5f9 !important;
}
/* Select boxes (Base Web + newer builds) */
[data-testid="stSelectbox"] div[data-baseweb="select"] > div {
    border-color: #94a3b8 !important;
    border-radius: 10px !important;
    background-color: #f8fafc !important;
}
[data-testid="stSelectbox"]:focus-within div[data-baseweb="select"] > div {
    border-color: #0d9488 !important;
    box-shadow: 0 0 0 2px rgba(13, 148, 136, 0.15) !important;
}

/* Assistant — chat (light clinical, matches Chatbot/static) */
[data-testid="stChatMessage"] {
    background: rgba(13, 148, 136, 0.08) !important;
    border: 1px solid rgba(13, 148, 136, 0.22) !important;
    border-radius: 16px !important;
    padding: 0.55rem 0.65rem !important;
    margin-bottom: 0.6rem !important;
    box-shadow: 0 2px 12px rgba(15, 23, 42, 0.06) !important;
}
[data-testid="stChatMessage"] [data-testid="stMarkdownContainer"] p {
    line-height: 1.55;
    color: #0f172a;
}
[data-testid="stChatInput"] textarea {
    border-radius: 14px !important;
    border: 1px solid #cbd5e1 !important;
    background: #ffffff !important;
    color: #0f172a !important;
}
[data-testid="stChatInput"] textarea:focus {
    border-color: #0d9488 !important;
    box-shadow: 0 0 0 3px rgba(13, 148, 136, 0.2) !important;
}
.stChatInputToolbar {
    padding-bottom: 0.35rem !important;
}
[data-testid="stChatInputSubmitButton"] button {
    background: #0d9488 !important;
    border: none !important;
    color: #ffffff !important;
}
[data-testid="stChatInputSubmitButton"] button:hover {
    background: #0f766e !important;
}

</style>
"""
st.markdown(_LARGER_TYPE, unsafe_allow_html=True)

REPORT_VIEWS = (
    ("Open requests by hospital", "SELECT * FROM report_open_requests_by_hospital"),
    ("Available blood units by site", "SELECT * FROM report_available_blood_units_by_site"),
    ("Blood need vs supply", "SELECT * FROM report_blood_need_vs_supply"),
    ("Organ offer pipeline", "SELECT * FROM report_organ_offer_pipeline"),
    ("Match / transplant status", "SELECT * FROM report_match_and_transplant_status"),
    ("Assistant audit trail", "SELECT * FROM report_assistant_audit_trail"),
)


def sidebar_connection():
    st.sidebar.header("Database")
    st.sidebar.markdown(
        "Set **`DATABASE_URL`** before launch (see [README.md](README.md))."
    )
    if st.sidebar.button("Test connection"):
        try:
            db.test_connection()
            st.sidebar.success("Connection OK")
        except Exception as exc:
            st.sidebar.error(str(exc))


sidebar_connection()

tab_reports, tab_hospitals, tab_patients, tab_assistant = st.tabs(
    ["Reports", "Hospitals", "Patients", "Assistant"],
)

with tab_reports:
    st.subheader("Business reports (PostgreSQL views)")
    st.markdown(
        "Ensure you have executed **`database/queries_reports.sql`** once "
        "(creates/replaces `report_*` views)."
    )
    for title, sql in REPORT_VIEWS:
        try:
            rows = db.fetch_all(sql)
        except Exception as exc:
            st.error(f"**{title}** — `{exc}`")
            continue
        with st.expander(title, expanded=False):
            if not rows:
                st.caption("(no rows)")
            else:
                st.dataframe(pd.DataFrame(rows), use_container_width=True)

with tab_hospitals:
    st.subheader("Hospitals — retrieval and manipulation")

    try:
        hospitals = db.fetch_all(
            "SELECT hospital_id, name, location, contact FROM hospital ORDER BY hospital_id"
        )
        st.dataframe(pd.DataFrame(hospitals), use_container_width=True)
    except Exception as exc:
        st.error(str(exc))
        hospitals = []

    add = st.expander("Add hospital", expanded=False)
    with add:
        name = st.text_input("Name", key="h_add_name")
        location = st.text_input("Location", key="h_add_loc")
        contact = st.text_input("Contact", key="h_add_contact")
        if st.button("Insert hospital"):
            try:
                db.execute(
                    "INSERT INTO hospital (name, location, contact) VALUES (%s,%s,%s)",
                    (name.strip(), location.strip(), contact.strip()),
                )
                st.success("Inserted.")
                st.rerun()
            except Exception as exc:
                st.error(str(exc))

    upd = st.expander("Update hospital", expanded=False)
    with upd:
        ids = [h["hospital_id"] for h in hospitals]
        if not ids:
            st.info("No hospitals loaded.")
        else:
            hid = st.selectbox("Hospital ID", options=ids, key="h_upd_pick")
            sel = next((x for x in hospitals if x["hospital_id"] == hid), {})
            name_u = st.text_input("Name", value=sel.get("name", ""), key="h_upd_name")
            loc_u = st.text_input(
                "Location",
                value=sel.get("location", ""),
                key="h_upd_loc",
            )
            ct_u = st.text_input(
                "Contact",
                value=sel.get("contact", ""),
                key="h_upd_ct",
            )
            if st.button("Save changes", key="h_upd_btn"):
                try:
                    db.execute(
                        "UPDATE hospital SET name=%s, location=%s, contact=%s "
                        "WHERE hospital_id=%s",
                        (
                            name_u.strip(),
                            loc_u.strip(),
                            ct_u.strip(),
                            hid,
                        ),
                    )
                    st.success("Updated.")
                    st.rerun()
                except Exception as exc:
                    st.error(str(exc))

    dele = st.expander("Delete hospital (blocked if dependents exist)", expanded=False)
    with dele:
        ids = [h["hospital_id"] for h in hospitals]
        if not ids:
            st.info("No hospitals to delete.")
        else:
            hid_d = st.selectbox(
                "Hospital ID to delete",
                options=ids,
                key="h_del_pick",
            )
            confirm = st.checkbox(
                "I understand this deletes the row (only if FKs allow).",
                key="h_del_ck",
            )
            if st.button("Delete hospital", key="h_del_btn"):
                if not confirm:
                    st.warning("Confirm before deleting.")
                else:
                    try:
                        n = db.execute(
                            "DELETE FROM hospital WHERE hospital_id=%s",
                            (hid_d,),
                        )
                        st.success(f"Deleted {n} row(s).") if n else st.info(
                            "Nothing deleted."
                        )
                        st.rerun()
                    except Exception as exc:
                        st.error(str(exc))

with tab_patients:
    st.subheader("Patients — retrieval, add, update, delete")

    try:
        patients = db.fetch_all(
            """
            SELECT p.patient_id, p.hospital_id, p.full_name, p.age,
                   p.gender, p.blood_group, p.contact_info, p.risk_score,
                   p.created_at, h.name AS hospital_name
            FROM patient p
            JOIN hospital h ON h.hospital_id = p.hospital_id
            ORDER BY p.patient_id
            """
        )
        st.dataframe(pd.DataFrame(patients), use_container_width=True)
        hosp_opts = db.fetch_all(
            "SELECT hospital_id, name FROM hospital ORDER BY hospital_id"
        )
    except Exception as exc:
        st.error(str(exc))
        patients = []
        hosp_opts = []

    pa = st.expander("Add patient", expanded=False)
    with pa:
        if not hosp_opts:
            st.info("Load hospitals before adding patients.")
        else:
            labels = {
                f'{r["name"]} (#{r["hospital_id"]})': r["hospital_id"] for r in hosp_opts
            }
            choice = st.selectbox(
                "Hospital",
                options=list(labels.keys()),
                key="p_add_hosp_lab",
            )
            hosp_id = labels[choice]
            full_name = st.text_input("Full name", key="p_add_fn")
            age = st.number_input("Age", min_value=0, max_value=150, value=40, key="p_add_age")
            gender = st.text_input("Gender (e.g. M / F)", value="M", key="p_add_g")
            blood_group = st.text_input(
                "Blood group (e.g. O+)", value="O+", key="p_add_bg"
            )
            contact_info = st.text_input("Contact info", key="p_add_ci")
            risk_score = st.number_input(
                "Risk score", min_value=0.0, max_value=999.99, value=55.55, key="p_add_rs"
            )
            if st.button("Insert patient", key="p_add_btn"):
                try:
                    db.execute(
                        """
                        INSERT INTO patient (
                            hospital_id, full_name, age, gender,
                            blood_group, contact_info, risk_score
                        ) VALUES (%s,%s,%s,%s,%s,%s,%s)
                        """,
                        (
                            hosp_id,
                            full_name.strip(),
                            int(age),
                            gender.strip(),
                            blood_group.strip(),
                            contact_info.strip(),
                            float(risk_score),
                        ),
                    )
                    st.success("Inserted.")
                    st.rerun()
                except Exception as exc:
                    st.error(str(exc))

    pu = st.expander("Update patient", expanded=False)
    with pu:
        pids = [p["patient_id"] for p in patients] if patients else []
        if not pids:
            st.info("No patients.")
        else:
            pid = st.selectbox("Patient ID", options=pids, key="p_upd_pick")
            cur = next((x for x in patients if x["patient_id"] == pid), {})
            nh = cur.get("hospital_id")
            hosp_labels = [
                (f'{r["name"]} (#{r["hospital_id"]})', r["hospital_id"])
                for r in hosp_opts
            ]
            hosp_default_idx = next(
                (i for i, (_, hid) in enumerate(hosp_labels) if hid == nh),
                0,
            )
            hchoice = st.selectbox(
                "Hospital",
                options=[x[0] for x in hosp_labels],
                index=hosp_default_idx,
                key="p_upd_hosp_lab",
            )
            new_hospital_id = dict(hosp_labels)[hchoice] if hosp_labels else nh
            fn = st.text_input(
                "Full name",
                value=str(cur.get("full_name", "")),
                key="p_upd_fn",
            )
            ag = st.number_input(
                "Age",
                min_value=0,
                max_value=150,
                value=int(cur.get("age", 0)),
                key="p_upd_ag",
            )
            gd = st.text_input(
                "Gender",
                value=str(cur.get("gender", "")),
                key="p_upd_ge",
            )
            bg = st.text_input(
                "Blood group",
                value=str(cur.get("blood_group", "")),
                key="p_upd_bg",
            )
            ci = st.text_input(
                "Contact info",
                value=str(cur.get("contact_info", "")),
                key="p_upd_ci",
            )
            rs = st.number_input(
                "Risk score",
                min_value=0.0,
                max_value=999.99,
                value=float(cur.get("risk_score", 0)),
                key="p_upd_rs",
            )
            if st.button("Save patient", key="p_upd_btn"):
                try:
                    db.execute(
                        """
                        UPDATE patient SET
                            hospital_id=%s, full_name=%s, age=%s,
                            gender=%s, blood_group=%s,
                            contact_info=%s, risk_score=%s
                        WHERE patient_id=%s
                        """,
                        (
                            new_hospital_id,
                            fn.strip(),
                            ag,
                            gd.strip(),
                            bg.strip(),
                            ci.strip(),
                            float(rs),
                            pid,
                        ),
                    )
                    st.success("Updated.")
                    st.rerun()
                except Exception as exc:
                    st.error(str(exc))

    pdel = st.expander("Delete patient (cascade medical_record per schema)", expanded=False)
    with pdel:
        pids = [p["patient_id"] for p in patients] if patients else []
        if not pids:
            st.info("No patients.")
        else:
            dp = st.selectbox("Patient ID to delete", options=pids, key="p_del_pick")
            c2 = st.checkbox("Confirm patient delete", key="p_del_ck")
            if st.button("Delete patient", key="p_del_btn"):
                if not c2:
                    st.warning("Confirm first.")
                else:
                    try:
                        n = db.execute(
                            "DELETE FROM patient WHERE patient_id=%s", (dp,)
                        )
                        st.success(f"Deleted {n} row(s).") if n else st.info(
                            "Nothing deleted."
                        )
                        st.rerun()
                    except Exception as exc:
                        st.error(str(exc))


with tab_assistant:
    st.subheader("Natural-language assistant")
    st.caption(
        "Rule-based Q&A on the same PostgreSQL data (inventory, patients, "
        "requests, transplants). Run **`database/chatbot_sql_template_seed.sql`** "
        "so chat audit (`sql_template`) is populated."
    )

    if not _HAS_CHATBOT or chatbot_backend is None:
        st.warning(
            "The **Chatbot** package was not found. Expected folder "
            "`DonorBridge/Chatbot` next to this `prototype` directory."
        )
        st.stop()

    try:
        conn_asst = _assistant_pg_connection()
    except Exception as exc:
        st.error(f"Assistant could not connect (check DATABASE_URL): {exc}")
        st.stop()

    try:
        hospital_rows_asst = db.fetch_all(
            "SELECT hospital_id, name FROM hospital ORDER BY hospital_id"
        )
    except Exception as exc:
        st.error(str(exc))
        st.stop()

    if not hospital_rows_asst:
        st.info("No hospitals in the database — load seed data first.")
        st.stop()

    hid_opts = [(r["hospital_id"], r["name"]) for r in hospital_rows_asst]

    assistant_hospital_id = st.selectbox(
        "Scope answers to hospital",
        options=[x[0] for x in hid_opts],
        format_func=lambda i: next(n for hid, n in hid_opts if hid == i),
        key="asst_hospital_id",
    )
    assistant_role = st.selectbox(
        "Recorded role (audit)",
        ["Doctor", "Nurse", "Coordinator", "Admin"],
        index=0,
        key="asst_user_role",
    )

    if st.button("New assistant conversation", key="asst_reset"):
        st.session_state.assistant_session_id = None
        st.session_state.assistant_messages = []
        st.rerun()

    if "assistant_messages" not in st.session_state:
        st.session_state.assistant_messages = []
    if "assistant_session_id" not in st.session_state:
        st.session_state.assistant_session_id = None

    if st.session_state.assistant_session_id is None:
        st.caption(
            f"No audit session yet — **send a question** to start one "
            f"(hospital #{assistant_hospital_id} scope)."
        )
    else:
        st.caption(
            f"Session #{st.session_state.assistant_session_id} · "
            f"hospital #{assistant_hospital_id} context."
        )

    st.markdown("**Try:** blood inventory, pending requests, high-risk patients.")

    for msg in st.session_state.assistant_messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])

    chat_prompt = st.chat_input("Ask about donors, inventory, requests…")
    if chat_prompt:
        if st.session_state.assistant_session_id is None:
            st.session_state.assistant_session_id = chatbot_backend.start_chat_session(
                conn_asst,
                assistant_hospital_id or chatbot_backend.DEFAULT_HOSPITAL_ID,
                assistant_role,
            )
        st.session_state.assistant_messages.append(
            {"role": "user", "content": chat_prompt}
        )
        reply = chatbot_backend.process_user_query(
            conn_asst,
            chat_prompt,
            assistant_hospital_id or chatbot_backend.DEFAULT_HOSPITAL_ID,
            st.session_state.assistant_session_id,
        )
        st.session_state.assistant_messages.append(
            {"role": "assistant", "content": reply}
        )
        st.rerun()
