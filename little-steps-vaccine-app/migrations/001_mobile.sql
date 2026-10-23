-- Additive integration patch. The original schema and dataset are unchanged.
-- Moving an appointment also moves pending reminders, preserving their time of day.
CREATE OR REPLACE FUNCTION sync_reminder_with_schedule()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.scheduled_date IS DISTINCT FROM OLD.scheduled_date THEN
        UPDATE vaccine_reminder
        SET reminder_date = NEW.scheduled_date + reminder_date::time
        WHERE schedule_id = NEW.schedule_id AND reminder_status = 'pending';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS after_schedule_date_update_sync_reminder ON vaccine_schedule;
CREATE TRIGGER after_schedule_date_update_sync_reminder
AFTER UPDATE OF scheduled_date ON vaccine_schedule
FOR EACH ROW EXECUTE FUNCTION sync_reminder_with_schedule();
