# Native iPhone recording walkthrough

The final client is now the SwiftUI app, not the earlier website. Install using `apple/LittleSteps.xcodeproj` in full Xcode, connect to the Mac's LAN API address in the app's Server settings, and follow the native recording sequence in `../APPLE_APP.zh-CN.md`. Installation, phone connectivity, and recording are still pending real-device verification. In the native app use Family → Add a parent → Add a child; Schedule → dose → Record vaccination; History; Reminders → Pending / Completed / All. No Safari shortcut is needed.

## Archived web-preview walkthrough

The steps below describe the earlier optional web client, not the current native app. UI labels differ; use the native sequence above for the submission video.

## Before recording

Finish database initialization and confirm `/health` returns `status: ok`. Run the real PostgreSQL integration tests. Keep the computer and phone on the same trusted Wi-Fi. Use only fictional names and dates. Open the local app in the phone browser or its home-screen shortcut.

Use a fresh empty demo database, or create a new fictional family through the interface. Do not reset an existing project database just to obtain an empty screen.

The authorized local database is already initialized and contains `Alex Demo` / `Emma Demo`. To record the setup flow without deleting these examples, choose Family → Switch → + Add another parent, then continue with the fictional names below. Do not create a different database or rerun initialization.

## Suggested sequence about three minutes

| Time | On-screen action | Optional English narration |
|---|---|---|
| 0:00–0:15 | Open Little Steps on the phone. | “Little Steps helps parents keep vaccination plans, records and reminders together.” |
| 0:15–0:35 | Set up your family → Parent name `Alex Taylor` → Save. | “First, I add a parent. The Python API stores the parent in PostgreSQL and returns a generated ID.” |
| 0:35–0:55 | Child `Emma` → DOB `2026-06-18` → Create child’s plan. | “Adding a child triggers PostgreSQL to create a schedule and linked reminders for each recommended dose in our dataset.” |
| 0:55–1:15 | Scroll through Birth, 2 months, 4 months groups. | “The app groups the project schedule by recommended age. Vaccine brands in the sample may be alternatives, so this is not clinical guidance.” |
| 1:15–1:45 | Birth → Engerix B → Record vaccination → date `2026-06-18` → provider `Riverside Family Clinic` → Save. | “I record a dose that has been given. In one database transaction, the record is saved and the linked schedule and reminder become completed.” |
| 1:45–2:00 | Schedule shows green recorded date; toggle Hide completed months. | “The schedule updates immediately. Completed age groups can be hidden.” |
| 2:00–2:15 | History → open recorded dose and show provider/date. | “Parents can review the vaccination history and the provider entered with the record.” |
| 2:15–2:35 | Reminders → Completed → show Engerix B. Then Upcoming. | “The matching reminder is now completed. Other reminders remain available here.” |
| 2:35–2:50 | Open an upcoming reminder → edit reminder date/time → Save. | “Parents can adjust an in-app reminder. This prototype does not send push notifications.” |
| 2:50–3:10 | Schedule → a pending dose → Change planned date → Save; check reminder. | “Changing a planned date also moves its pending reminder and keeps the chosen time. It does not book a clinic appointment.” |
| 3:10–3:25 | Family → show parent/child; optionally add a second child and switch. | “Each child has their own schedule, records and reminders.” |

The example dates are intentionally fictional coursework data. If recording after a long delay, adapt dates only to preserve validation (birth date ≤ vaccination date ≤ today).

## Optional database evidence

After recording the phone flow, show a short computer capture of the original tables in pgAdmin, or execute `scripts/verify_demo.sql` in the configured demo database. The query joins the vaccination record, schedule and reminder so the completion trigger is visible. Do not display `.env`, credentials, or real personal data in the video.
