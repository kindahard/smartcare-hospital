-- ============================================================
-- SmartCare Hospital Management System
-- DDL Script — PostgreSQL
-- Best Practice: Tables first, then all constraints
-- ============================================================


-- ============================================================
-- SECTION 1: CREATE TABLES
-- ============================================================

CREATE TABLE "USER" (
    user_id       SERIAL          PRIMARY KEY,
    name          VARCHAR(100)    NOT NULL,
    email         VARCHAR(150)    NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,
    role          VARCHAR(10)     NOT NULL,
    is_active     BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP       NOT NULL DEFAULT NOW(),
    phone_number  VARCHAR(20)
);

CREATE TABLE PATIENT (
    patient_id    SERIAL          PRIMARY KEY,
    user_id       INT             NOT NULL,
    gender        VARCHAR(6)      NOT NULL,
    date_of_birth DATE            NOT NULL,
    address       VARCHAR(255),
    blood_type    VARCHAR(5)
);

CREATE TABLE DOCTOR (
    doctor_id      SERIAL          PRIMARY KEY,
    user_id        INT             NOT NULL,
    specialty      VARCHAR(100)    NOT NULL,
    license_number VARCHAR(50)     NOT NULL
);

CREATE TABLE APPOINTMENT (
    appointment_id SERIAL          PRIMARY KEY,
    patient_id     INT             NOT NULL,
    doctor_id      INT             NOT NULL,
    date_time      TIMESTAMP       NOT NULL,
    status         VARCHAR(10)     NOT NULL DEFAULT 'pending',
    notes          TEXT
);

CREATE TABLE MEDICALRECORD (
    record_id             SERIAL          PRIMARY KEY,
    patient_id            INT             NOT NULL,
    appointment_id        INT             NOT NULL,
    doctor_id             INT             NOT NULL,
    visit_date            DATE            NOT NULL,
    diagnosis             TEXT,
    notes                 TEXT,
    attached_document_url VARCHAR(500)
);

