-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 1: Database Design
-- Case study: Hospital / Clinic System (Lagos Community Clinic - simulated)
-- DBMS: PostgreSQL 15+
-- Author: Destiny Osazuwa (301908420)
-- =====================================================================

DROP SCHEMA IF EXISTS clinic CASCADE;
CREATE SCHEMA clinic;
SET search_path TO clinic;

-- ---------------------------------------------------------------------
-- Reference table: hospital departments
-- ---------------------------------------------------------------------
CREATE TABLE department (
    department_id   SERIAL PRIMARY KEY,
    name            VARCHAR(80)  NOT NULL UNIQUE,
    location        VARCHAR(80)
);

-- ---------------------------------------------------------------------
-- Doctors (each belongs to one department)
-- ---------------------------------------------------------------------
CREATE TABLE doctor (
    doctor_id       SERIAL PRIMARY KEY,
    department_id   INT          NOT NULL REFERENCES department(department_id)
                                 ON UPDATE CASCADE ON DELETE RESTRICT,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    specialty       VARCHAR(80)  NOT NULL,
    licence_no      VARCHAR(30)  NOT NULL UNIQUE,
    email           VARCHAR(120) UNIQUE,
    phone           VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- Patients
-- ---------------------------------------------------------------------
CREATE TABLE patient (
    patient_id      SERIAL PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    date_of_birth   DATE         NOT NULL CHECK (date_of_birth <= CURRENT_DATE),
    gender          CHAR(1)      NOT NULL CHECK (gender IN ('M','F','O')),
    phone           VARCHAR(20),
    email           VARCHAR(120) UNIQUE,
    address         VARCHAR(200),
    registered_on   DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------
-- Appointments: a patient sees a doctor at a given time.
-- UNIQUE (doctor_id, appointment_time) prevents double-booking a slot
-- (reused in Portfolio 3 for the concurrency demonstration).
-- ---------------------------------------------------------------------
CREATE TABLE appointment (
    appointment_id   SERIAL PRIMARY KEY,
    patient_id       INT          NOT NULL REFERENCES patient(patient_id)
                                  ON UPDATE CASCADE ON DELETE RESTRICT,
    doctor_id        INT          NOT NULL REFERENCES doctor(doctor_id)
                                  ON UPDATE CASCADE ON DELETE RESTRICT,
    appointment_time TIMESTAMP    NOT NULL,
    status           VARCHAR(15)  NOT NULL DEFAULT 'SCHEDULED'
                     CHECK (status IN ('SCHEDULED','COMPLETED','CANCELLED','NO_SHOW')),
    reason           VARCHAR(200),
    CONSTRAINT uq_doctor_slot UNIQUE (doctor_id, appointment_time)
);

-- ---------------------------------------------------------------------
-- Diagnosis recorded during an appointment
-- ---------------------------------------------------------------------
CREATE TABLE diagnosis (
    diagnosis_id     SERIAL PRIMARY KEY,
    appointment_id   INT          NOT NULL REFERENCES appointment(appointment_id)
                                  ON DELETE CASCADE,
    icd_code         VARCHAR(10)  NOT NULL,
    description      VARCHAR(200) NOT NULL,
    notes            TEXT
);

-- ---------------------------------------------------------------------
-- Medication catalogue
-- ---------------------------------------------------------------------
CREATE TABLE medication (
    medication_id    SERIAL PRIMARY KEY,
    name             VARCHAR(100) NOT NULL UNIQUE,
    form             VARCHAR(30)  NOT NULL,          -- tablet, syrup, injection...
    unit_price       NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- ---------------------------------------------------------------------
-- Prescription header + line items (resolves many-to-many between
-- appointment and medication)
-- ---------------------------------------------------------------------
CREATE TABLE prescription (
    prescription_id  SERIAL PRIMARY KEY,
    appointment_id   INT          NOT NULL REFERENCES appointment(appointment_id)
                                  ON DELETE CASCADE,
    issued_on        DATE         NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE prescription_item (
    prescription_id  INT          NOT NULL REFERENCES prescription(prescription_id)
                                  ON DELETE CASCADE,
    medication_id    INT          NOT NULL REFERENCES medication(medication_id)
                                  ON DELETE RESTRICT,
    dosage           VARCHAR(60)  NOT NULL,
    duration_days    INT          NOT NULL CHECK (duration_days > 0),
    quantity         INT          NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (prescription_id, medication_id)      -- composite key
);

-- ---------------------------------------------------------------------
-- Laboratory tests and results
-- ---------------------------------------------------------------------
CREATE TABLE lab_test_type (
    test_type_id     SERIAL PRIMARY KEY,
    name             VARCHAR(100) NOT NULL UNIQUE,
    normal_range     VARCHAR(60),
    unit             VARCHAR(20)
);

CREATE TABLE lab_result (
    lab_result_id    SERIAL PRIMARY KEY,
    appointment_id   INT          NOT NULL REFERENCES appointment(appointment_id)
                                  ON DELETE CASCADE,
    test_type_id     INT          NOT NULL REFERENCES lab_test_type(test_type_id)
                                  ON DELETE RESTRICT,
    result_value     VARCHAR(60)  NOT NULL,
    tested_on        DATE         NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------
-- Helpful foreign-key indexes (PostgreSQL does not create these
-- automatically). Further indexing strategy is covered in Portfolio 2.
-- ---------------------------------------------------------------------
CREATE INDEX idx_doctor_department   ON doctor(department_id);
CREATE INDEX idx_appt_patient        ON appointment(patient_id);
CREATE INDEX idx_diag_appt           ON diagnosis(appointment_id);
CREATE INDEX idx_presc_appt          ON prescription(appointment_id);
CREATE INDEX idx_lab_appt            ON lab_result(appointment_id);
