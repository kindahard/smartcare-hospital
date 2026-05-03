-- ============================================================
--  SmartCare — Hospital Management System
--  DDL Script  |  PostgreSQL 15+
--  Team 2  |  Helwan University  |  April 2026
-- ============================================================
--  Structure:
--    PHASE 0 — EXTENSIONS, ENUM TYPES, CUSTOM RANGE TYPE
--    PHASE 1 — CREATE TABLES     (columns + PK only)
--    PHASE 2 — ADD CONSTRAINTS   (UNIQUE, CHECK, FK, EXCLUDE + indexes)
--    PHASE 3 — CREATE TRIGGERS
-- ============================================================


-- ============================================================
--  PHASE 0 — EXTENSIONS, ENUM TYPES, CUSTOM RANGE TYPE
-- ============================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Enum types
CREATE TYPE role_enum        AS ENUM ('Admin', 'Doctor', 'Patient');
CREATE TYPE appt_status_enum AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');
CREATE TYPE notif_type_enum  AS ENUM ('appointment', 'prescription', 'billing', 'system_error');
CREATE TYPE channel_enum     AS ENUM ('email', 'in_app');
CREATE TYPE inv_status_enum  AS ENUM ('pending', 'paid', 'refunded');
CREATE TYPE pay_method_enum  AS ENUM ('card', 'digital_wallet');
CREATE TYPE report_type_enum AS ENUM ('doctor_performance', 'appointment_trends', 'billing_summary');
CREATE TYPE export_fmt_enum  AS ENUM ('PDF', 'Excel');

-- Custom range type for TIME overlap checks in clinic_reservation
CREATE TYPE timerange AS RANGE (subtype = time);


-- ============================================================
--  PHASE 1 — CREATE TABLES
-- ============================================================

-- ------------------------------------------------------------
--  1.1  app_user  (renamed from 'user' — reserved word in PG)
-- ------------------------------------------------------------
CREATE TABLE app_user (
    user_id       INT            NOT NULL GENERATED ALWAYS AS IDENTITY,
    name          VARCHAR(100)   NOT NULL,
    email         VARCHAR(150)   NOT NULL,
    password_hash VARCHAR(255)   NOT NULL,
    role          role_enum      NOT NULL,
    is_active     BOOLEAN        NOT NULL DEFAULT true,
    created_at    TIMESTAMP      NOT NULL DEFAULT NOW(),
    phone_number  VARCHAR(20)        NULL,

    CONSTRAINT pk_user PRIMARY KEY (user_id)
);

-- ------------------------------------------------------------
--  1.2  patient  (extends app_user — 1:1)
-- ------------------------------------------------------------
CREATE TABLE patient (
    patient_id    INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id       INT          NOT NULL,
    date_of_birth DATE         NOT NULL,
    gender        VARCHAR(10)  NOT NULL,
    address       TEXT             NULL,
    blood_type    VARCHAR(5)       NULL,

    CONSTRAINT pk_patient PRIMARY KEY (patient_id)
);

-- ------------------------------------------------------------
--  1.3  doctor  (extends app_user — 1:1)
-- ------------------------------------------------------------
CREATE TABLE doctor (
    doctor_id      INT           NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id        INT           NOT NULL,
    specialty      VARCHAR(100)  NOT NULL,
    license_number VARCHAR(50)   NOT NULL,

    CONSTRAINT pk_doctor PRIMARY KEY (doctor_id)
);

-- ------------------------------------------------------------
--  1.4  clinic
-- ------------------------------------------------------------
CREATE TABLE clinic (
    clinic_id INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    type      VARCHAR(100) NOT NULL,

    CONSTRAINT pk_clinic PRIMARY KEY (clinic_id)
);

-- ------------------------------------------------------------
--  1.5  clinic_reservation
--        doctor_id → app_user(user_id)  role must be Doctor
--        clinic_id → clinic(clinic_id)
-- ------------------------------------------------------------
CREATE TABLE clinic_reservation (
    reservation_id INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    clinic_id      INT          NOT NULL,
    doctor_id      INT          NOT NULL,
    day            DATE         NOT NULL,
    start_hour     TIME         NOT NULL,
    end_hour       TIME         NOT NULL,

    CONSTRAINT pk_clinic_reservation PRIMARY KEY (reservation_id)
);

