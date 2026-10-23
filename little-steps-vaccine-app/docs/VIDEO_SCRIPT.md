# Little Steps Video Script

## Suggested length

Approximately three minutes. Record the native iPhone app, not the older browser preview. Use fictional information only.

## Screen sequence and English narration

| Time | Screen action | Suggested narration |
|---|---|---|
| 0:00–0:15 | Open Little Steps and show Schedule, History, Reminders, and Family. | “Little Steps is a native SwiftUI app that helps parents keep vaccination plans, records, and reminders together.” |
| 0:15–0:35 | Family → Add a parent → enter `Alex Taylor`. | “I start by adding a parent. The app sends the request through the Python API and stores the family data in PostgreSQL.” |
| 0:35–0:55 | Add a child → `Emma Taylor` → choose a fictional past date of birth. | “When I add a child, the database creates a schedule and linked reminders for the recommended doses in our coursework dataset.” |
| 0:55–1:15 | Open Schedule and show At birth, 2 months, 4 months, and a group older than one year if visible. | “The Schedule page groups doses by age. For older groups, the app now shows years and remaining months, such as one year and six months, which is easier for parents to understand.” |
| 1:15–1:45 | Open At birth → a dose → Record vaccination. Enter a valid fictional date and `Demo Family Clinic`, then save. | “I record a completed vaccination with the date and provider. The matching schedule and reminder are updated together.” |
| 1:45–2:00 | Show Recorded and toggle Hide completed age groups. | “The completed dose is shown in the schedule, and completed age groups can be hidden.” |
| 2:00–2:15 | Open History and show the saved provider and date. | “History gives the parent a clear record of previous vaccinations.” |
| 2:15–2:35 | Open Reminders → Completed, then Pending. Edit a pending reminder date and time. | “The Reminders page separates completed and pending records. Parents can adjust a pending reminder, but this coursework prototype does not send push notifications.” |
| 2:35–2:55 | Change an unrecorded planned date in Schedule, then check Reminders. | “When a planned date changes, its pending reminder date moves with it while preserving the selected time.” |
| 2:55–3:10 | Refresh, return to Family, and show the saved child. | “Finally, I refresh the app to demonstrate persistence. All data in this recording is fictional coursework data.” |

## Recording checklist

- Keep Docker Compose and the API running.
- Keep the Mac and iPhone on the same trusted Wi-Fi.
- Do not show `.env`, passwords, database administration screens, or real personal data.
- Avoid using `localhost` or `127.0.0.1` in the iPhone app.
- Do not delete the existing database to repeat the demo. Add another fictional family instead.
- If the video is shorter, prioritize Family, Schedule, Record vaccination, History, Reminders, and refresh persistence.
