# 9120-assignment
# Pediatric Vaccination Tracker — Database and Prototype Discussion

## Rules agreed so far

### ID formats

The IDs currently use `CHAR(6)` with these formats:

| ID | Example |
|---|---|
| `record_id` | `R00001` |
| `child_id` | `C00001` |
| `vaccine_id` | `V00001` |
| `schedule_id` | `S00001` |

It is not yet decided whether the database should automatically generate the `parent_id`, `child_id`, and `record_id`. The `reminder_id` format also needs to be confirmed.

### Recommended vaccination schedules

- `recommended_schedule` stores the recommended age for each vaccine dose.
- Its key is `(vaccine_id, dose_number)`.
- A child’s planned vaccination date is calculated from the child’s date of birth and the dose’s recommended age.
- PostgreSQL’s `INTERVAL` type is the current proposal for storing recommended ages, such as `2 months` or `6 months`.

### Creating a child’s schedule and reminders

The current design is to create the child’s plans and reminders automatically when a new child is added:

1. For each dose in `recommended_schedule`, create a plan for the new child.
2. Generate a `schedule_id` for that plan.
3. Calculate and save the planned vaccination date.
4. Create a reminder linked to that specific `schedule_id`.
5. Set the initial plan and reminder statuses to `pending`.

This requires the recommended schedule data to be in the database before children are added.

### Recording a completed vaccination

When a vaccination record is added through the front end, the database should find the matching child, vaccine, and dose. It should then change both the corresponding schedule status and reminder status to `completed`.

The existing `Check_status` domain will remain unchanged. It allows `pending` and `completed`.

### Reminder date

For now, the reminder date is set to the planned vaccination date. This is provisional and will be discussed with the group.

## SQL issues identified

- `Vaccine_schedule_id.schedule_id` uses `CHAR(6)`, so it cannot use PostgreSQL’s integer `IDENTITY` feature. A sequence can generate IDs such as `S00001`.
- `Vaccine_Record(vaccine_id, dose_number)` should reference `recommended_schedule(vaccine_id, dose_number)`, because the `Vaccine` table does not contain a dose number.
- The SQL file has been updated to reflect the current design, but it has not yet been run in PostgreSQL.

## Decisions to confirm before building the database

1. **ID generation:** Which IDs should the database generate? Confirm whether this includes `parent_id`, `child_id`, and `record_id`. Also confirm the prefix for `parent_id` and `reminder_id`. >> ALL IDs
2. **Recommended age:** Confirm whether `INTERVAL` is suitable for the recommended ages in the project data. >> Confirmed
3. **Recommended schedule data:** Confirm that recommended doses will be inserted before children are added. If recommended doses are added later, decide whether existing children should receive new plans automatically. >> The recommended doses should be inserted before children are added. And as a parent update their child's scheduled date, the scheduled date is automatically set to the updated one by parents.   
4. **Reminder timing:** Confirm whether reminders should be sent on the planned vaccination date or earlier. >> The user can set the reminder date and time, with the planned vaccination date selected by default.
5. **Python front end:** Decide whether to use Streamlit for the prototype and where PostgreSQL will run during the video demonstration.

## Proposed implementation and demonstration flow

```text
Load vaccine and recommended-dose data
        ↓
Add a parent and child through the Python application
        ↓
Database creates the child’s schedules and reminders
        ↓
Enter a vaccination record through the application
        ↓
Database marks the matching schedule and reminder completed
        ↓
Show the updated status in the application
```

A sensible first step is to verify this workflow in the database with sample data before building the full front end.