CREATE TABLE PRESCRIPTION (
    prescription_id SERIAL          PRIMARY KEY,
    record_id       INT             NOT NULL,
    issue_date      DATE            NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE DRUG (
    drug_id   SERIAL          PRIMARY KEY,
    drug_name VARCHAR(150)    NOT NULL
);

CREATE TABLE DRUG_DETAILS (
    ingredient_id     SERIAL          PRIMARY KEY,
    drug_id           INT             NOT NULL,
    active_ingredient VARCHAR(150)    NOT NULL
);

CREATE TABLE PRESCRIPTION_DETAILS (
    prescription_details_id SERIAL          PRIMARY KEY,
    prescription_id         INT             NOT NULL,
    drug_id                 INT             NOT NULL,
    dosage                  VARCHAR(100)    NOT NULL,
    frequency               VARCHAR(100)    NOT NULL,
    duration                VARCHAR(100)    NOT NULL  -- fixed typo: duartion -> duration
);

CREATE TABLE INVOICE (
    invoice_id     SERIAL           PRIMARY KEY,
    appointment_id INT              NOT NULL,
    issue_date     DATE             NOT NULL DEFAULT CURRENT_DATE,
    total_amount   NUMERIC(10, 2)   NOT NULL,
    status         VARCHAR(10)      NOT NULL DEFAULT 'pending'
);

CREATE TABLE PAYMENT (
    payment_id      SERIAL           PRIMARY KEY,
    invoice_id      INT              NOT NULL,
    amount          NUMERIC(10, 2)   NOT NULL,
    method          VARCHAR(15)      NOT NULL,
    receipt_pdf_url VARCHAR(500)
);

CREATE TABLE NOTIFICATION (
    notification_id SERIAL          PRIMARY KEY,
    user_id         INT             NOT NULL,
    type            VARCHAR(20)     NOT NULL,
    channel         VARCHAR(10)     NOT NULL,
    message         TEXT            NOT NULL,
    sent_at         TIMESTAMP       NOT NULL DEFAULT NOW(),
    is_read         BOOLEAN         NOT NULL DEFAULT FALSE
);

CREATE TABLE NOTIFICATIONPREFERENCE (
    preference_id SERIAL          PRIMARY KEY,
    user_id       INT             NOT NULL,
    channel       VARCHAR(10)     NOT NULL,
    event_type    VARCHAR(20)     NOT NULL,
    is_enabled    BOOLEAN         NOT NULL DEFAULT TRUE
);

CREATE TABLE REPORT (
    report_id     SERIAL          PRIMARY KEY,
    admin_id      INT             NOT NULL,
    report_type   VARCHAR(50)     NOT NULL,
    generated_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
    export_format VARCHAR(5)      NOT NULL,
    file_url      VARCHAR(500)
);


-- ============================================================
-- SECTION 2: UNIQUE CONSTRAINTS
-- ============================================================

ALTER TABLE "USER"                  ADD CONSTRAINT uq_user_email                    UNIQUE (email);
ALTER TABLE PATIENT                 ADD CONSTRAINT uq_patient_user_id               UNIQUE (user_id);
ALTER TABLE DOCTOR                  ADD CONSTRAINT uq_doctor_user_id                UNIQUE (user_id);
ALTER TABLE DOCTOR                  ADD CONSTRAINT uq_doctor_license_number         UNIQUE (license_number);
ALTER TABLE DRUG                    ADD CONSTRAINT uq_drug_name                     UNIQUE (drug_name);
ALTER TABLE NOTIFICATIONPREFERENCE  ADD CONSTRAINT uq_notifpref_user_channel_event  UNIQUE (user_id, channel, event_type);


-- ============================================================
-- SECTION 3: CHECK CONSTRAINTS
-- ============================================================

ALTER TABLE "USER"               ADD CONSTRAINT chk_user_role                  CHECK (role IN ('admin', 'doctor', 'patient', 'staff'));
ALTER TABLE PATIENT              ADD CONSTRAINT chk_patient_gender              CHECK (gender IN ('male', 'female'));
ALTER TABLE APPOINTMENT          ADD CONSTRAINT chk_appointment_status          CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'));
ALTER TABLE INVOICE              ADD CONSTRAINT chk_invoice_total_amount        CHECK (total_amount >= 0);
ALTER TABLE INVOICE              ADD CONSTRAINT chk_invoice_status              CHECK (status IN ('pending', 'paid', 'refunded'));
ALTER TABLE PAYMENT              ADD CONSTRAINT chk_payment_amount              CHECK (amount > 0);
ALTER TABLE PAYMENT              ADD CONSTRAINT chk_payment_method              CHECK (method IN ('card', 'digital_wallet'));
ALTER TABLE NOTIFICATION         ADD CONSTRAINT chk_notification_type           CHECK (type IN ('appointment', 'prescription', 'billing', 'system'));
ALTER TABLE NOTIFICATION         ADD CONSTRAINT chk_notification_channel        CHECK (channel IN ('email', 'in_app'));
ALTER TABLE NOTIFICATIONPREFERENCE ADD CONSTRAINT chk_notifpref_channel         CHECK (channel IN ('email', 'in_app'));
ALTER TABLE NOTIFICATIONPREFERENCE ADD CONSTRAINT chk_notifpref_event_type      CHECK (event_type IN ('appointment', 'prescription', 'billing', 'system'));
ALTER TABLE REPORT               ADD CONSTRAINT chk_report_export_format        CHECK (export_format IN ('pdf', 'excel'));


-- ============================================================
-- SECTION 4: FOREIGN KEY CONSTRAINTS
-- ============================================================

-- PATIENT
ALTER TABLE PATIENT                 ADD CONSTRAINT fk_patient_user
    FOREIGN KEY (user_id)                   REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

-- DOCTOR
ALTER TABLE DOCTOR                  ADD CONSTRAINT fk_doctor_user
    FOREIGN KEY (user_id)                   REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

-- APPOINTMENT
ALTER TABLE APPOINTMENT             ADD CONSTRAINT fk_appointment_patient
    FOREIGN KEY (patient_id)                REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE APPOINTMENT             ADD CONSTRAINT fk_appointment_doctor
    FOREIGN KEY (doctor_id)                 REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

-- MEDICALRECORD
ALTER TABLE MEDICALRECORD           ADD CONSTRAINT fk_medicalrecord_patient
    FOREIGN KEY (patient_id)                REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE MEDICALRECORD           ADD CONSTRAINT fk_medicalrecord_doctor
    FOREIGN KEY (doctor_id)                 REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE MEDICALRECORD           ADD CONSTRAINT fk_medicalrecord_appointment
    FOREIGN KEY (appointment_id)            REFERENCES APPOINTMENT (appointment_id)     ON UPDATE CASCADE ON DELETE RESTRICT;

-- PRESCRIPTION
ALTER TABLE PRESCRIPTION            ADD CONSTRAINT fk_prescription_record
    FOREIGN KEY (record_id)                 REFERENCES MEDICALRECORD (record_id)        ON UPDATE CASCADE ON DELETE RESTRICT;

-- DRUG_DETAILS
ALTER TABLE DRUG_DETAILS            ADD CONSTRAINT fk_drugdetails_drug
    FOREIGN KEY (drug_id)                   REFERENCES DRUG (drug_id)                   ON UPDATE CASCADE ON DELETE RESTRICT;

-- PRESCRIPTION_DETAILS
ALTER TABLE PRESCRIPTION_DETAILS    ADD CONSTRAINT fk_prescdetails_prescription
    FOREIGN KEY (prescription_id)           REFERENCES PRESCRIPTION (prescription_id)   ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE PRESCRIPTION_DETAILS    ADD CONSTRAINT fk_prescdetails_drug
    FOREIGN KEY (drug_id)                   REFERENCES DRUG (drug_id)                   ON UPDATE CASCADE ON DELETE RESTRICT;

-- INVOICE
ALTER TABLE INVOICE                 ADD CONSTRAINT fk_invoice_appointment
    FOREIGN KEY (appointment_id)            REFERENCES APPOINTMENT (appointment_id)     ON UPDATE CASCADE ON DELETE RESTRICT;

-- PAYMENT
ALTER TABLE PAYMENT                 ADD CONSTRAINT fk_payment_invoice
    FOREIGN KEY (invoice_id)                REFERENCES INVOICE (invoice_id)             ON UPDATE CASCADE ON DELETE RESTRICT;

-- NOTIFICATION
ALTER TABLE NOTIFICATION            ADD CONSTRAINT fk_notification_user
    FOREIGN KEY (user_id)                   REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

-- NOTIFICATIONPREFERENCE
ALTER TABLE NOTIFICATIONPREFERENCE  ADD CONSTRAINT fk_notifpref_user
    FOREIGN KEY (user_id)                   REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;

-- REPORT
ALTER TABLE REPORT                  ADD CONSTRAINT fk_report_admin
    FOREIGN KEY (admin_id)                  REFERENCES "USER" (user_id)                 ON UPDATE CASCADE ON DELETE RESTRICT;
