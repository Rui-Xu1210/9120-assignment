# Verification status

## Native Apple client update

- Added a real shared SwiftUI iOS/macOS app; no WebView and no bundled DB credentials.
- Apple Silicon macOS executable compiled with Swift 6.3.3 in Swift 5 language mode, deployment target macOS 14. The app bundle passed `codesign --verify --deep --strict` with a local ad-hoc signature. Not notarized.
- `apple/test.command --live`: 24 assertions passed. Covers date-only/naive timestamp handling, recommended-age groups, safe server URLs, snake_case decoding, 409/422/503 errors, empty family, successful mutation followed by failed refresh (mock), duplicate save (mock), and read-only real API catalog/family/schedule/history/reminder/store loading. See `apple/NATIVE_TEST_RESULTS.txt`. Mock saves did not write to PostgreSQL.
- Mac GUI verification did **not** pass in this environment: LaunchServices `open` returned `kLSNoExecutableErr`, and direct executable startup exited 134. No native screenshot, native UI interaction, or successful desktop launch is claimed.
- Full Xcode and iOS SDK are absent. The `.xcodeproj` and Info.plist pass plist syntax checks, but this is not an iOS build. iPhone signing, installation, network permission, visual checks, and recording remain unverified.
- Existing database and demo records were retained; native live checks are read-only. Earlier browser evidence below refers only to the optional web client and does not establish native UI success.

Checked 20 October 2026, Australia/Sydney (application/database timezone).

## Real PostgreSQL verification — passed

- Created only the explicitly authorized local database `9120assignment_demo`. Maintenance database `postgres` was used only for a read-only permission/existence query and `CREATE DATABASE`; its application tables and all other databases were not modified.
- Initialized the supplied schema and seed, followed by `migrations/001_mobile.sql`: 22 vaccines, 31 recommended doses, initially no parents or children.
- `RUN_DB_TESTS=1 python -m pytest tests -v`: **30 passed**, no skipped tests. Includes 28 database-independent tests and two real PostgreSQL tests. One dependency deprecation warning is non-failing.
- Integration tests load the original SQL in a private UUID-named schema inside `9120assignment_demo`, exercise the Python HTTP API and SQL triggers, and drop only that schema. Confirmed no test schemas remain.
- Both application connections and setup reject any database name other than `9120assignment_demo`; a regression test checks this protection.

## Real browser/API/database flow — passed

The app on port 8000 uses PostgreSQL, not fixture data.

- Browser-created fictional parent `Alex Demo` and child `Emma Demo` (DOB 2026-04-20).
- Child insertion generated 31 schedules and 31 reminders in PostgreSQL.
- Browser-recorded Engerix B dose 1, vaccination date 2026-04-21, provider `Demo Family Clinic`.
- History shows the record; the original completion trigger set its schedule and reminder to `completed`, confirmed with a direct PostgreSQL join.
- Completed-reminder filter shows one item; pending/upcoming filter shows 30.
- Edited Bexsero dose 1 reminder to 2026-10-23 at 09:30, then changed its planned date to 2026-10-24. Browser and direct SQL both confirm the reminder moved to 2026-10-24 at 09:30.
- Reload retained the selected child and recorded-dose count. Hide-completed removed the completed Birth group.
- Browser error/warning log empty in the checked real session.
- `/health` returned `status: ok` with database `9120assignment_demo`; the current LAN-address health endpoint also returned HTTP 200 from this computer. This does not prove a physical phone can reach the address.
- `../app-postgresql.jpg` is a real browser screenshot. The browser viewport override did not take effect in this session, so this screenshot is desktop-width, not a physical-phone capture.

## Earlier UI-only checks

- Python and JavaScript syntax checks passed.
- Earlier fixture-based browser checks covered family setup, child switching, schedules, record/history, reminder filters/editing, date synchronization and reload persistence.
- Earlier layout checks at 390 × 844 and 320 × 740 reported no horizontal overflow. They used an explicitly labelled in-memory fixture server under `work/`, not PostgreSQL; the fixture server is stopped and is not shipped.
- `../mobile-ui-fixture-preview.png` retains its NOT CONNECTED TO POSTGRESQL label. It must not be used as real database evidence.
- `schema.sql` and `seed.sql` were copied directly from the supplied source files and were not edited. The original Downloads directory was unavailable for a final repeated byte comparison.

## Still requires your physical phone

- Native iPhone build/signing/installation, same-network reachability, and actual native-app screen recording. A Safari home-screen shortcut is not the native installation path.
- Keep the computer awake and the Python/PostgreSQL services running. If the displayed LAN IP is unreachable, check the computer's current Wi-Fi address and network isolation; do not expose PostgreSQL or enable public forwarding.

## Repeat tests safely

```bash
python -m pip install -r requirements-dev.txt
RUN_DB_TESTS=1 python -m pytest tests -v
```

Use only the authorized database. Do not reinitialize the already populated public schema. The fictional demonstration records are intentionally retained for preview; the automated tests do not alter them.
