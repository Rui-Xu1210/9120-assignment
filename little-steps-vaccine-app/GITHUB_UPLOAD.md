# GitHub Upload Checklist

## Repository contents

Upload the contents of this project folder, including:

- `app/`
- `apple/`
- `docker/`
- `frontend/`
- `migrations/`
- `scripts/`
- `tests/`
- `schema.sql`
- `seed.sql`
- `requirements.txt`
- `requirements-lock.txt`
- `Dockerfile`
- `docker-compose.yml`
- `.dockerignore`
- `.env.example`
- `README.md`
- `README.zh-CN.md`
- `DOCKER_SETUP.md`
- `docs/INSTALLATION_AND_VIDEO_GUIDE.md`
- `docs/VIDEO_SCRIPT.md`
- `GITHUB_UPLOAD.md`

## Do not upload

- `.env`
- `.venv/`
- `__pycache__/`
- `.pytest_cache/`
- `*.pyc`
- `*.log`
- `apple/.build/`
- Any local PostgreSQL data directory
- Any password, private key, Apple certificate, provisioning profile, or personal data

The repository's `.gitignore` already excludes the main local secrets and build/cache folders. Review `git status` before pushing.

## Suggested commands

```bash
git init
git add .
git status
# Confirm that .env and local database files are not listed.
git commit -m "Prepare Little Steps app for group handoff"
git branch -M main
git remote add origin <your-github-repository-url>
git push -u origin main
```

Unzip `Little-Steps-GitHub-Source.zip` and upload the contents of `little-steps-vaccine-app`, including the hidden `.gitignore`, `.dockerignore` and `.env.example` files. A private group repository is appropriate for coursework. No repository has been created or uploaded by this handoff. Check course rules before making the assignment public. No redistribution license has been added; agree one with your group if needed.

The Mac `.app` is distributed separately as `Little-Steps-Mac-arm64.zip` because compiled application bundles can make GitHub repositories unnecessarily large. The iPhone source is supplied in `Little-Steps-iPhone-Xcode.zip`; a recording device must be signed locally in Xcode. Not every group member needs to install the iPhone app. Optional GitHub Release attachments can hold the two ZIPs and English guide; do not commit a real database backup, signing files, credentials or recording with personal information.

## Before uploading

Read `docs/RELEASE_STATUS.md` for current verification limits. Keep the original schema and seed, migrations, API, native source and tests together. Existing test logs describe earlier runs; they are not proof that this release has been installed on an iPhone. Review all staged files and screenshots before pushing, even with `.gitignore` in place.
