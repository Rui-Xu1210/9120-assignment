# Docker setup for Little Steps

This Compose setup runs an isolated PostgreSQL database and the Python/FastAPI API. It does not connect to, recreate, or modify the existing PostgreSQL database on the Mac. The app still uses the same protected database name, `9120assignment_demo`, inside the container.

## Versions and installed packages

- **API image:** `python:3.12-slim-bookworm`
- **Database image:** `postgres:18-alpine`
- **Python packages:** installed from `requirements-lock.txt`, including FastAPI `0.150.0`, Uvicorn `0.54.0`, Psycopg `3.3.6`, Pydantic `2.14.1`, python-dotenv `1.2.4`, and the pinned test/runtime packages listed in that file.
- **Application port:** `8000`
- **Database port:** `5432`, private to the Docker Compose network and not published to the Mac.

The Docker image installs the locked Python packages with `pip`, copies the API, web preview, schema, seed, migration, and startup files into `/app`, and runs as an unprivileged `appuser`.

The image tags select Python 3.12 and PostgreSQL 18, but are not immutable digest pins; patch versions may change. Docker Desktop is not installed in the preparation environment, so image builds, Linux dependency compatibility, startup and container persistence have not been tested. The Python lock file was tested on the host only. Complete the smoke test below before recording.

## Start the isolated environment

Install Docker Desktop, then run these commands from this folder:

```bash
export DOCKER_DB_PASSWORD='choose-a-local-demo-password'
docker compose up --build
```

On the first run, the API waits for PostgreSQL, initializes the empty `9120assignment_demo` database with `schema.sql` and `seed.sql`, applies the mobile migration, and starts the API. Open `http://127.0.0.1:8000` on the Mac. For an iPhone on the same Wi-Fi, use the Mac's LAN address, for example `http://192.168.1.10:8000`.

On later runs, the entrypoint detects the existing tables and applies only the additive migration. It never drops tables or runs the destructive initialization path. The named `postgres-data` volume keeps the container database between restarts.

PostgreSQL 18 stores its versioned data under `/var/lib/postgresql`; the volume is mounted at that parent directory. This is a new isolated dataset, not a copy of the existing Mac demonstration database. Add a fictional parent and child in Family before recording. Do not move a previous PostgreSQL data volume into this setup without an appropriate migration.

If port 8000 is occupied, stop the other demo API or run `API_PORT=8001 docker compose up --build`. Use port 8001 in the native app and health-check URL too. Compose publishes the API to the local network for the iPhone; do not expose it to the internet or forward the port on a router. Keep the same Docker password for an existing volume: changing the exported variable does not change the stored database user's password.

To stop the services without deleting data:

```bash
docker compose down
```

To remove this isolated Docker database and start a fresh demonstration database, use the following only when you are sure you do not need the Docker volume:

```bash
docker compose down -v
```

This command affects only the Docker volume. It does not touch any PostgreSQL database installed on the Mac.

## Run checks

With the services running, the API health check is available at `http://127.0.0.1:8000/health`. The native read-only checks can be pointed at a separately running local API; the Docker API itself can be tested with the Python test suite after installing the development requirements on the host.

The app remains a coursework demonstration: use fictional family data, a trusted network, and no real medical records. The native iPhone/Mac client connects to the API; it does not connect directly to PostgreSQL.

Before the video, check `docker compose ps`, open `/health`, add a fictional family, record one dose, check History and Reminders, restart with `docker compose down` followed by `docker compose up`, then confirm that the saved records remain. Do not use `down -v` for this persistence check. These steps are a teammate acceptance checklist, not a claim of completed testing.