-- ------------------------------------------------------------
--  1.6  appointment
--        patient_id → app_user(user_id)  role must be Patient
--        doctor_id  → app_user(user_id)  role must be Doctor
-- ------------------------------------------------------------
CREATE TABLE appointment (
    appointment_id INT              NOT NULL GENERATED ALWAYS AS IDENTITY,
    patient_id     INT              NOT NULL,
    doctor_id      INT              NOT NULL,
    date_time      TIMESTAMP        NOT NULL,
    status         appt_status_enum NOT NULL DEFAULT 'pending',
    notes          TEXT                 NULL,

    CONSTRAINT pk_appointment PRIMARY KEY (appointment_id)
);

-- ------------------------------------------------------------
--  1.7  medicalrecord
--        patient_id → app_user(user_id)  role must be Patient
--        doctor_id  → app_user(user_id)  role must be Doctor
-- ------------------------------------------------------------
CREATE TABLE medicalrecord (
    record_id             INT  NOT NULL GENERATED ALWAYS AS IDENTITY,
    patient_id            INT  NOT NULL,
    doctor_id             INT  NOT NULL,
    appointment_id        INT      NULL,
    visit_date            DATE NOT NULL,
    diagnosis             TEXT NOT NULL,
    notes                 TEXT     NULL,
    attached_document_url TEXT     NULL,

    CONSTRAINT pk_medicalrecord PRIMARY KEY (record_id)
);

-- ------------------------------------------------------------
--  1.8  prescription  (split from old single table)
-- ------------------------------------------------------------
CREATE TABLE prescription (
    prescription_id INT  NOT NULL GENERATED ALWAYS AS IDENTITY,
    record_id       INT  NOT NULL,
    issue_date      DATE NOT NULL,

    CONSTRAINT pk_prescription PRIMARY KEY (prescription_id)
);

-- ------------------------------------------------------------
--  1.9  drug
-- ------------------------------------------------------------
CREATE TABLE drug (
    drug_id   INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    drug_name VARCHAR(150) NOT NULL,

    CONSTRAINT pk_drug PRIMARY KEY (drug_id)
);

-- ------------------------------------------------------------
--  1.10  drug_details  (active ingredients per drug)
-- ------------------------------------------------------------
CREATE TABLE drug_details (
    ingredient_id      INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    drug_id            INT          NOT NULL,
    active_ingredient  VARCHAR(150) NOT NULL,

    CONSTRAINT pk_drug_details PRIMARY KEY (ingredient_id)
);

-- ------------------------------------------------------------
--  1.11  prescription_details  (one row per drug line in a prescription)
-- ------------------------------------------------------------
CREATE TABLE prescription_details (
    prescription_details_id INT         NOT NULL GENERATED ALWAYS AS IDENTITY,
    prescription_id         INT         NOT NULL,
    drug_id                 INT         NOT NULL,
    dosage                  VARCHAR(50) NOT NULL,
    frequency               VARCHAR(50) NOT NULL,
    duration                VARCHAR(50)     NULL,

    CONSTRAINT pk_prescription_details PRIMARY KEY (prescription_details_id)
);

-- ------------------------------------------------------------
--  1.12  invoice
-- ------------------------------------------------------------
CREATE TABLE invoice (
    invoice_id     INT             NOT NULL GENERATED ALWAYS AS IDENTITY,
    appointment_id INT             NOT NULL,
    issue_date     DATE            NOT NULL,
    total_amount   NUMERIC(10,2)   NOT NULL,
    status         inv_status_enum NOT NULL DEFAULT 'pending',

    CONSTRAINT pk_invoice PRIMARY KEY (invoice_id)
);

-- ------------------------------------------------------------
--  1.13  payment
-- ------------------------------------------------------------
CREATE TABLE payment (
    payment_id      INT             NOT NULL GENERATED ALWAYS AS IDENTITY,
    invoice_id      INT             NOT NULL,
    payment_date    DATE            NOT NULL,
    amount          NUMERIC(10,2)   NOT NULL,
    method          pay_method_enum NOT NULL,
    receipt_pdf_url TEXT                NULL,

    CONSTRAINT pk_payment PRIMARY KEY (payment_id)
);

