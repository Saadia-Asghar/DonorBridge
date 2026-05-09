-- DonorBridge sample data (PostgreSQL). Run after schema.sql.
-- Targets ≥10 rows per table while respecting XOR match rules and UNIQUE(intent_code)/(hospital_id,blood_group)/Transplant(match_id).

BEGIN;

TRUNCATE TABLE
    blood_request_details,
    organ_request_details,
    query_execution_log,
    intent_detection,
    transplant,
    match_candidate,
    blood_unit,
    blood_donation,
    blood_inventory_location,
    organ_offer,
    request,
    medical_record,
    patient,
    donor,
    chat_message,
    chat_session,
    sql_template,
    hospital
RESTART IDENTITY CASCADE;

-- 12 hospitals
INSERT INTO hospital (hospital_id, name, location, contact)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'City General Hospital', 'Metro City — Downtown Campus', '+1 (555) 010-4400'),
    (2, 'Regional Transplant Center', 'North County Medical Park', '+1 (555) 019-9900'),
    (3, 'Riverside Community Hospital', 'West River Waterfront', '+1 (555) 020-3310'),
    (4, 'Lakeshore Medical Center', 'Lakeshore North', '+1 (555) 022-8841'),
    (5, 'Summit County Trauma Annex', 'Summit Spine Access Road', '+1 (555) 031-7712'),
    (6, 'Harbor Pediatrics Specialty', 'Inner Harbor Wharf', '+1 (555) 044-6613'),
    (7, 'Plains Veteran Care VA Affiliate', 'High Plains Drive', '+1 (555) 055-2290'),
    (8, 'Copperbelt Mining Town Clinic Hub', 'Route 212 Mile 9', '+1 (555) 066-9932'),
    (9, 'Desert Oasis Dialysis Annex', 'Junction 91 Exit D', '+1 (555) 077-1104'),
    (10, 'Pinewood Teaching Hospital North', 'Faculty Quadrant B', '+1 (555) 088-5566'),
    (11, 'Frostbite Urgent Surgical Tower', 'Arctic View Boulevard', '+1 (555) 099-8877'),
    (12, 'Meadowlark Blood Center Shared Services', 'Meadowlark Logistics Park', '+1 (555) 100-2020');

-- 14 patients across hospitals (≥10)
INSERT INTO patient (
    patient_id, hospital_id, full_name, age, gender, blood_group,
    contact_info, risk_score, created_at
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'Maria Chen', 54, 'F', 'O+', 'maria.chen.email@example.com', 82.50, TIMESTAMP '2026-01-08 09:30:00'),
    (2, 2, 'Robert Ali', 62, 'M', 'AB+', 'robert.ali.sms@example.com', 91.20, TIMESTAMP '2025-11-20 14:00:00'),
    (3, 1, 'Ana Reyes', 41, 'F', 'AB+', 'ana.reyes.email@example.com', 45.30, TIMESTAMP '2026-02-01 11:15:00'),
    (4, 1, 'James Holt', 33, 'M', 'A-', 'james.holt.email@example.com', 71.05, TIMESTAMP '2026-04-03 06:05:00'),
    (5, 2, 'Sofía Mendez', 48, 'F', 'AB+', 'sofia.mendez.sms@example.com', 66.90, TIMESTAMP '2025-09-09 09:09:00'),
    (6, 2, 'Carla Evans', 51, 'F', 'O+', 'carla.evans.email@example.com', 88.75, TIMESTAMP '2024-06-01 12:40:00'),
    (7, 3, 'Devon Willis', 19, 'M', 'B-', 'devon.willis.email@example.com', 62.80, TIMESTAMP '2026-02-14 10:00:00'),
    (8, 4, 'Hannah Öztürk', 67, 'F', 'A+', 'hannah.ozturk.sms@example.com', 78.95, TIMESTAMP '2025-12-01 16:08:00'),
    (9, 5, 'Mateo Alvarez-Briggs', 28, 'M', 'O-', 'mateo.av.alvarez@example.com', 88.05, TIMESTAMP '2026-03-03 06:52:00'),
    (10, 6, 'Priya Kannan', 9, 'F', 'AB-', 'pkannan.careteam@example.com', 93.42, TIMESTAMP '2025-10-09 07:58:00'),
    (11, 7, 'Quentin Vogel', 71, 'M', 'B+', 'qvogel.va@example.com', 71.62, TIMESTAMP '2025-06-06 06:06:00'),
    (12, 8, 'Ruth Okonkwo-Patel', 45, 'F', 'A-', 'rokpatel.family@example.com', 74.71, TIMESTAMP '2025-08-08 09:41:00'),
    (13, 9, 'Sam Dupont', 38, 'M', 'O+', 'samdupont.reg@example.com', 82.93, TIMESTAMP '2025-07-07 07:07:00'),
    (14, 10, 'Taryn Bishop', 55, 'F', 'AB+', 'tbishop.facultyhosp@example.com', 76.82, TIMESTAMP '2025-09-09 09:51:22');

