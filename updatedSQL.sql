BEGIN;
CREATE DOMAIN Check_status 
AS VARCHAR(9)
DEFAULT 'pending'
CHECK (VALUE IN ('pending', 'completed'));  

CREATE TABLE Parent (
parent_id  CHAR(6)     NOT NULL,
name        VARCHAR(100) NOT NULL,

PRIMARY KEY (parent_id)
);

CREATE TABLE Child (
    child_id       CHAR(6)      NOT NULL,
    name           VARCHAR(100) NOT NULL,
    date_of_birth  DATE         NOT NULL,
    parent_id      CHAR(6)      NOT NULL,
    PRIMARY KEY (child_id),
    FOREIGN KEY (parent_id) REFERENCES Parent(parent_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Vaccine (
vaccine_id    CHAR(6),
vaccine_name  VARCHAR(50) NOT NULL,
vaccine_type  VARCHAR(25),
manufacturer  VARCHAR(100),
description   TEXT,

PRIMARY KEY (vaccine_id)
);

CREATE TABLE Prevented_Disease (
vaccine_id    CHAR(6)     NOT NULL,
disease_name  VARCHAR(50) NOT NULL,

PRIMARY KEY (vaccine_id, disease_name),
FOREIGN KEY (vaccine_id) REFERENCES Vaccine(vaccine_id)
        		ON UPDATE CASCADE
        		ON DELETE CASCADE
);

CREATE VIEW Child_With_Age AS
SELECT
    child_id,
    name,
    date_of_birth,
    parent_id,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))::INTEGER AS age
FROM Child;

CREATE SEQUENCE vaccine_schedule_number_seq
    START WITH 1
    MAXVALUE 99999;

CREATE TABLE recommended_schedule (
    vaccine_id      CHAR(6)  NOT NULL,
    dose_number     SMALLINT NOT NULL,
    recommended_age INTERVAL NOT NULL
        CHECK (recommended_age >= INTERVAL '0' ),

    PRIMARY KEY (vaccine_id, dose_number),

    FOREIGN KEY (vaccine_id)
        REFERENCES Vaccine (vaccine_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Vaccine_Record (
	record_id CHAR(6),
	child_id CHAR(6) NOT NULL,
	vaccine_id CHAR(6) NOT NULL,
	dose_number SMALLINT NOT NULL,
	vaccination_date TIMESTAMP NOT NULL,
	provider VARCHAR(50),

	PRIMARY KEY (record_id),
CONSTRAINT Vaccine_Record_FK1 FOREIGN KEY (child_id) REFERENCES 
Child(child_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
CONSTRAINT Vaccine_Record_FK2 FOREIGN KEY (vaccine_id, dose_number)
REFERENCES recommended_schedule(vaccine_id, dose_number)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
UNIQUE (child_id, vaccine_id, dose_number)
);

CREATE TABLE Vaccine_schedule_id (
    schedule_id CHAR(6),
    child_id    CHAR(6)  NOT NULL,
    vaccine_id  CHAR(6)  NOT NULL,
    dose_number SMALLINT NOT NULL,

    PRIMARY KEY (schedule_id),

    UNIQUE (child_id, vaccine_id, dose_number),

    FOREIGN KEY (child_id)
        REFERENCES Child (child_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    FOREIGN KEY (vaccine_id, dose_number)
        REFERENCES recommended_schedule (vaccine_id, dose_number)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE Vaccine_schedule (
    schedule_id  CHAR(6)     NOT NULL,
    scheduled_date DATE       NOT NULL,
    provider      VARCHAR(50),
    status       Check_status  NOT NULL ,

    PRIMARY KEY (schedule_id),

    FOREIGN KEY (schedule_id)
        REFERENCES Vaccine_schedule_id (schedule_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION create_vaccine_schedule(
    p_child_id     CHAR(6),
    p_vaccine_id   CHAR(6),
    p_dose_number  SMALLINT,
    p_provider     VARCHAR DEFAULT NULL
)
RETURNS CHAR(6)
LANGUAGE plpgsql
AS $$
DECLARE
    v_scheduled_date DATE;
    v_schedule_id   CHAR(6);
BEGIN
    SELECT (c.date_of_birth + rs.recommended_age)::DATE
    INTO v_scheduled_date
    FROM Child AS c
    JOIN recommended_schedule AS rs
      ON rs.vaccine_id = p_vaccine_id
     AND rs.dose_number = p_dose_number
    WHERE c.child_id = p_child_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Child % or recommended dose (vaccine %, dose %) does not exist',
            p_child_id, p_vaccine_id, p_dose_number;
    END IF;

    v_schedule_id :=
        'S' || LPAD(nextval('vaccine_schedule_number_seq')::TEXT, 5, '0');

    INSERT INTO Vaccine_schedule_id (
        schedule_id, child_id, vaccine_id, dose_number
    )
    VALUES (
        v_schedule_id, p_child_id, p_vaccine_id, p_dose_number
    );

    INSERT INTO Vaccine_schedule (
        schedule_id, scheduled_date, provider, status
    )
    VALUES (
        v_schedule_id, v_scheduled_date, p_provider, 'pending'
    );

    RETURN v_schedule_id;
END;
$$;

CREATE TABLE Vaccine_Reminder (
	reminder_id CHAR(6),
	schedule_id CHAR(6) UNIQUE NOT NULL,
	reminder_date TIMESTAMP NOT NULL,
	reminder_status Check_status NOT NULL,

	PRIMARY KEY (reminder_id),
	FOREIGN KEY (schedule_id) REFERENCES Vaccine_Schedule_id (schedule_id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

COMMIT;

BEGIN;

CREATE OR REPLACE FUNCTION update_parent(p_parent_id TEXT, p_name TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Parent SET name=p_name WHERE parent_id=p_parent_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Parent % does not exist', p_parent_id; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION delete_parent(p_parent_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    PERFORM 1 FROM Parent WHERE parent_id=p_parent_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Parent % does not exist', p_parent_id; END IF;
    DELETE FROM Child WHERE parent_id=p_parent_id;
    DELETE FROM Parent WHERE parent_id=p_parent_id;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION update_child(
    p_child_id TEXT, p_name TEXT, p_date_of_birth DATE, p_parent_id TEXT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Child
    SET name=p_name, date_of_birth=p_date_of_birth, parent_id=p_parent_id
    WHERE child_id=p_child_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Child % does not exist', p_child_id; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION delete_child(p_child_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Child WHERE child_id=p_child_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Child % does not exist', p_child_id; END IF;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION update_vaccination_record(
    p_record_id TEXT, p_child_id TEXT, p_vaccine_id TEXT,
    p_dose_number SMALLINT, p_vaccination_date TIMESTAMP, p_provider TEXT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Vaccine_Record
    SET child_id=p_child_id, vaccine_id=p_vaccine_id,
        dose_number=p_dose_number, vaccination_date=p_vaccination_date,
        provider=p_provider
    WHERE record_id=p_record_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Vaccination record % does not exist', p_record_id; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION delete_vaccination_record(p_record_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Vaccine_Record WHERE record_id=p_record_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Vaccination record % does not exist', p_record_id; END IF;
    RETURN TRUE;
END;
$$;

COMMIT;