-- ------------------------------------------------------------
--  1.14  notification
-- ------------------------------------------------------------
CREATE TABLE notification (
    notification_id INT             NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id         INT             NOT NULL,
    type            notif_type_enum NOT NULL,
    channel         channel_enum    NOT NULL,
    message         TEXT            NOT NULL,
    sent_at         TIMESTAMP       NOT NULL DEFAULT NOW(),
    is_read         BOOLEAN         NOT NULL DEFAULT false,

    CONSTRAINT pk_notification PRIMARY KEY (notification_id)
);

-- ------------------------------------------------------------
--  1.15  notificationpreference
-- ------------------------------------------------------------
CREATE TABLE notificationpreference (
    preference_id INT          NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id       INT          NOT NULL,
    channel       channel_enum NOT NULL,
    event_type    VARCHAR(50)  NOT NULL,
    is_enabled    BOOLEAN      NOT NULL DEFAULT true,

    CONSTRAINT pk_notifpref PRIMARY KEY (preference_id)
);

-- ------------------------------------------------------------
--  1.16  report
-- ------------------------------------------------------------
CREATE TABLE report (
    report_id      INT              NOT NULL GENERATED ALWAYS AS IDENTITY,
    admin_id       INT              NOT NULL,
    report_type    report_type_enum NOT NULL,
    generated_at   TIMESTAMP        NOT NULL DEFAULT NOW(),
    export_format  export_fmt_enum  NOT NULL,
    file_url       TEXT                 NULL,

    CONSTRAINT pk_report PRIMARY KEY (report_id)
);


-- ============================================================
--  PHASE 2 — ADD CONSTRAINTS & INDEXES
-- ============================================================

-- ------------------------------------------------------------
--  2.1  UNIQUE constraints
-- ------------------------------------------------------------

ALTER TABLE app_user
    ADD CONSTRAINT uq_user_email          UNIQUE (email);

ALTER TABLE patient
    ADD CONSTRAINT uq_patient_user        UNIQUE (user_id);

ALTER TABLE doctor
    ADD CONSTRAINT uq_doctor_user         UNIQUE (user_id),
    ADD CONSTRAINT uq_doctor_license      UNIQUE (license_number);

ALTER TABLE appointment
    ADD CONSTRAINT uq_doctor_timeslot     UNIQUE (doctor_id, date_time);

ALTER TABLE invoice
    ADD CONSTRAINT uq_invoice_appointment UNIQUE (appointment_id);

ALTER TABLE payment
    ADD CONSTRAINT uq_payment_invoice     UNIQUE (invoice_id);

ALTER TABLE notificationpreference
    ADD CONSTRAINT uq_notifpref           UNIQUE (user_id, channel, event_type);


-- ------------------------------------------------------------
--  2.2  CHECK constraints
-- ------------------------------------------------------------

ALTER TABLE clinic_reservation
    ADD CONSTRAINT chk_clinic_hours       CHECK (end_hour > start_hour);

ALTER TABLE invoice
    ADD CONSTRAINT chk_invoice_amount     CHECK (total_amount >= 0);

ALTER TABLE payment
    ADD CONSTRAINT chk_payment_amount     CHECK (amount > 0);


-- ------------------------------------------------------------
--  2.3  FOREIGN KEY constraints
-- ------------------------------------------------------------

-- patient profile → app_user
ALTER TABLE patient
    ADD CONSTRAINT fk_patient_user
        FOREIGN KEY (user_id) REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- doctor profile → app_user
ALTER TABLE doctor
    ADD CONSTRAINT fk_doctor_user
        FOREIGN KEY (user_id) REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- clinic_reservation → clinic + app_user(doctor)
ALTER TABLE clinic_reservation
    ADD CONSTRAINT fk_reservation_clinic
        FOREIGN KEY (clinic_id)  REFERENCES clinic(clinic_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_reservation_doctor
        FOREIGN KEY (doctor_id)  REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- appointment → app_user(patient) + app_user(doctor)
ALTER TABLE appointment
    ADD CONSTRAINT fk_appointment_patient
        FOREIGN KEY (patient_id) REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (doctor_id)  REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- medicalrecord → app_user(patient) + app_user(doctor) + appointment
ALTER TABLE medicalrecord
    ADD CONSTRAINT fk_mr_patient
        FOREIGN KEY (patient_id)     REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_mr_doctor
        FOREIGN KEY (doctor_id)      REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_mr_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id)
        ON DELETE SET NULL ON UPDATE CASCADE;

