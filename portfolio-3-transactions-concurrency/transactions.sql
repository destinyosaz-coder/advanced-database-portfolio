-- =====================================================================
-- MIT 8103 - Portfolio 3: Transactions and Concurrency
-- Case study: Lagos Community Clinic. Run AFTER Portfolio 1 + 2 seed.
-- Run ONE numbered block at a time (select the block, press F5).
-- Exercises D and E need TWO Query Tool tabs (two separate sessions).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. CLEAN-UP (run first, and any time you want to repeat an exercise)
-- ---------------------------------------------------------------------
DELETE FROM clinic.appointment WHERE appointment_time >= '2030-01-01';
DELETE FROM clinic.patient WHERE first_name = 'Atomic';
UPDATE clinic.appointment SET status = 'SCHEDULED' WHERE appointment_id = 1;

-- =====================================================================
-- EXERCISE A: COMMIT (rescheduling an appointment as ONE unit of work)
-- Cancel the old booking and create the new one. Both happen or neither.
-- =====================================================================
-- A1. Run these four statements together
BEGIN;
UPDATE clinic.appointment SET status = 'CANCELLED' WHERE appointment_id = 1;
INSERT INTO clinic.appointment (patient_id, doctor_id, appointment_time, status, reason)
SELECT patient_id, doctor_id, '2030-01-10 09:00', 'SCHEDULED', 'Rescheduled visit'
FROM clinic.appointment WHERE appointment_id = 1;
COMMIT;

-- A2. Show the result (screenshot this)
SELECT appointment_id, patient_id, doctor_id, appointment_time, status
FROM clinic.appointment
WHERE appointment_id = 1 OR appointment_time = '2030-01-10 09:00';

-- =====================================================================
-- EXERCISE B: ROLLBACK (undoing a mistake)
-- A wrong update raises every medication price by 10x. We spot it and undo.
-- =====================================================================
-- B1. Show the price before
SELECT medication_id, name, unit_price FROM clinic.medication WHERE medication_id = 1;

-- B2. Run these two together (the price inside the transaction is 10x)
BEGIN;
UPDATE clinic.medication SET unit_price = unit_price * 10 WHERE medication_id = 1;
SELECT medication_id, name, unit_price FROM clinic.medication WHERE medication_id = 1;

-- B3. Undo it
ROLLBACK;

-- B4. Show the price after rollback: same as B1 (screenshot B1, B2, B4)
SELECT medication_id, name, unit_price FROM clinic.medication WHERE medication_id = 1;

-- =====================================================================
-- EXERCISE C: ATOMICITY (one failing statement cancels the whole unit)
-- =====================================================================
-- C1. Run these two together. The first is valid, the second breaks a CHECK.
BEGIN;
INSERT INTO clinic.patient (first_name, last_name, date_of_birth, gender) VALUES ('Atomic', 'Valid', '1990-05-05', 'F');
INSERT INTO clinic.patient (first_name, last_name, date_of_birth, gender) VALUES ('Atomic', 'Invalid', '1990-05-05', 'X');
-- ERROR appears on the second insert. PostgreSQL marks the transaction as failed.

-- C2. Cancel the failed transaction
ROLLBACK;

-- C3. Count 'Atomic' patients. Expect 0: even the valid insert was undone.
SELECT count(*) AS atomic_patients FROM clinic.patient WHERE first_name = 'Atomic';

-- =====================================================================
-- EXERCISE D: CONCURRENCY CONTROL - two receptionists book the SAME slot
-- Needs TWO Query Tool tabs: call them SESSION 1 and SESSION 2.
-- The UNIQUE (doctor_id, appointment_time) constraint is the control.
-- =====================================================================
-- D1. SESSION 1: start a booking (do NOT commit yet)
BEGIN;
INSERT INTO clinic.appointment (patient_id, doctor_id, appointment_time, reason)
VALUES (10, 2, '2030-02-01 10:00', 'Session 1 booking');

-- D2. SESSION 2: try to book the same doctor and time.
--     It will WAIT (spinning, no result). Screenshot the waiting state.
INSERT INTO clinic.appointment (patient_id, doctor_id, appointment_time, reason)
VALUES (20, 2, '2030-02-01 10:00', 'Session 2 booking');

-- D3. SESSION 1: now commit
COMMIT;

-- D4. SESSION 2 now fails with: duplicate key value violates unique
--     constraint "uq_doctor_slot". Screenshot the error.
-- D5. Either session: confirm only ONE booking exists
SELECT appointment_id, patient_id, reason FROM clinic.appointment
WHERE doctor_id = 2 AND appointment_time = '2030-02-01 10:00';

-- =====================================================================
-- EXERCISE E: ISOLATION LEVELS (non-repeatable read)
-- Again TWO tabs. Price of medication 1 is read twice in one transaction
-- while another session changes it in between.
-- =====================================================================
-- E-PART 1: READ COMMITTED (PostgreSQL default)  -> the price CHANGES
-- E1. SESSION 1:
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT unit_price FROM clinic.medication WHERE medication_id = 1;   -- first read
-- E2. SESSION 2 (runs and commits immediately):
UPDATE clinic.medication SET unit_price = unit_price + 1 WHERE medication_id = 1;
-- E3. SESSION 1: read again
SELECT unit_price FROM clinic.medication WHERE medication_id = 1;   -- different!
COMMIT;

-- E-PART 2: REPEATABLE READ  -> the price STAYS THE SAME
-- E4. SESSION 1:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT unit_price FROM clinic.medication WHERE medication_id = 1;   -- first read
-- E5. SESSION 2:
UPDATE clinic.medication SET unit_price = unit_price + 1 WHERE medication_id = 1;
-- E6. SESSION 1: read again
SELECT unit_price FROM clinic.medication WHERE medication_id = 1;   -- same as E4
COMMIT;
-- E7. SESSION 1 after commit: the new price is now visible
SELECT unit_price FROM clinic.medication WHERE medication_id = 1;

-- E8. RESTORE the price (important): remove the two +1 increments
UPDATE clinic.medication SET unit_price = unit_price - 2 WHERE medication_id = 1;