INSERT INTO medical_record (
    record_id, patient_id, diagnosis, severity_level, stage, hemoglobin_level, updated_at
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'Iron deficiency anemia with transfusion dependency', 'High', 'Stage III', 8.20, TIMESTAMP '2026-05-07 16:45:00'),
    (2, 2, 'End-stage renal disease — listed for kidney transplantation', 'Critical', 'Awaiting graft', 10.05, TIMESTAMP '2026-04-22 10:00:00'),
    (3, 3, 'Pre-operative anemia prior to orthopedic surgery', 'Moderate', 'Pre-op clearance', 11.48, TIMESTAMP '2026-04-01 08:20:00'),
    (4, 4, 'Splenic venous hemorrhage shock — massive transfusion protocol candidate', 'High', 'ICU POD1', 6.95, TIMESTAMP '2026-05-08 06:05:00'),
    (5, 5, 'Acute hemorrhagic anemia after duodenal bleed', 'High', 'Medical floor', 9.42, TIMESTAMP '2026-04-06 07:08:00'),
    (6, 6, 'Hepatic failure — transplant evaluation', 'Critical', 'MELD 28 awaiting graft', NULL, TIMESTAMP '2026-03-10 09:03:00'),
    (7, 7, 'Sickle complications — VOC with hemolysis surge', 'High', 'Ward stabilization', 7.92, TIMESTAMP '2026-02-15 11:41:02'),
    (8, 8, 'Dilated cardiomyopathy — bridging toward heart transplant listing', 'High', 'Outpatient escalation', NULL, TIMESTAMP '2025-12-10 07:52:52'),
    (9, 9, 'Polytrauma with operative repair — anemia', 'Moderate', 'STEP-DOWN POD3', 9.93, TIMESTAMP '2026-03-04 12:52:53'),
    (10, 10, 'APL-like leukemic panel negative — anemia of chronic disease pediatric', 'High', 'Onc inpatient', 8.11, TIMESTAMP '2025-10-10 06:53:53'),
    (11, 11, 'Anemia COPD GOLD D — dyspnea on exertion composite', 'Moderate', 'Pulmonary rehab', 11.02, TIMESTAMP '2025-06-08 06:53:53'),
    (12, 12, 'Thalas minor co-infection anemia — MTP consult', 'Low', 'Mining clinic liaison', 10.93, TIMESTAMP '2025-08-13 06:53:53'),
    (13, 13, 'CKD anemia pre-dialysis', 'Moderate', 'Arteriovenous maturation', NULL, TIMESTAMP '2025-07-10 06:53:53'),
    (14, 14, 'Post-chemotherapy marrow suppression anemia', 'High', 'Onc inpatient week 6', 8.93, TIMESTAMP '2025-09-11 07:53:53'),
    (15, 1, 'Follow-up anemia — stable on IV iron bridging', 'Low', 'Outpatient oncology', 9.93, TIMESTAMP '2026-01-07 06:53:53'),
    (16, 2, 'Post-transplant clinic iron panel trend', 'Low', 'SIX-month clinic', NULL, TIMESTAMP '2026-05-06 06:53:53'),
    (17, 13, 'Parathyroid-mediated anemia escalation', 'Moderate', 'Dialysis chair day 412', NULL, TIMESTAMP '2026-03-06 06:53:53'),
    (18, 14, 'Neutrophil rebound — supportive transfusion withheld', 'Low', 'Discharge readiness', NULL, TIMESTAMP '2025-09-18 06:53:53'),
    (19, 10, 'Pediatrics growth curve catch-up — nutrition consult', 'Low', 'Clinic POD90', NULL, TIMESTAMP '2025-11-19 06:53:53'),
    (20, 7, 'Second VOC admission anemia trend', 'High', 'ICU POD2 revisit', 7.45, TIMESTAMP '2026-04-06 06:53:53');

-- 26 donors — whole-blood-capable donors + deceased organ cohort (later used only by organ_offer)
INSERT INTO donor (
    donor_id, hospital_id, full_name, age, blood_group, donor_type,
    contact_info, availability_status, eligibility_status, last_donation_date
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'Liam Okafor', 29, 'O+', 'Whole blood', '+1 (555) 080-7711', 'Available', 'Eligible', DATE '2025-11-10'),
    (2, 2, 'Ava Singh', 41, 'A+', 'Deceased organ donor referral', '+1 (555) 030-5544 registry', 'One-time retrieval', 'Cleared pathology', DATE '2025-12-15'),
    (3, 1, 'Marcus Lee', 37, 'B+', 'Whole blood', '+1 (555) 088-9033', 'Available', 'Eligible', DATE '2025-10-20'),
    (4, 1, 'Kim Park', 28, 'A-', 'Whole blood', '+1 (555) 011-8844', 'Available', 'Eligible', DATE '2025-11-25'),
    (5, 2, 'Elena Kozak', 52, 'AB+', 'Whole blood', '+1 (555) 099-6611', 'Available', 'Eligible', DATE '2026-02-02'),
    (6, 2, 'Noah Bennett', 38, 'O-', 'Deceased multi-organ donor', '+1 (555) 040-7799 donor registry', 'Retrieval complete', 'Extended consent donor card on file', DATE '2026-05-06'),
    (7, 3, 'Iris Calder', 42, 'B-', 'Whole blood', '+1 (555) 120-1201', 'Available', 'Eligible', DATE '2025-07-07'),
    (8, 4, 'Jonas Pryce', 35, 'A+', 'Whole blood Apheresis', '+1 (555) 121-2121', 'Available', 'Eligible', DATE '2025-06-06'),
    (9, 5, 'Kelly Yamamoto-Mensah', 31, 'O-', 'Whole blood', '+1 (555) 130-9191', 'Available', 'Eligible', DATE '2025-07-07'),
    (10, 6, 'Leo Ibrahim', 24, 'AB-', 'Plateletpheresis', '+1 (555) 131-7171', 'Available', 'Eligible', DATE '2025-06-06'),
    (11, 7, 'Morgan Singh-Ross', 40, 'B+', 'Whole blood', '+1 (555) 141-6161', 'Available', 'Eligible', DATE '2025-06-06'),
    (12, 8, 'Nina Petrov-Kline', 27, 'A-', 'Whole blood MTP roster', '+1 (555) 151-9191', 'Available', 'Eligible', DATE '2025-06-06'),
    (13, 9, 'Owen Delacroix', 36, 'O+', 'Whole blood night shift cohort', '+1 (555) 161-8181', 'Available', 'Eligible', DATE '2025-05-06'),
    (14, 10, 'Paula Reyes-Dutta', 33, 'AB+', 'Whole blood residency drive', '+1 (555) 171-7171', 'Available', 'Eligible', DATE '2025-04-06'),
    (15, 11, 'Quincy Farah', 45, 'A+', 'Whole blood alpine strike team', '+1 (555) 181-7171', 'Available', 'Eligible', DATE '2025-06-06'),
    (16, 12, 'Rafi Chen-Bello', 38, 'B-', 'Cryo eligible whole blood combo', '+1 (555) 191-7171', 'Available', 'Eligible', DATE '2025-06-06'),
    (17, 1, 'Sarah Holm', 22, 'O-', 'Student drive donor', '+1 (555) 201-7171', 'Available', 'Eligible', DATE '2025-06-06'),
    (18, 2, 'Tomás Verdugo', 55, 'A-', 'Rare antigen registry', '+1 (555) 211-7171', 'Available', 'Eligible', DATE '2025-05-06'),
    (19, 3, 'Uma Lichtenberg', 29, 'B+', 'Whole blood commuter slot', '+1 (555) 221-7171', 'Available', 'Eligible', DATE '2026-03-06'),
    (20, 4, 'Vik Rao', 34, 'AB+', 'Double red cell', '+1 (555) 231-7171', 'Deferred 14d', 'Temp deferral anemia', DATE '2025-12-06'),
    (21, 5, 'Wren Kostas', 26, 'O+', 'Convalescent adjunct flag cleared', '+1 (555) 241-7171', 'Available', 'Eligible', DATE '2025-05-06'),
    (22, 6, 'Xiomara Petit', 50, 'A+', 'Apheresis slot only', '+1 (555) 251-7171', 'Unavailable', 'Travel Zika deferral hold', DATE '2024-06-06'),
    (23, 7, 'Yusef Calderon', 33, 'B+', 'Military MTP cadre donor', '+1 (555) 261-7171', 'Available', 'Eligible', DATE '2026-03-06'),
    (24, 8, 'Zaria Okoye', 37, 'O-', 'Rare donor registry cross-match standby', '+1 (555) 271-7171', 'Standby roster', 'Eligible sentinel', DATE '2025-11-06'),
    (25, 3, 'Deceased donor decedent record D-ALPHA', 50, 'A+', 'Deceased organ donor referral registry', '+1 (555) 281-7171 deceased', 'Retrieval complete', 'Authorizing surrogate chart', DATE '2026-03-06'),
    (26, 4, 'Deceased donor decedent record D-BETA', 46, 'B-', 'Living-deceased transitional donation program', '+1 (555) 291-7171 deceased', 'Retrieval staged', 'Tissue committee approved', DATE '2026-04-06');

