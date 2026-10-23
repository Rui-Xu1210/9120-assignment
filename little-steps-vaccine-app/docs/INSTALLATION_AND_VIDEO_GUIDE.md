# Little Steps Installation and Video Guide

This guide helps teammates install Little Steps, prepare one iPhone for the coursework video, and share clean source on GitHub. The app is a native SwiftUI client, not a website shortcut. It needs a Python/FastAPI backend and PostgreSQL running on a Mac or in Docker. Only one group member needs to prepare the recording phone.

**Read first:** the current Mac executable compiles and its ad-hoc signature verifies, but its GUI launch failed in the preparation environment. Mac interaction is not verified. Full Xcode and Docker Desktop are unavailable here, so iOS compilation, signing, installation and Docker execution have not been verified. These packages are a handoff candidate, not a promise of one-click installation. See `docs/RELEASE_STATUS.md` and complete a rehearsal before recording.

## What to share with the group

- `Little-Steps-Mac-arm64.zip`: prebuilt Apple Silicon Mac client, launcher and guide; no backend is bundled.
- `Little-Steps-iPhone-Xcode.zip`: native source and English notes; not an IPA and not a complete backend package.
- `Little-Steps-GitHub-Source.zip`: complete clean project, including the native client, API, SQL, tests and Docker configuration. Extract its `little-steps-vaccine-app` folder for backend commands and GitHub upload.
- `Little-Steps-Group-Guide-English.docx`: printable installation guide, English video narration and GitHub checklist.
- `docs/INSTALLATION_AND_VIDEO_GUIDE.md`: this guide.
- `docs/VIDEO_SCRIPT.md`: the suggested English narration and screen sequence.
- `requirements-lock.txt`: the exact Python package versions.

Mac users need the Mac ZIP plus the source ZIP. The recording-phone owner needs the source ZIP and Xcode; the smaller iPhone ZIP is an optional convenience copy of the same Apple source. Do not share `.env`, database passwords, signing certificates, provisioning profiles, local PostgreSQL files, `.venv`, `.pytest_cache`, or `apple/.build`.

## Mac installation

### Requirements

- Apple Silicon Mac (`arm64`), macOS 14 or later.
- Docker Desktop if using the container backend.
- Otherwise, local PostgreSQL and Python may be used as described in `README.md`.

### Recommended Docker setup

1. Install and open Docker Desktop.
2. Extract the source ZIP and open Terminal in `little-steps-vaccine-app`.
3. Set a local Docker-only password:

```bash
export DOCKER_DB_PASSWORD='choose-a-local-demo-password'
```

4. Start the isolated API and PostgreSQL database:

```bash
docker compose up --build
```

5. Confirm the API at `http://127.0.0.1:8000/health`.
6. Unzip `Little-Steps-Mac-arm64.zip` and optionally move `Little Steps.app` into Applications.
7. Double-click `Little Steps.app`. If macOS blocks an unidentified developer, only approve a trusted copy via **System Settings > Privacy & Security > Open Anyway**, if offered. Do not disable Gatekeeper. This does not fix a crash or missing-executable error. If the app still fails, use the source project in full Xcode to build and inspect its error; do not repeatedly bypass security prompts.
8. In the app, open **Server settings** and use `http://127.0.0.1:8000`.
9. Select **Connect and load family**.

The Mac application is locally ad-hoc signed and not notarized. It is an arm64 build; no Intel binary is included. Intel Mac users need a compatible toolchain to build from source, and that path has not been tested. Keep the backend running while using the app. Opening port 8000 in a browser shows the older optional preview, not the native app.

## iPhone installation

There is no universal installable IPA in this coursework package and it is not an App Store release. A physical iPhone build must be signed locally by the recording-device owner. Never share an Apple Account password, signing key or certificate with the group. Use an iPhone with iOS 17 or later and a compatible full Xcode installation.

1. Install the full **Xcode** application from the Mac App Store.
2. Open `apple/LittleSteps.xcodeproj` from the extracted source or iPhone ZIP. The source ZIP is still required for backend commands.
3. Select the **LittleSteps** target.
4. Under **Signing & Capabilities**, enable **Automatically manage signing** and choose your own **Team**.
5. If necessary, change the Bundle Identifier to a unique value such as `com.yourname.littlestepsdemo`.
6. Connect the iPhone by cable, trust the Mac, and enable Developer Mode if requested.
7. Select the iPhone as the run destination and click **Run**.
8. Start the backend on the Mac with Docker Compose.
9. Make sure the Mac and iPhone use the same trusted Wi-Fi network.
10. In the iPhone app, open **Server settings** and enter the Mac's Wi-Fi IPv4 address, for example `http://192.168.1.10:8000`.
11. Do not use `127.0.0.1` or `localhost` on the iPhone. Those addresses refer to the iPhone itself.
12. Allow Local Network access when iOS asks for it, then choose **Connect and load family**.

The iPhone app requires the Python API to stay running on the Mac. PostgreSQL remains private to the Mac or Docker network; the phone connects only to the API. If the phone cannot reach `/health` in Safari, check the Wi-Fi address, macOS firewall and network client isolation before debugging the app. Recheck the Mac IP after changing networks. Personal-team signing can require later rebuilding; follow Xcode's current prompts.

## Current feature update

On the Schedule page, native recommendation age groups now use years and remaining months when the age is at least one year:

- `12 months` becomes `1 year`.
- `18 months` becomes `1 year, 6 months`.
- A mixed age can include days, such as `2 years, 1 month, 2 days`.

The web preview also uses this convention for schedule labels and child ages. The native app displays a date of birth rather than a numeric child-age label. Numeric age values are still used for schedule ordering.

## Before recording

Follow `docs/VIDEO_SCRIPT.md` for a roughly three-minute English narration. Rehearse Family entry, Schedule, recording a dose, History, Reminders, and refresh persistence on the actual phone. A fresh Docker database contains the vaccine catalog, not the original Mac demo family; create fictional records such as Alex Taylor and Emma Taylor. Do not delete a database to repeat the demonstration. Use the phone's screen recorder and capture narration separately if preferred; trim credentials, notifications and personal screens before sharing.

## GitHub handoff

Follow `GITHUB_UPLOAD.md` in the full source ZIP. Upload the extracted source contents, including hidden ignore/example files, not just the ZIP itself. Review staged files before pushing. This handoff does not create a repository or upload anything for you. Keep the project private unless course rules and all group members permit publication.

## Important coursework limits

- Use fictional parent, child, provider, and vaccination information only.
- The sample schedule may include alternative brands and is not medical advice.
- Reminders are stored/queryable records; they do not send push notifications, texts, or emails.
- The local HTTP API has no user authentication and is unencrypted. Use a trusted local network only.
- The application client does not connect directly to PostgreSQL.
- The authorized database name is `9120assignment_demo`. Do not change it to another database name or reinitialize an existing database just for a recording.
