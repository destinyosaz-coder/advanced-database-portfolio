-- =====================================================================
-- MIT 8103 - Portfolio 2: optimisation.sql
-- Method: run each EXPLAIN ANALYZE BEFORE indexing, create the index,
--         then run the same EXPLAIN ANALYZE AFTER. Screenshot both.
-- Run the numbered blocks one at a time (highlight, then F5).
-- =====================================================================
SET search_path TO clinic;

-- ---------------------------------------------------------------------
-- EXPERIMENT 1: Q1 (cancelled appointments in a date range)
-- ---------------------------------------------------------------------
-- 1A. BEFORE
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_id, patient_id, doctor_id, appointment_time
FROM appointment
WHERE status = 'CANCELLED'
  AND appointment_time >= '2024-06-01' AND appointment_time < '2024-07-01';

-- 1B. Create a composite index (equality column first, range column second)
CREATE INDEX idx_appt_status_time ON appointment (status, appointment_time);
ANALYZE appointment;

-- 1C. AFTER
EXPLAIN (ANALYZE, BUFFERS)
SELECT appointment_id, patient_id, doctor_id, appointment_time
FROM appointment
WHERE status = 'CANCELLED'
  AND appointment_time >= '2024-06-01' AND appointment_time < '2024-07-01';

-- ---------------------------------------------------------------------
-- EXPERIMENT 2: Q2 (patient search by last name)
-- ---------------------------------------------------------------------
-- 2A. BEFORE
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, first_name, last_name, phone FROM patient WHERE last_name = 'Okafor';

-- 2B. Create index
CREATE INDEX idx_patient_last_name ON patient (last_name);
ANALYZE patient;

-- 2C. AFTER
EXPLAIN (ANALYZE, BUFFERS)
SELECT patient_id, first_name, last_name, phone FROM patient WHERE last_name = 'Okafor';

-- ---------------------------------------------------------------------
-- EXPERIMENT 3: Q6 (one patient's full history) - uses the FK index
-- created in Portfolio 1. Compare with and without it.
-- ---------------------------------------------------------------------
-- 3A. WITH the foreign-key index (idx_appt_patient)
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.appointment_time, a.status FROM appointment a WHERE a.patient_id = 1234;

-- 3B. Temporarily remove it to see the cost
DROP INDEX idx_appt_patient;
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.appointment_time, a.status FROM appointment a WHERE a.patient_id = 1234;

-- 3C. Restore it (important: Portfolio 3 relies on the schema being intact)
CREATE INDEX idx_appt_patient ON appointment (patient_id);
ANALYZE appointment;

-- ---------------------------------------------------------------------
-- EXPERIMENT 4: Q4 (top medications): an aggregate over the whole table.
-- Expectation: an index will NOT help, because every row is needed.
-- ---------------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.name, count(*) AS times_prescribed
FROM prescription_item pi JOIN medication m ON m.medication_id = pi.medication_id
GROUP BY m.name ORDER BY times_prescribed DESC LIMIT 10;

CREATE INDEX idx_pi_medication ON prescription_item (medication_id);
ANALYZE prescription_item;

EXPLAIN (ANALYZE, BUFFERS)
SELECT m.name, count(*) AS times_prescribed
FROM prescription_item pi JOIN medication m ON m.medication_id = pi.medication_id
GROUP BY m.name ORDER BY times_prescribed DESC LIMIT 10;
