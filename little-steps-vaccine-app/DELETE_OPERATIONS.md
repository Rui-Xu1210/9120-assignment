# Delete operations and transactions

## Existing database
Run `python scripts/setup_db.py --migrate-only` from this project, then restart the backend and refresh the browser. This applies the additive migrations without deleting existing data. Alternatively, execute `migrations/002_delete_operations.sql` in PostgreSQL inside BEGIN / COMMIT; issue ROLLBACK if it fails.

## New database
Use the existing setup instructions (`python scripts/setup_db.py --create`). `schema.sql` includes the delete functions and trigger. Setup also reapplies migrations safely.

## Frontend
- Family → Manage family → Delete the selected child, or delete the parent and all their children.
- History → choose a record → Delete vaccination record.
- Each action shows its effect and offers Delete / Cancel. Cancel sends no request.
- After deletion, the UI reloads and repairs selected parent/child IDs.

## PostgreSQL and backend
- DELETE /children/{child_id}: removes the child; foreign keys cascade to records, schedule identities, schedule details and reminders.
- DELETE /records/{record_id}: removes the record; a SQL trigger resets the matching schedule and reminders to pending, preserving their dates. A corrected record can be added afterwards.
- DELETE /parents/{parent_id}: locks the parent, deletes their children and then the parent in the same transaction. The existing restrictive parent foreign key remains.
- app/db.py explicitly commits successful transactions, rolls back on exceptions, and closes the connection. A missing target returns 404.
- SQL functions participate in the caller's transaction. scripts/transaction_examples.sql demonstrates BEGIN, ROLLBACK and COMMIT.
- Rollback is available before commit; it is not an undo for a completed request. A network interruption can leave the client unsure whether commit happened; refresh before retrying.

Both the browser frontend and native Apple client are updated.

## Xcode app
Open `apple/LittleSteps.xcodeproj`, choose the LittleSteps scheme and your Mac or iPhone target, then Run. Keep the updated Python backend and PostgreSQL running separately.
- Family: delete a parent (including their children) or an individual child.
- History: delete a vaccination record.
- A confirmation sheet explains the effect. Cancel sends no delete request.
- Successful deletions refresh the family selection, records, schedules and reminders.
- For an existing database, apply the migration above before using these controls.
- On iPhone, configure the Mac's local network API address in the app's server settings.

The project retains its existing local-demo access model (no login).

Validation details and test commands are in TEST_RESULTS.txt.

The supplied standalone SQL files are older than this application's schema. Use this project's schema.sql and seed.sql together as the authoritative app setup; do not load both schema versions into the same database.
