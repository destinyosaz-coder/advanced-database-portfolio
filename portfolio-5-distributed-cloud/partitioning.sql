-- =====================================================================
-- MIT 8103 - Portfolio 5, Part A: Partitioning (PostgreSQL)
-- Idea: split the big appointment table into smaller pieces by date.
-- A query for one month then reads only the matching piece
-- ("partition pruning"). This is the same principle as sharding,
-- but inside one server.
-- Run the numbered blocks one at a time.
-- =====================================================================

-- A1. Create the partitioned table (the "parent")
DROP TABLE IF EXISTS clinic.appointment_part CASCADE;
CREATE TABLE clinic.appointment_part (
    appointment_id   INT          NOT NULL,
    patient_id       INT          NOT NULL REFERENCES clinic.patient(patient_id),
    doctor_id        INT          NOT NULL REFERENCES clinic.doctor(doctor_id),
    appointment_time TIMESTAMP    NOT NULL,
    status           VARCHAR(15)  NOT NULL DEFAULT 'SCHEDULED',
    reason           VARCHAR(200),
    PRIMARY KEY (appointment_id, appointment_time)
) PARTITION BY RANGE (appointment_time);

-- A2. Create one partition per quarter, plus a catch-all
CREATE TABLE clinic.appt_2024_q1 PARTITION OF clinic.appointment_part FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE clinic.appt_2024_q2 PARTITION OF clinic.appointment_part FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');
CREATE TABLE clinic.appt_2024_q3 PARTITION OF clinic.appointment_part FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');
CREATE TABLE clinic.appt_2024_q4 PARTITION OF clinic.appointment_part FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');
CREATE TABLE clinic.appt_other   PARTITION OF clinic.appointment_part DEFAULT;

-- A3. Copy the existing data in. PostgreSQL routes each row automatically.
INSERT INTO clinic.appointment_part (appointment_id, patient_id, doctor_id, appointment_time, status, reason)
SELECT appointment_id, patient_id, doctor_id, appointment_time, status, reason FROM clinic.appointment;
ANALYZE clinic.appointment_part;

-- A4. Show how many rows landed in each partition (screenshot this)
SELECT tableoid::regclass AS partition_name, count(*) AS row_count
FROM clinic.appointment_part GROUP BY 1 ORDER BY 1;

-- A5. PRUNING TEST on the partitioned table (screenshot: only ONE partition is scanned)
EXPLAIN (ANALYZE) SELECT count(*) FROM clinic.appointment_part
WHERE appointment_time >= '2024-05-01' AND appointment_time < '2024-06-01';

-- A6. Same question on the ordinary table, for comparison (screenshot)
EXPLAIN (ANALYZE) SELECT count(*) FROM clinic.appointment
WHERE appointment_time >= '2024-05-01' AND appointment_time < '2024-06-01';
