-- Additive migration: safe to reapply to an existing project database.
-- Functions run inside the caller's transaction; they never commit themselves.

CREATE OR REPLACE FUNCTION reset_deleted_record_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE matched_schedule CHAR(6);
BEGIN
    SELECT schedule_id INTO matched_schedule FROM vaccine_schedule_id
    WHERE child_id=OLD.child_id AND vaccine_id=OLD.vaccine_id
      AND dose_number=OLD.dose_number;
    UPDATE vaccine_schedule SET status='pending'
    WHERE schedule_id=matched_schedule;
    UPDATE vaccine_reminder SET reminder_status='pending'
    WHERE schedule_id=matched_schedule;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS after_record_delete_reset_status ON vaccine_record;
CREATE TRIGGER after_record_delete_reset_status
AFTER DELETE ON vaccine_record FOR EACH ROW
EXECUTE FUNCTION reset_deleted_record_status();

CREATE OR REPLACE FUNCTION delete_child(p_child_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    -- Cascades remove records, schedule identities, details and reminders.
    DELETE FROM child WHERE child_id=p_child_id;
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION delete_vaccination_record(p_record_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE owner_id CHAR(6);
BEGIN
    SELECT child_id INTO owner_id FROM vaccine_record WHERE record_id=p_record_id;
    IF NOT FOUND THEN RETURN FALSE; END IF;
    -- Same lock order as record creation: child first, then record and statuses.
    PERFORM 1 FROM child WHERE child_id=owner_id FOR UPDATE;
    DELETE FROM vaccine_record WHERE record_id=p_record_id;
    -- The delete trigger resets the matching schedule and reminders.
    RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION delete_parent(p_parent_id TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    -- Prevent new children being attached while this family is removed.
    PERFORM 1 FROM parent WHERE parent_id=p_parent_id FOR UPDATE;
    IF NOT FOUND THEN RETURN FALSE; END IF;
    -- Keep the existing ON DELETE RESTRICT parent foreign key.
    DELETE FROM child WHERE parent_id=p_parent_id;
    DELETE FROM parent WHERE parent_id=p_parent_id;
    RETURN FOUND;
END;
$$;
