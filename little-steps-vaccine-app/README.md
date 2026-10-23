# Little Steps Vaccination Tracker

An English, parent-facing **native SwiftUI iPhone and Mac client** backed by the supplied PostgreSQL schema and Python/FastAPI application. No WebView is used. The earlier web interface is retained only as an optional API preview.

## Native Apple app

See `docs/INSTALLATION_AND_VIDEO_GUIDE.md` for the group handoff, Mac installation, iPhone installation, Docker setup, and current feature update. See `docs/VIDEO_SCRIPT.md` for the English recording walkthrough. The shared iPhone/Mac source project is `apple/LittleSteps.xcodeproj`; the recording device must be signed locally in Xcode. The Mac app is distributed separately as `Little-Steps-Mac-arm64.zip`. Read `docs/RELEASE_STATUS.md` before installing: this is a coursework handoff candidate, not a fully device-tested release.

## Quick start

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # only if .env does not exist; configure local PostgreSQL credentials
python scripts/setup_db.py --create
python scripts/serve.py
```

The only permitted database is `9120assignment_demo`: both the application and setup script reject other database names. Initialization refuses to overwrite public tables. If this project's source SQL is already loaded into `9120assignment_demo`, use `python scripts/setup_db.py --migrate-only` instead of initialization. The original author's local database is already initialized; do not run initialization again on it. A teammate's new isolated Docker database is initialized automatically and does not include that local family's saved records.

## Docker quick start

For an isolated, repeatable backend environment with pinned Python packages, see `DOCKER_SETUP.md`. From this folder, run `export DOCKER_DB_PASSWORD='choose-a-local-demo-password'` and then `docker compose up --build`. Docker uses its own PostgreSQL volume and the database name `9120assignment_demo`; it does not modify the PostgreSQL service or database on the Mac.

Keep this backend running, then open the native app. In Server settings use `http://127.0.0.1:8000` on Mac or the Mac's current LAN address on iPhone. The website at port 8000 is only the older optional preview. PostgreSQL stays private to the computer.

## Verification status

Current handoff checks and outstanding Mac GUI, iPhone and Docker verification are listed in `docs/RELEASE_STATUS.md`. The results below describe earlier backend/browser verification, not a successful native installation on a phone. No existing host database is modified by preparation of the handoff archives.

30 automated tests passed, including two real PostgreSQL integration tests and a database-target safety test. The authorized local database was created with 22 vaccines and 31 recommended doses. The real browser flow on port 8000 verified parent/child creation, automatic schedules/reminders, vaccination recording, history, reminder filtering/editing, date synchronization preserving time, and reload persistence. PostgreSQL queries confirmed the linked completion statuses and persisted reminder date/time. Temporary test schemas were removed. Other databases were not modified.

The local demo contains fictional parent `Alex Demo` and child `Emma Demo`, with one recorded dose. Earlier mobile-layout fixture checks are separately labelled and are not database integration evidence. Physical-phone access and recording still require verification on your phone. See `TEST_STATUS.md` and `LOCAL_DEMO.zh-CN.md`.

## Scope

Local student demonstration only; fictional family data only. No authentication, push notifications, offline data mode, or cloud deployment. The native client needs the Python API and PostgreSQL running. Source seed data may contain alternative brands and is not a clinically validated vaccination plan. The original schema and seed are retained verbatim; mobile extensions are separate.


## Delete operations and rollback
See [DELETE_OPERATIONS.md](DELETE_OPERATIONS.md) for installation, UI actions and transaction examples. Existing databases must run `python scripts/setup_db.py --migrate-only` before using the updated delete buttons.
