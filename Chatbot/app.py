"""Streamlit chat UI for the DonorBridge chatbot (secondary frontend).

Run with DATABASE_URL set (PostgreSQL):

    pip install -r requirements.txt
    streamlit run app.py
"""

from __future__ import annotations

import streamlit as st

from chatbot_backend import (
    DEFAULT_HOSPITAL_ID,
    process_user_query,
    start_chat_session,
    get_connection,
)


st.set_page_config(page_title="DonorBridge Chatbot", page_icon="🩸")

_BLUE_CHAT_CSS = """
<style>
[data-testid="stChatMessage"] {
    background: rgba(13, 148, 136, 0.08) !important;
    border: 1px solid rgba(13, 148, 136, 0.22) !important;
    border-radius: 16px !important;
    padding: 0.55rem 0.65rem !important;
    margin-bottom: 0.6rem !important;
    box-shadow: 0 2px 12px rgba(15, 23, 42, 0.06) !important;
}
[data-testid="stChatInput"] textarea {
    border-radius: 14px !important;
    border: 1px solid #cbd5e1 !important;
    background: #ffffff !important;
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
st.markdown(_BLUE_CHAT_CSS, unsafe_allow_html=True)


@st.cache_resource
def get_cached_connection():
    return get_connection()


def get_hospitals(conn):
    cur = conn.cursor()
    cur.execute("SELECT hospital_id, name FROM hospital ORDER BY hospital_id")
    return cur.fetchall()


st.title("DonorBridge Chatbot")
st.caption(
    "Rule-based SQL chatbot (PostgreSQL). Ask about blood inventory, donors, "
    "high-risk patients, requests, matches, or transplant priority."
)

try:
    conn = get_cached_connection()
except RuntimeError as e:
    st.error(str(e))
    st.info("Configure DATABASE_URL or copy ../prototype/.env next to DonorBridge root.")
    st.stop()

with st.sidebar:
    st.header("Settings")
    hospitals = get_hospitals(conn)
    hospital_id = st.selectbox(
        "Hospital",
        options=[h[0] for h in hospitals],
        format_func=lambda hid: next(name for i, name in hospitals if i == hid),
        index=0 if hospitals else None,
    )
    user_role = st.selectbox(
        "Role", ["Doctor", "Nurse", "Coordinator", "Admin"], index=0
    )

    st.markdown("**Try asking:**")
    st.markdown(
        "- What is the inventory for O- blood?\n"
        "- Is there any shortage or low stock?\n"
        "- Who are the high-risk patients?\n"
        "- Who should get the next kidney transplant?\n"
        "- Show me eligible donors.\n"
        "- List the pending requests.\n"
        "- Show me the match candidates.\n"
        "- Which blood units are expiring soon?\n"
        "- Show me the transplant history.\n"
        "- Why is Hospital 1 at risk?"
    )

    if st.button("New chat session"):
        st.session_state.pop("messages", None)
        st.session_state.pop("session_id", None)
        st.rerun()

if "session_id" not in st.session_state:
    st.session_state.session_id = start_chat_session(
        conn, hospital_id or DEFAULT_HOSPITAL_ID, user_role
    )

if "messages" not in st.session_state:
    st.session_state.messages = []

st.caption(f"Session #{st.session_state.session_id} · {user_role}")

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

prompt = st.chat_input("Ask a question…")
if prompt:
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    reply = process_user_query(
        conn,
        prompt,
        hospital_id or DEFAULT_HOSPITAL_ID,
        st.session_state.session_id,
    )
    st.session_state.messages.append({"role": "assistant", "content": reply})
    with st.chat_message("assistant"):
        st.markdown(reply)
