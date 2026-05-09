-- Chatbot audit: seed sql_template rows for intent_detection.template_id lookups.
-- Run after database/schema.sql, database/seed.sql, and optionally database/queries_reports.sql.

BEGIN;

INSERT INTO sql_template (intent_code, sql_text, allowed_params, active_flag)
VALUES
    ('FALLBACK', 'N/A — no SQL executed.', '{}', TRUE),
    ('CHECK_INVENTORY_ALL', 'COUNT blood_unit grouped by donor hospital (AVAILABLE)', '{"hospital_id": "int"}', TRUE),
    ('CHECK_INVENTORY_BY_TYPE', 'COUNT blood_unit by hospital and blood_group', '{"hospital_id": "int", "blood_group": "str"}', TRUE),
    ('CHECK_INVENTORY_BY_FAMILY', 'COUNT blood_unit IN (+/-) variants', '{"hospital_id": "int", "groups": ["str"]}', TRUE),
    ('LIST_HOSPITALS', 'SELECT hospital', '{}', TRUE),
    ('LIST_PATIENTS', 'SELECT patient by hospital', '{"hospital_id": "int"}', TRUE),
    ('GET_DONATIONS', 'blood_donation join donor', '{"hospital_id": "int"}', TRUE),
    ('GET_HIGH_RISK_PATIENTS', 'patient join medical_record', '{"hospital_id": "int", "risk_threshold": "num"}', TRUE),
    ('GET_TRANSPLANT_PRIORITY', 'request organ_request_details patient', '{"hospital_id": "int"}', TRUE),
    ('GET_DONORS', 'donor eligibility filter', '{"hospital_id": "int"}', TRUE),
    ('GET_PENDING_REQUESTS', 'open blood/organ requests', '{"hospital_id": "int"}', TRUE),
    ('GET_EXPIRING_UNITS', 'blood_unit AVAILABLE by expiry_date', '{}', TRUE),
    ('GET_MATCH_CANDIDATES', 'match_candidate request patient', '{"hospital_id": "int"}', TRUE),
    ('GET_TRANSPLANT_HISTORY', 'transplant lineage', '{"hospital_id": "int"}', TRUE),
    ('EXPLAIN_ALERT_INVENTORY', 'Explain hospital risk vs inventory and open blood demand', '{"hospital_id": "int"}', TRUE)
ON CONFLICT (intent_code) DO NOTHING;

COMMIT;