-- Requests — twenty-nine rows: seventeen BLOOD, twelve ORGAN (detail tables ≥10 rows each)
INSERT INTO request (
    request_id, patient_id, hospital_id, request_type, urgency_level, status, request_date
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 1, 'BLOOD', 5, 'OPEN', TIMESTAMP '2026-05-08 07:20:00'),
    (2, 3, 1, 'BLOOD', 2, 'FULFILLED', TIMESTAMP '2026-04-18 13:05:00'),
    (3, 2, 2, 'ORGAN', 5, 'MATCHED', TIMESTAMP '2025-08-03 09:40:00'),
    (4, 4, 1, 'BLOOD', 5, 'OPEN', TIMESTAMP '2026-05-08 06:07:00'),
    (5, 5, 2, 'BLOOD', 4, 'OPEN', TIMESTAMP '2026-04-06 07:09:00'),
    (6, 6, 2, 'ORGAN', 5, 'MATCHED', TIMESTAMP '2025-06-09 09:41:00'),
    (7, 7, 3, 'BLOOD', 5, 'OPEN', TIMESTAMP '2026-02-16 06:52:53'),
    (8, 8, 4, 'ORGAN', 4, 'OPEN', TIMESTAMP '2025-12-12 12:53:53'),
    (9, 9, 5, 'BLOOD', 3, 'OPEN', TIMESTAMP '2026-03-06 06:53:53'),
    (10, 10, 6, 'BLOOD', 4, 'OPEN', TIMESTAMP '2025-10-09 06:53:53'),
    (11, 11, 7, 'BLOOD', 2, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (12, 12, 8, 'BLOOD', 3, 'OPEN', TIMESTAMP '2025-08-12 06:53:53'),
    (13, 13, 9, 'ORGAN', 5, 'MATCHED', TIMESTAMP '2025-07-10 06:53:53'),
    (14, 14, 10, 'BLOOD', 2, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (15, 1, 11, 'BLOOD', 1, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (16, 2, 12, 'ORGAN', 3, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (17, 3, 1, 'ORGAN', 2, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (18, 4, 5, 'BLOOD', 4, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (19, 5, 6, 'ORGAN', 4, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (20, 6, 7, 'BLOOD', 3, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (21, 7, 8, 'ORGAN', 2, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (22, 8, 9, 'BLOOD', 5, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (23, 9, 10, 'ORGAN', 3, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (24, 10, 11, 'BLOOD', 2, 'FULFILLED', TIMESTAMP '2026-06-06 06:53:53'),
    (25, 11, 12, 'ORGAN', 5, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (26, 12, 2, 'BLOOD', 1, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (27, 13, 3, 'ORGAN', 4, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (28, 14, 4, 'BLOOD', 2, 'OPEN', TIMESTAMP '2026-06-06 06:53:53'),
    (29, 11, 5, 'ORGAN', 3, 'OPEN', TIMESTAMP '2026-06-06 06:54:12');

INSERT INTO blood_request_details (request_id, blood_group_required, units_required, required_by)
VALUES
    (1, 'O+', 4, TIMESTAMP '2026-05-09 18:00:00'),
    (2, 'AB+', 2, TIMESTAMP '2026-04-25 07:30:00'),
    (4, 'A-', 6, TIMESTAMP '2026-05-08 09:02:00'),
    (5, 'AB+', 3, TIMESTAMP '2026-04-07 06:59:40'),
    (7, 'B-', 5, TIMESTAMP '2026-02-17 12:53:53'),
    (9, 'O-', 4, TIMESTAMP '2026-03-07 12:53:53'),
    (10, 'AB-', 2, TIMESTAMP '2025-10-10 12:53:53'),
    (11, 'B+', 4, TIMESTAMP '2026-06-07 12:53:53'),
    (12, 'A-', 8, TIMESTAMP '2025-08-13 12:53:53'),
    (14, 'AB+', 6, TIMESTAMP '2026-06-07 12:53:53'),
    (15, 'O+', 8, TIMESTAMP '2026-06-07 12:53:53'),
    (18, 'O+', 4, TIMESTAMP '2026-06-07 12:53:53'),
    (20, 'AB+', 3, TIMESTAMP '2026-06-07 12:53:53'),
    (22, 'B+', 5, TIMESTAMP '2026-06-07 12:53:53'),
    (24, 'AB-', 2, TIMESTAMP '2026-06-07 12:53:53'),
    (26, 'B+', 3, TIMESTAMP '2026-06-07 12:53:53'),
    (28, 'A+', 4, TIMESTAMP '2026-06-07 12:53:53');

INSERT INTO organ_request_details (request_id, organ_type_required, max_wait_time_days, hla_notes)
VALUES
    (3, 'Kidney', 365.0, 'HLA DRB1 mismatch acceptable per protocol revision 2025; sensitization screened negative.'),
    (6, 'Liver', 120.0, 'ABO-compatible; bridge segment living-donor evaluation if graft wait exceeds 45 days.'),
    (8, 'Heart', 90.5, 'UNOS listing active; ECMO bridging contraindications cleared peri-listing.'),
    (13, 'Kidney–Pancreas', 540.7, 'Simultaneous K-P priority window if HbA1c remains target four consecutive draws.'),
    (16, 'Lung bilateral', 60.5, 'LAS score refresh weekly; bronchoscopy cultures negative.'),
    (17, 'Small bowel', 45.9, 'Total parenteral nutrition line sepsis history — expedited multidisciplinary review.'),
    (19, 'Pancreas islet adjunct', 200.9, 'Islet adjunct study arm open if crossmatch negative.'),
    (21, 'Kidney redo', 300.9, 'Second graft permissible if DSA MFI suppressed below sentinel curve.'),
    (23, 'Liver redo', 80.9, 'Hepato-pulmonary ratio improving on terlipressin hold.'),
    (25, 'Cornea dual', 30.9, 'Ocular surface dryness protocol — tissue bank notified.'),
    (27, 'Kidney preemptive bridging slot', 400.9, 'Preemptive living donor chain reserved pending thaw crossmatch.'),
    (29, 'Simultaneous multivisceral plate', 95.5, 'Multidisciplinary board approved composite procurement window 48h.');

-- 26 blood donations (no donations for deceased-only donors 2, 6, 25, 26)
INSERT INTO blood_donation (
    blood_donation_id, donor_id, donation_date, quantity_donated_ml, outcome
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, TIMESTAMP '2025-11-10 10:15:00', 470, 'Completed — routine screening cleared'),
    (2, 3, TIMESTAMP '2025-10-20 11:05:00', 450, 'Completed'),
    (3, 4, TIMESTAMP '2025-11-25 08:42:00', 455, 'Completed — MTP clearance'),
    (4, 5, TIMESTAMP '2026-02-02 13:58:00', 492, 'Completed — ferritin within range'),
    (5, 7, TIMESTAMP '2026-03-06 06:53:53', 460, 'Completed'),
    (6, 8, TIMESTAMP '2026-03-07 06:53:53', 470, 'Completed'),
    (7, 9, TIMESTAMP '2026-03-08 06:53:53', 480, 'Completed'),
    (8, 10, TIMESTAMP '2026-03-09 06:53:53', 410, 'Completed'),
    (9, 11, TIMESTAMP '2026-03-10 06:53:53', 490, 'Completed'),
    (10, 12, TIMESTAMP '2026-03-11 06:53:53', 420, 'Completed'),
    (11, 13, TIMESTAMP '2026-03-12 06:53:53', 473, 'Completed'),
    (12, 14, TIMESTAMP '2026-03-13 06:53:53', 478, 'Completed'),
    (13, 15, TIMESTAMP '2026-03-14 06:53:53', 455, 'Completed'),
    (14, 16, TIMESTAMP '2026-03-15 06:53:53', 440, 'Completed'),
    (15, 17, TIMESTAMP '2026-03-16 06:53:53', 466, 'Completed'),
    (16, 18, TIMESTAMP '2026-03-17 06:53:53', 459, 'Completed'),
    (17, 19, TIMESTAMP '2026-03-18 06:53:53', 480, 'Completed'),
    (18, 20, TIMESTAMP '2025-11-06 09:10:00', 472, 'Completed — prior to deferral window'),
    (19, 21, TIMESTAMP '2026-03-19 06:53:53', 469, 'Completed'),
    (20, 23, TIMESTAMP '2026-03-20 06:53:53', 478, 'Completed'),
    (21, 24, TIMESTAMP '2026-03-21 06:53:53', 459, 'Completed'),
    (22, 1, TIMESTAMP '2026-01-10 11:20:00', 460, 'Completed — repeat donor'),
    (23, 3, TIMESTAMP '2026-04-01 08:00:00', 455, 'Completed'),
    (24, 7, TIMESTAMP '2026-04-02 08:00:00', 444, 'Completed'),
    (25, 12, TIMESTAMP '2026-04-03 08:00:00', 466, 'Completed'),
    (26, 22, TIMESTAMP '2024-06-06 08:00:00', 442, 'Completed — historical file before travel hold');

-- One unit per donation; groups match donor ABO (expiry ≥ donation date)
INSERT INTO blood_unit (
    blood_unit_id, blood_donation_id, blood_group, volume_ml, expiry_date, unit_status
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'O+', 248, DATE '2025-12-22', 'AVAILABLE'),
    (2, 2, 'B+', 255, DATE '2025-12-01', 'AVAILABLE'),
    (3, 3, 'A-', 267, DATE '2026-01-05', 'AVAILABLE'),
    (4, 4, 'AB+', 251, DATE '2026-03-12', 'RESERVED'),
    (5, 5, 'B-', 260, DATE '2026-04-20', 'AVAILABLE'),
    (6, 6, 'A+', 262, DATE '2026-04-21', 'AVAILABLE'),
    (7, 7, 'O-', 258, DATE '2026-04-22', 'AVAILABLE'),
    (8, 8, 'AB-', 248, DATE '2026-04-23', 'AVAILABLE'),
    (9, 9, 'B+', 250, DATE '2026-04-24', 'AVAILABLE'),
    (10, 10, 'A-', 249, DATE '2026-04-25', 'AVAILABLE'),
    (11, 11, 'O+', 252, DATE '2026-04-26', 'AVAILABLE'),
    (12, 12, 'AB+', 253, DATE '2026-04-27', 'AVAILABLE'),
    (13, 13, 'A+', 254, DATE '2026-04-28', 'AVAILABLE'),
    (14, 14, 'B-', 256, DATE '2026-04-29', 'AVAILABLE'),
    (15, 15, 'O-', 257, DATE '2026-04-30', 'AVAILABLE'),
    (16, 16, 'A-', 258, DATE '2026-05-01', 'AVAILABLE'),
    (17, 17, 'B+', 259, DATE '2026-05-02', 'AVAILABLE'),
    (18, 18, 'AB+', 260, DATE '2025-12-18', 'AVAILABLE'),
    (19, 19, 'O+', 261, DATE '2026-05-03', 'AVAILABLE'),
    (20, 20, 'B+', 262, DATE '2026-05-04', 'AVAILABLE'),
    (21, 21, 'O-', 263, DATE '2026-05-05', 'AVAILABLE'),
    (22, 22, 'O+', 230, DATE '2026-02-20', 'RESERVED'),
    (23, 23, 'B+', 240, DATE '2026-05-15', 'AVAILABLE'),
    (24, 24, 'B-', 241, DATE '2026-05-16', 'AVAILABLE'),
    (25, 25, 'A-', 242, DATE '2026-05-17', 'AVAILABLE'),
    (26, 26, 'A+', 243, DATE '2024-07-20', 'DISCARDED');

INSERT INTO blood_inventory_location (inventory_id, hospital_id, blood_group, last_updated)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'O+', TIMESTAMP '2026-05-08 08:00:00'),
    (2, 1, 'AB+', TIMESTAMP '2026-04-19 09:00:00'),
    (3, 1, 'B+', TIMESTAMP '2026-04-10 12:15:00'),
    (4, 1, 'A-', TIMESTAMP '2026-05-08 06:15:00'),
    (5, 1, 'O-', TIMESTAMP '2026-05-06 06:53:53'),
    (6, 2, 'A+', TIMESTAMP '2026-04-28 15:30:00'),
    (7, 2, 'AB+', TIMESTAMP '2026-05-01 10:00:00'),
    (8, 2, 'O-', TIMESTAMP '2026-04-23 07:52:17'),
    (9, 2, 'B+', TIMESTAMP '2026-05-06 06:53:53'),
    (10, 3, 'O+', TIMESTAMP '2026-05-06 06:53:53'),
    (11, 3, 'B-', TIMESTAMP '2026-05-06 06:53:53'),
    (12, 4, 'A+', TIMESTAMP '2026-05-06 06:53:53'),
    (13, 5, 'AB-', TIMESTAMP '2026-05-06 06:53:53'),
    (14, 6, 'AB+', TIMESTAMP '2026-05-06 06:53:53'),
    (15, 7, 'B+', TIMESTAMP '2026-05-06 06:53:53'),
    (16, 8, 'A-', TIMESTAMP '2026-05-06 06:53:53');

INSERT INTO organ_offer (
    organ_offer_id, donor_id, organ_type, availability_status, retrieval_date, medical_clearance
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 2, 'Kidney', 'ALLOCATED', TIMESTAMP '2026-04-26 06:40:00', 'Final serology negative; anatomical suitability confirmed'),
    (2, 6, 'Liver', 'ALLOCATED', TIMESTAMP '2026-05-07 06:18:48', 'No steatosis; hemodynamics stable intra-op'),
    (3, 2, 'Heart', 'ALLOCATED', TIMESTAMP '2026-04-26 07:00:00', 'Biopsy margin negative for rejection panel'),
    (4, 25, 'Lung', 'ALLOCATED', TIMESTAMP '2026-03-07 05:10:00', 'Bronchoscopy cultures pre-retrieval negative'),
    (5, 25, 'Kidney', 'ALLOCATED', TIMESTAMP '2026-03-07 05:12:00', 'Crossmatch acceptable with desensitization bridge'),
    (6, 26, 'Liver', 'ALLOCATED', TIMESTAMP '2026-04-08 04:40:00', 'Split-liver allocation segment B reserved'),
    (7, 26, 'Intestine', 'ALLOCATED', TIMESTAMP '2026-04-08 04:45:00', 'TPN wean candidate approved'),
    (8, 6, 'Pancreas', 'ALLOCATED', TIMESTAMP '2026-05-07 06:30:00', 'Islet cell preservation protocol engaged'),
    (9, 25, 'Cornea', 'ALLOCATED', TIMESTAMP '2026-03-07 05:20:00', 'Tissue bank sterility packet closed'),
    (10, 26, 'Skin', 'ALLOCATED', TIMESTAMP '2026-04-08 04:50:00', 'Burn center mesh staging approved'),
    (11, 2, 'Lung', 'ALLOCATED', TIMESTAMP '2026-04-26 07:15:00', 'LAS documentation snapshot uploaded'),
    (12, 25, 'Liver', 'ALLOCATED', TIMESTAMP '2026-03-07 05:18:00', 'Auxiliary graft consideration documented'),
    (13, 26, 'Kidney', 'ALLOCATED', TIMESTAMP '2026-04-08 04:42:00', 'ECD kidney acceptable per policy addendum'),
    (14, 6, 'Heart', 'ALLOCATED', TIMESTAMP '2026-05-07 06:22:00', 'Second heart on file for study arm control');

INSERT INTO match_candidate (
    match_id, request_id, match_type, blood_unit_id, organ_offer_id,
    compatibility_score, priority_level, match_status, match_date
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'BLOOD', 1, NULL, 0.941, 'HIGH', 'PROPOSED', TIMESTAMP '2026-05-08 07:55:00'),
    (2, 3, 'ORGAN', NULL, 1, 0.872, 'HIGH', 'ACCEPTED', TIMESTAMP '2026-04-27 08:15:00'),
    (3, 4, 'BLOOD', 3, NULL, 0.915, 'HIGH', 'PROPOSED', TIMESTAMP '2026-05-08 06:20:09'),
    (4, 5, 'BLOOD', 4, NULL, 0.903, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-04-06 07:30:52'),
    (5, 6, 'ORGAN', NULL, 2, 0.851, 'HIGH', 'ACCEPTED', TIMESTAMP '2026-05-07 06:52:43'),
    (6, 7, 'BLOOD', 5, NULL, 0.910, 'HIGH', 'PROPOSED', TIMESTAMP '2026-02-16 07:12:00'),
    (7, 2, 'BLOOD', 12, NULL, 0.889, 'LOW', 'FULFILLED', TIMESTAMP '2026-04-18 14:00:00'),
    (8, 9, 'BLOOD', 7, NULL, 0.901, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-03-06 08:00:00'),
    (9, 10, 'BLOOD', 8, NULL, 0.887, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-04-09 08:00:00'),
    (10, 11, 'BLOOD', 9, NULL, 0.877, 'LOW', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (11, 12, 'BLOOD', 10, NULL, 0.898, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (12, 14, 'BLOOD', 12, NULL, 0.865, 'LOW', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (13, 15, 'BLOOD', 22, NULL, 0.912, 'LOW', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (14, 18, 'BLOOD', 11, NULL, 0.890, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (15, 20, 'BLOOD', 12, NULL, 0.882, 'MEDIUM', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (16, 22, 'BLOOD', 18, NULL, 0.901, 'HIGH', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (17, 24, 'BLOOD', 8, NULL, 0.871, 'LOW', 'FULFILLED', TIMESTAMP '2026-06-07 06:53:53'),
    (18, 26, 'BLOOD', 9, NULL, 0.868, 'LOW', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (19, 28, 'BLOOD', 6, NULL, 0.874, 'LOW', 'PROPOSED', TIMESTAMP '2026-06-07 06:53:53'),
    (20, 8, 'ORGAN', NULL, 3, 0.861, 'HIGH', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (21, 13, 'ORGAN', NULL, 5, 0.848, 'HIGH', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (22, 16, 'ORGAN', NULL, 4, 0.829, 'MEDIUM', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (23, 17, 'ORGAN', NULL, 7, 0.817, 'LOW', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (24, 19, 'ORGAN', NULL, 8, 0.836, 'MEDIUM', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (25, 21, 'ORGAN', NULL, 6, 0.844, 'LOW', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (26, 23, 'ORGAN', NULL, 12, 0.852, 'MEDIUM', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (27, 25, 'ORGAN', NULL, 9, 0.820, 'HIGH', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (28, 27, 'ORGAN', NULL, 13, 0.833, 'MEDIUM', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53'),
    (29, 29, 'ORGAN', NULL, 10, 0.839, 'MEDIUM', 'ACCEPTED', TIMESTAMP '2026-06-07 06:53:53');

INSERT INTO transplant (transplant_id, match_id, transplant_date, surgeon_name, outcome)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 2, TIMESTAMP '2026-04-28 05:50:00', 'Dr. Nguyen', 'Kidney recipient stable POD3; graft function within target.'),
    (2, 5, TIMESTAMP '2026-05-08 06:40:58', 'Dr. Okonkwo–Patel', 'Immediate bile output; ammonia trending down POD1.'),
    (3, 20, TIMESTAMP '2026-01-18 06:12:41', 'Dr. Martins', 'Cardiac output index normalized OFF ECMO POD4.'),
    (4, 21, TIMESTAMP '2026-07-09 04:50:12', 'Dr. Lee–Sato', 'Simultaneous kidney–pancreas insulin independence day 5.'),
    (5, 22, TIMESTAMP '2026-01-02 05:11:22', 'Dr. Ashford', 'Bilateral lung gas exchange improved; vent wean started.'),
    (6, 23, TIMESTAMP '2026-06-11 08:22:33', 'Dr. Farley', 'Multivisceral graft perfusion robust; stoma output present.'),
    (7, 24, TIMESTAMP '2026-06-14 09:33:44', 'Dr. Ito', 'Islet adjunct C-peptide detectable; insulin reduced 40%.'),
    (8, 25, TIMESTAMP '2026-06-16 10:44:55', 'Dr. Romero', 'Redo kidney creatinine nadir 1.3 by POD7.'),
    (9, 26, TIMESTAMP '2026-06-18 11:55:06', 'Dr. Petrosian', 'Auxiliary liver segment hypertrophy trending as planned.'),
    (10, 27, TIMESTAMP '2026-06-20 07:06:07', 'Dr. Hale', 'Corneal clarity grade 1+; vision chart improved line +2.'),
    (11, 28, TIMESTAMP '2026-06-22 08:17:08', 'Dr. Nkrumah', 'ECD kidney delayed graft function resolving dipyridamole MIBI.'),
    (12, 29, TIMESTAMP '2026-06-24 09:28:09', 'Dr. Reyes', 'Bioengineered skin take 92% at POD10.');

INSERT INTO sql_template (template_id, intent_code, sql_text, allowed_params, active_flag)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'INV_BLOOD_STOCK', 'SELECT blood_group, unit_status, COUNT(*) AS unit_count FROM blood_unit bu JOIN blood_donation bd ON bd.blood_donation_id = bu.blood_donation_id JOIN donor d ON d.donor_id = bd.donor_id WHERE d.hospital_id = :hospital_id AND bu.blood_group = :blood_group AND bu.unit_status = ''AVAILABLE'' GROUP BY blood_group, unit_status', 'hospital_id:int,blood_group:text', TRUE),
    (2, 'INV_REQUEST_OPEN', 'SELECT request_id, urgency_level, status FROM request WHERE hospital_id = :hospital_id AND status IN (''OPEN'',''MATCHED'') ORDER BY urgency_level DESC', 'hospital_id:int', TRUE),
    (3, 'STATS_MATCH_BACKLOG', 'SELECT match_status, COUNT(*) FROM match_candidate GROUP BY match_status ORDER BY COUNT(*) DESC', '', TRUE),
    (4, 'STATS_ORGAN_PIPELINE', 'SELECT organ_type, availability_status, COUNT(*) FROM organ_offer GROUP BY organ_type, availability_status', '', TRUE),
    (5, 'LOOKUP_TRANSPLANT_WEEKLY', 'SELECT t.transplant_id, t.surgeon_name, mc.match_type FROM transplant t JOIN match_candidate mc ON mc.match_id = t.match_id ORDER BY t.transplant_date DESC LIMIT :limit_rows', 'limit_rows:int', TRUE),
    (6, 'LOOKUP_CHAT_SESSION_DAY', 'SELECT chat_session_id, user_role FROM chat_session WHERE started_at >= :started_after', 'started_after:timestamp', TRUE),
    (7, 'AUDIT_INTENT_FREQUENCY', 'SELECT st.intent_code, COUNT(*) FROM intent_detection idet JOIN sql_template st ON st.template_id = idet.template_id GROUP BY st.intent_code', '', TRUE),
    (8, 'RPT_DONOR_DEFERRAL_LIST', 'SELECT donor_id, full_name, eligibility_status FROM donor WHERE eligibility_status ILIKE ''%defer%'' OR availability_status ILIKE ''%unavail%''', '', TRUE),
    (9, 'RPT_EXPIRING_UNITS', 'SELECT blood_unit_id, expiry_date FROM blood_unit WHERE expiry_date <= CURRENT_DATE + 14', '', TRUE),
    (10, 'RPT_INVENTORY_TOUCH_LOG', 'SELECT hospital_id, blood_group, last_updated FROM blood_inventory_location ORDER BY last_updated DESC', '', TRUE),
    (11, 'RPT_MULTI_ORGAN_RECALL', 'SELECT donor_id, organ_type FROM organ_offer WHERE donor_id IN (SELECT donor_id FROM organ_offer GROUP BY donor_id HAVING COUNT(*) > 1)', '', TRUE),
    (12, 'RPT_CHAT_EXEC_JOIN', 'SELECT qel.execution_id, qel.execution_status, cm.sender_type FROM query_execution_log qel JOIN intent_detection idet ON idet.intent_id = qel.intent_id JOIN chat_message cm ON cm.message_id = idet.message_id', '', TRUE);

INSERT INTO chat_session (chat_session_id, hospital_id, user_role, started_at)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'TRANSPLANT_COORDINATOR', TIMESTAMP '2026-05-08 08:02:00'),
    (2, 2, 'BEDFLOW_ANALYST', TIMESTAMP '2026-04-06 07:12:00'),
    (3, 3, 'BLOOD_BANK_LEAD', TIMESTAMP '2026-05-09 06:06:06'),
    (4, 4, 'NIGHT_HOSPITALIST', TIMESTAMP '2026-05-10 22:22:22'),
    (5, 5, 'TRAUMA_PROGRAM_MANAGER', TIMESTAMP '2026-05-11 05:55:55'),
    (6, 6, 'PEDI_HEMONC_FELLOW', TIMESTAMP '2026-05-12 06:06:06'),
    (7, 7, 'VA_PHARMACIST', TIMESTAMP '2026-05-13 07:07:07'),
    (8, 8, 'OCC_MED_NAVIGATOR', TIMESTAMP '2026-05-14 08:08:08'),
    (9, 9, 'DIALYSIS_CHARGE_NURSE', TIMESTAMP '2026-05-15 09:09:09'),
    (10, 10, 'QUALITY_COORDINATOR', TIMESTAMP '2026-05-16 10:10:10'),
    (11, 11, 'FROST_RESUS_LEAD', TIMESTAMP '2026-05-17 11:11:11'),
    (12, 12, 'SHARED_SERV_DISPATCH', TIMESTAMP '2026-05-18 12:12:12');

INSERT INTO chat_message (message_id, chat_session_id, sender_type, message_text, created_at)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 'USER', 'How many available O+ units can we draw from donors registered at City General right now?', TIMESTAMP '2026-05-08 08:03:12'),
    (2, 2, 'USER', 'Show me every open blood or matched organ request waiting at Regional Transplant Center sorted by urgency.', TIMESTAMP '2026-04-06 07:12:18'),
    (3, 1, 'USER', 'Flag any MTP-class blood runs from the last twelve hours tied to ICU holds.', TIMESTAMP '2026-05-08 08:12:52'),
    (4, 3, 'USER', 'Summarize match_candidate rows by status for triage briefing.', TIMESTAMP '2026-05-09 06:07:12'),
    (5, 4, 'USER', 'List organ_offer pipeline totals by availability_status.', TIMESTAMP '2026-05-10 22:23:00'),
    (6, 5, 'USER', 'Pull last five transplants with surgeon names for M&M prep.', TIMESTAMP '2026-05-11 05:56:00'),
    (7, 6, 'USER', 'Which chat sessions started after March 1 for pediatrics analytics?', TIMESTAMP '2026-05-12 06:07:00'),
    (8, 7, 'USER', 'Intent audit: count detections grouped by intent_code.', TIMESTAMP '2026-05-13 07:08:00'),
    (9, 8, 'USER', 'Who is currently deferred or unavailable as whole-blood donors?', TIMESTAMP '2026-05-14 08:09:00'),
    (10, 9, 'USER', 'Which blood units expire within two weeks?', TIMESTAMP '2026-05-15 09:10:00'),
    (11, 10, 'USER', 'Show blood_inventory_location rows ordered by last_updated.', TIMESTAMP '2026-05-16 10:11:00'),
    (12, 11, 'USER', 'Which donors appear on more than one organ_offer row?', TIMESTAMP '2026-05-17 11:12:00'),
    (13, 12, 'USER', 'Join chat messages to execution logs for compliance.', TIMESTAMP '2026-05-18 12:13:00'),
    (14, 1, 'USER', 'Template smoke test message alpha.', TIMESTAMP '2026-05-08 08:20:00'),
    (15, 2, 'USER', 'Template smoke test message beta.', TIMESTAMP '2026-04-06 07:18:00');

INSERT INTO intent_detection (intent_id, message_id, template_id, confidence_score, detected_at)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 1, 0.937, TIMESTAMP '2026-05-08 08:03:13'),
    (2, 2, 2, 0.911, TIMESTAMP '2026-04-06 07:12:21'),
    (3, 3, 1, 0.883, TIMESTAMP '2026-05-08 08:12:55'),
    (4, 4, 3, 0.901, TIMESTAMP '2026-05-09 06:07:13'),
    (5, 5, 4, 0.889, TIMESTAMP '2026-05-10 22:23:01'),
    (6, 6, 5, 0.904, TIMESTAMP '2026-05-11 05:56:01'),
    (7, 7, 6, 0.877, TIMESTAMP '2026-05-12 06:07:01'),
    (8, 8, 7, 0.893, TIMESTAMP '2026-05-13 07:08:01'),
    (9, 9, 8, 0.868, TIMESTAMP '2026-05-14 08:09:01'),
    (10, 10, 9, 0.882, TIMESTAMP '2026-05-15 09:10:01'),
    (11, 11, 10, 0.895, TIMESTAMP '2026-05-16 10:11:01'),
    (12, 12, 11, 0.871, TIMESTAMP '2026-05-17 11:12:01'),
    (13, 13, 12, 0.888, TIMESTAMP '2026-05-18 12:13:01'),
    (14, 14, 3, 0.901, TIMESTAMP '2026-05-08 08:20:01'),
    (15, 15, 4, 0.899, TIMESTAMP '2026-04-06 07:18:01');

INSERT INTO query_execution_log (
    execution_id, intent_id, param_json, execution_status, rows_returned, executed_at,
    request_id, match_id, inventory_id
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, '{"hospital_id":1,"blood_group":"O+"}', 'SUCCESS', 1, TIMESTAMP '2026-05-08 08:03:14', NULL, 1, 1),
    (2, 2, '{"hospital_id":2}', 'SUCCESS', 3, TIMESTAMP '2026-04-06 07:12:22', 5, 4, NULL),
    (3, 3, '{"hospital_id":1,"blood_group":"A-"}', 'SUCCESS', 1, TIMESTAMP '2026-05-08 08:12:56', 4, 3, 4),
    (4, 4, '{}', 'SUCCESS', 3, TIMESTAMP '2026-05-09 06:07:14', NULL, 6, NULL),
    (5, 5, '{}', 'SUCCESS', 10, TIMESTAMP '2026-05-10 22:23:02', NULL, 20, NULL),
    (6, 6, '{"limit_rows":5}', 'SUCCESS', 5, TIMESTAMP '2026-05-11 05:56:02', NULL, 2, NULL),
    (7, 7, '{"started_after":"2026-03-01 00:00:00"}', 'SUCCESS', 12, TIMESTAMP '2026-05-12 06:07:02', NULL, NULL, NULL),
    (8, 8, '{}', 'SUCCESS', 12, TIMESTAMP '2026-05-13 07:08:02', NULL, NULL, NULL),
    (9, 9, '{}', 'SUCCESS', 2, TIMESTAMP '2026-05-14 08:09:02', NULL, NULL, NULL),
    (10, 10, '{}', 'SUCCESS', 10, TIMESTAMP '2026-05-15 09:10:02', NULL, NULL, NULL),
    (11, 11, '{}', 'SUCCESS', 16, TIMESTAMP '2026-05-16 10:11:02', NULL, NULL, 10),
    (12, 12, '{}', 'SUCCESS', 6, TIMESTAMP '2026-05-17 11:12:02', NULL, NULL, NULL),
    (13, 13, '{}', 'SUCCESS', 13, TIMESTAMP '2026-05-18 12:13:02', NULL, NULL, NULL),
    (14, 14, '{}', 'SUCCESS', 4, TIMESTAMP '2026-05-08 08:20:02', NULL, 8, NULL),
    (15, 15, '{}', 'SUCCESS', 14, TIMESTAMP '2026-04-06 07:18:02', 22, NULL, NULL);

-- Resync identity sequences after manual keys
SELECT setval(pg_get_serial_sequence('hospital', 'hospital_id'), (SELECT COALESCE(MAX(hospital_id), 1) FROM hospital));
SELECT setval(pg_get_serial_sequence('patient', 'patient_id'), (SELECT COALESCE(MAX(patient_id), 1) FROM patient));
SELECT setval(pg_get_serial_sequence('medical_record', 'record_id'), (SELECT COALESCE(MAX(record_id), 1) FROM medical_record));
SELECT setval(pg_get_serial_sequence('donor', 'donor_id'), (SELECT COALESCE(MAX(donor_id), 1) FROM donor));
SELECT setval(pg_get_serial_sequence('request', 'request_id'), (SELECT COALESCE(MAX(request_id), 1) FROM request));
SELECT setval(pg_get_serial_sequence('blood_donation', 'blood_donation_id'), (SELECT COALESCE(MAX(blood_donation_id), 1) FROM blood_donation));
SELECT setval(pg_get_serial_sequence('blood_unit', 'blood_unit_id'), (SELECT COALESCE(MAX(blood_unit_id), 1) FROM blood_unit));
SELECT setval(pg_get_serial_sequence('blood_inventory_location', 'inventory_id'), (SELECT COALESCE(MAX(inventory_id), 1) FROM blood_inventory_location));
SELECT setval(pg_get_serial_sequence('organ_offer', 'organ_offer_id'), (SELECT COALESCE(MAX(organ_offer_id), 1) FROM organ_offer));
SELECT setval(pg_get_serial_sequence('match_candidate', 'match_id'), (SELECT COALESCE(MAX(match_id), 1) FROM match_candidate));
SELECT setval(pg_get_serial_sequence('transplant', 'transplant_id'), (SELECT COALESCE(MAX(transplant_id), 1) FROM transplant));
SELECT setval(pg_get_serial_sequence('chat_session', 'chat_session_id'), (SELECT COALESCE(MAX(chat_session_id), 1) FROM chat_session));
SELECT setval(pg_get_serial_sequence('sql_template', 'template_id'), (SELECT COALESCE(MAX(template_id), 1) FROM sql_template));
SELECT setval(pg_get_serial_sequence('chat_message', 'message_id'), (SELECT COALESCE(MAX(message_id), 1) FROM chat_message));
SELECT setval(pg_get_serial_sequence('intent_detection', 'intent_id'), (SELECT COALESCE(MAX(intent_id), 1) FROM intent_detection));
SELECT setval(pg_get_serial_sequence('query_execution_log', 'execution_id'), (SELECT COALESCE(MAX(execution_id), 1) FROM query_execution_log));

COMMIT;