-- prescription → medicalrecord
ALTER TABLE prescription
    ADD CONSTRAINT fk_prescription_mr
        FOREIGN KEY (record_id) REFERENCES medicalrecord(record_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- drug_details → drug
ALTER TABLE drug_details
    ADD CONSTRAINT fk_drug_details_drug
        FOREIGN KEY (drug_id) REFERENCES drug(drug_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- prescription_details → prescription + drug
ALTER TABLE prescription_details
    ADD CONSTRAINT fk_pd_prescription
        FOREIGN KEY (prescription_id) REFERENCES prescription(prescription_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_pd_drug
        FOREIGN KEY (drug_id)         REFERENCES drug(drug_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- invoice → appointment
ALTER TABLE invoice
    ADD CONSTRAINT fk_invoice_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointment(appointment_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- payment → invoice
ALTER TABLE payment
    ADD CONSTRAINT fk_payment_invoice
        FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- notification → app_user
ALTER TABLE notification
    ADD CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id) REFERENCES app_user(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- notificationpreference → app_user
ALTER TABLE notificationpreference
    ADD CONSTRAINT fk_notifpref_user
        FOREIGN KEY (user_id) REFERENCES app_user(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- report → app_user (admin)
ALTER TABLE report
    ADD CONSTRAINT fk_report_admin
        FOREIGN KEY (admin_id) REFERENCES app_user(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE;


-- ------------------------------------------------------------
--  2.4  EXCLUDE constraints  (clinic_reservation overlap)
-- ------------------------------------------------------------

-- No two doctors can occupy the same clinic at overlapping times
ALTER TABLE clinic_reservation
    ADD CONSTRAINT no_clinic_overlap
        EXCLUDE USING gist (
            clinic_id                    WITH =,
            day                          WITH =,
            timerange(start_hour, end_hour) WITH &&
        );

-- The same doctor cannot be in two clinics at overlapping times
ALTER TABLE clinic_reservation
    ADD CONSTRAINT no_doctor_overlap
        EXCLUDE USING gist (
            doctor_id                    WITH =,
            day                          WITH =,
            timerange(start_hour, end_hour) WITH &&
        );


-- ------------------------------------------------------------
--  2.5  INDEXES
-- ------------------------------------------------------------

-- app_user
CREATE INDEX idx_user_role               ON app_user             (role);
CREATE INDEX idx_user_active             ON app_user             (is_active);

-- clinic_reservation
CREATE INDEX idx_reservation_clinic_day  ON clinic_reservation   (clinic_id, day);
CREATE INDEX idx_reservation_doctor_day  ON clinic_reservation   (doctor_id, day);

-- appointment
CREATE INDEX idx_appointment_patient     ON appointment          (patient_id, date_time);
CREATE INDEX idx_appointment_doctor      ON appointment          (doctor_id,  date_time);
CREATE INDEX idx_appointment_status      ON appointment          (status);
CREATE INDEX idx_appointment_date        ON appointment          (date_time);

-- medicalrecord
CREATE INDEX idx_mr_patient              ON medicalrecord        (patient_id,     visit_date);
CREATE INDEX idx_mr_doctor               ON medicalrecord        (doctor_id,      visit_date);
CREATE INDEX idx_mr_appointment          ON medicalrecord        (appointment_id);

-- prescription
CREATE INDEX idx_prescription_record     ON prescription         (record_id);

-- prescription_details
CREATE INDEX idx_pd_prescription         ON prescription_details (prescription_id);
CREATE INDEX idx_pd_drug                 ON prescription_details (drug_id);

-- drug_details
CREATE INDEX idx_drug_details_drug       ON drug_details         (drug_id);

-- invoice
CREATE INDEX idx_invoice_status          ON invoice              (status);

-- notification
CREATE INDEX idx_notification_user       ON notification         (user_id, is_read, sent_at);

-- report
CREATE INDEX idx_report_admin            ON report               (admin_id, generated_at);


-- ============================================================
--  PHASE 3 — TRIGGER FUNCTIONS & TRIGGERS
-- ============================================================

-- ------------------------------------------------------------
--  3a. Only a Patient-role user can get a patient profile
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_patient_role()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.user_id) <> 'Patient' THEN
        RAISE EXCEPTION 'app_user.role must be Patient to create a patient profile';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_role_check
BEFORE INSERT ON patient
FOR EACH ROW EXECUTE FUNCTION fn_check_patient_role();


-- ------------------------------------------------------------
--  3b. Only a Doctor-role user can get a doctor profile
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_doctor_role()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.user_id) <> 'Doctor' THEN
        RAISE EXCEPTION 'app_user.role must be Doctor to create a doctor profile';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_doctor_role_check
BEFORE INSERT ON doctor
FOR EACH ROW EXECUTE FUNCTION fn_check_doctor_role();


-- ------------------------------------------------------------
--  3c. appointment.patient_id must be a Patient-role user
--      appointment.doctor_id  must be a Doctor-role user
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_appointment_roles()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.patient_id) <> 'Patient' THEN
        RAISE EXCEPTION 'appointment.patient_id must reference a Patient-role user';
    END IF;
    IF (SELECT role FROM app_user WHERE user_id = NEW.doctor_id) <> 'Doctor' THEN
        RAISE EXCEPTION 'appointment.doctor_id must reference a Doctor-role user';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_appointment_roles
BEFORE INSERT OR UPDATE ON appointment
FOR EACH ROW EXECUTE FUNCTION fn_check_appointment_roles();


-- ------------------------------------------------------------
--  3d. medicalrecord.patient_id must be a Patient-role user
--      medicalrecord.doctor_id  must be a Doctor-role user
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_mr_roles()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.patient_id) <> 'Patient' THEN
        RAISE EXCEPTION 'medicalrecord.patient_id must reference a Patient-role user';
    END IF;
    IF (SELECT role FROM app_user WHERE user_id = NEW.doctor_id) <> 'Doctor' THEN
        RAISE EXCEPTION 'medicalrecord.doctor_id must reference a Doctor-role user';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_mr_roles
BEFORE INSERT OR UPDATE ON medicalrecord
FOR EACH ROW EXECUTE FUNCTION fn_check_mr_roles();


-- ------------------------------------------------------------
--  3e. clinic_reservation.doctor_id must be a Doctor-role user
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_reservation_doctor_role()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.doctor_id) <> 'Doctor' THEN
        RAISE EXCEPTION 'clinic_reservation.doctor_id must reference a Doctor-role user';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_reservation_doctor_role
BEFORE INSERT OR UPDATE ON clinic_reservation
FOR EACH ROW EXECUTE FUNCTION fn_check_reservation_doctor_role();


-- ------------------------------------------------------------
--  3f. Invoice can only be created for a completed appointment
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_invoice_completed()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT status FROM appointment WHERE appointment_id = NEW.appointment_id) <> 'completed' THEN
        RAISE EXCEPTION 'An invoice can only be created for a completed appointment';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_completed_only
BEFORE INSERT ON invoice
FOR EACH ROW EXECUTE FUNCTION fn_check_invoice_completed();


-- ------------------------------------------------------------
--  3g. Auto-mark invoice as paid when a payment row is inserted
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_mark_invoice_paid()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE invoice SET status = 'paid' WHERE invoice_id = NEW.invoice_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_mark_paid
AFTER INSERT ON payment
FOR EACH ROW EXECUTE FUNCTION fn_mark_invoice_paid();


-- ------------------------------------------------------------
--  3h. Reject appointments booked in the past
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_appointment_future()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.date_time <= NOW() THEN
        RAISE EXCEPTION 'Appointment date_time must be in the future';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_appointment_future_only
BEFORE INSERT ON appointment
FOR EACH ROW EXECUTE FUNCTION fn_check_appointment_future();


-- ------------------------------------------------------------
--  3i. Only Admin-role users can be linked to a report
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_check_report_admin_role()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF (SELECT role FROM app_user WHERE user_id = NEW.admin_id) <> 'Admin' THEN
        RAISE EXCEPTION 'report.admin_id must reference an Admin-role user';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_report_admin_role
BEFORE INSERT ON report
FOR EACH ROW EXECUTE FUNCTION fn_check_report_admin_role();
