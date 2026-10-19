# Local Setup Guide for the Frontend Team

This guide explains how to run the PostgreSQL database and Python backend on a teammate's own computer, then connect a phone app to that computer over the local Wi-Fi network. No shared or cloud server is required.

## How the parts connect

```text
Phone app  --HTTP/JSON-->  Python backend (teammate's computer)  -->  PostgreSQL (same computer)
```

- `sql_code_por.sql` creates the database tables, keys, triggers, and view.
- `Insert_dataset.sql` loads the vaccine catalogue, prevented diseases, and recommended dose ages.
- `app/` contains the Python backend and its frontend-facing functions.
- `.env` contains the local database connection settings, including a password. Keep it private.
- `.env.example` is a shareable template with a placeholder password.

## Files to share with the frontend teammate

Share the project folder, including at least:

- the `app/` folder
- `requirements.txt`
- `.env.example`
- `sql_code_por.sql`
- `Insert_dataset.sql`
- `README.md`
- `FRONTEND_HANDOFF.md`

Do **not** share `.env`. It contains credentials for your own computer. Each teammate creates their own `.env` with their own local PostgreSQL settings.

Use `sql_code_por.sql` to initialize the database. Do not use the older draft `sql_code.sql`.

## Set up PostgreSQL on the teammate's computer

### 1. Install PostgreSQL

Install PostgreSQL on the computer that will run the project. pgAdmin can be used to manage that computer's local PostgreSQL server. Server labels and connection settings may differ between computers; use the local server and credentials configured on that computer.

### 2. Create a new, empty database

In pgAdmin, connect to the local PostgreSQL server and create a database named:

```text
9120assignment
```

The PostgreSQL username and password are the database login credentials configured on that computer. They are not the computer login or a pgAdmin website password.

### 3. Create the tables and load the starter data

Select the new `9120assignment` database in pgAdmin and open its **Query Tool**. Run these files in order:

1. `sql_code_por.sql`
2. `Insert_dataset.sql`

Run both files in the Query Tool connected to `9120assignment`, not in a different database. These are initialization scripts for a new database. Run them once; running them again may fail because the tables or starter rows already exist.

Afterward, in pgAdmin, expand `Schemas → public → Tables`. You should see tables such as `parent`, `child`, `vaccine`, `vaccine_record`, `vaccine_schedule`, and `vaccine_reminder`. The starter data includes vaccine catalogue entries. The parent and child tables are initially empty; that is expected.

## Set up and run the Python backend

### 1. Install Python

Install Python 3.10 or newer, then open a terminal and change to the project folder.

### 2. Create a local `.env` file

In the project root (the folder containing `requirements.txt`), copy `.env.example` and name the copy `.env`. Edit `.env` with the PostgreSQL settings for the teammate's own computer:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=9120assignment
DB_USER=postgres
DB_PASSWORD=the password configured for PostgreSQL on this computer
```

If the local PostgreSQL installation uses a different port or username, enter those local values instead. Do not add quotes around the password. Do not share or commit `.env`.

### 3. Install the Python packages

macOS / Linux:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

Windows PowerShell:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install -r requirements.txt
```

### 4. Start and check the backend

Make sure PostgreSQL is running, then start the backend from the project root:

```bash
python -m uvicorn app.main:app --reload
```

On that same computer, open:

```text
http://127.0.0.1:8000/docs
```

This is an interactive API reference. Try `GET /health` first. A successful response shows that the backend reached PostgreSQL. You can also try `GET /vaccines`; it should return the starter vaccine catalogue.

To stop the backend, press `Ctrl+C` in the terminal where Uvicorn is running.

## Connect a phone app over local Wi-Fi

On a phone, `127.0.0.1` and `localhost` refer to the phone itself, not the teammate's computer. A physical phone therefore cannot use the computer's local-only address above.

To connect the phone and computer on the same Wi-Fi network:

1. Find the computer's local Wi-Fi IP address, for example `192.168.1.23`.
2. Start the backend so other devices on the local network can reach it:

   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

3. Set the phone app's API base URL to the computer's local IP address, for example:

   ```text
   http://192.168.1.23:8000
   ```

   Replace the example IP with the actual IP address of the computer running the backend. Do not use `localhost` in the phone app's API URL.

4. If the phone cannot connect, check whether the computer firewall allows Python/Uvicorn to accept local network connections. Some campus Wi-Fi networks isolate devices; if so, try connecting both devices to the same personal hotspot.

The computer must remain on, with both PostgreSQL and the Python backend running, while the phone app uses the data. This is enough for a local course demonstration; no cloud deployment is needed. Do not expose PostgreSQL port `5432` to the phone or the network. The phone should connect to the Python backend on port `8000` only.

## Main operations the frontend can call

The API sends and receives JSON. Try the routes in `/docs` before connecting them to the phone UI:

1. `POST /parents` creates a parent. Save the returned `parent_id`.
2. `POST /children` creates a child using `name`, `date_of_birth`, and `parent_id`. The database trigger creates schedules and reminders based on the recommended vaccine doses.
3. `GET /children/{child_id}` returns the child's profile, vaccination history, and schedules.
4. `PATCH /schedules/{schedule_id}` changes an appointment date, provider, or status.
5. `POST /records` records an administered vaccine dose. The database trigger marks the matching schedule and reminder as completed.
6. `GET /records?child_id=C00001` lists a child's vaccination history.
7. `GET /reminders?child_id=C00001` lists a child's reminders. Add `&status=pending` to show only pending reminders.
8. `GET /vaccines` and `GET /schedules/recommended` return the vaccine catalogue and recommended dose information. Vaccine IDs are generated by the database; look them up instead of hard-coding them in the app.

Reminders are database records for the app to display. The current version does not send push notifications, SMS, or email. The backend also has no login or authentication yet, so use it only for a controlled local course demonstration and do not expose it to the public internet.

## Team setup notes

- For a consistent setup, each teammate should create a local database named `9120assignment` and initialize it with the two specified SQL files.
- PostgreSQL credentials may differ on each computer. Each teammate enters their own local credentials in their own `.env` file.
- The existing project database on the original developer's computer is currently in that computer's `postgres` database. This is only that computer's current setup. A teammate can create a fresh `9120assignment` database and run the SQL scripts; there is no need to copy the original developer's password or database files.
- If the mobile frontend is a web app or uses a WebView, browser cross-origin rules may require adding a CORS policy for its development origin. CORS is not currently configured in this Python backend. Confirm the frontend technology before choosing the allowed origin.
