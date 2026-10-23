# Group handoff verification status

Prepared 21 October 2026. This is a coursework handoff candidate, not a notarized or device-tested release.

## Current checks

- Python API tests: 28 passed, two real-PostgreSQL tests skipped without explicit integration opt-in. Host tests do not establish Docker/Linux compatibility.
- Native non-live checks: 22 passing assertions, including 12 months to 1 year, 18 months to 1 year and 6 months, and mixed years/months/days. No current live API test is claimed.
- Web JavaScript syntax and shell-script syntax checked. Compose YAML parsed structurally, not validated by Docker Compose.
- Current Apple Silicon Mac executable rebuilt from source and local ad-hoc signature checked. Minimum macOS 14; no Intel package provided.
- Release archives checked for ZIP integrity, expected source files and excluded local secrets, signing material and build caches.

## Still needs a teammate check

- Mac GUI launch failed during earlier verification with `kLSNoExecutableErr`; direct executable startup exited 134. This packaging step does not establish that the GUI launches. Native screen rendering and interactive workflows remain unverified. Build and inspect in full Xcode if necessary.
- No full Xcode/iOS SDK was available: no iOS compile, signing, install or physical-phone network/UI recording has been performed. The iPhone ZIP is source, not an installable IPA.
- No Docker CLI/Desktop was available: image build, locked dependencies on Python 3.12 Linux, startup and persistent-volume behavior remain unverified. Tags are not immutable digest pins.
- A fresh Docker instance contains the source vaccine catalog, not the author's saved local family. Add fictional records for the video. Do not reset an existing database.

## Earlier evidence

`TEST_STATUS.md`, `TEST_RESULTS.txt`, `apple/NATIVE_TEST_RESULTS.txt` and `apple/NATIVE_BUILD_STATUS.md` retain historical backend, browser and native-check results. Earlier 30-test runs included live database tests; these are separate from the current 28-pass run. Browser screenshots are not native-app screenshots.

## Acceptance rehearsal

On the designated phone, verify API health, add parent and child, inspect age groups, record a dose, confirm History and completed reminders, edit a pending reminder, change its planned date, and refresh to confirm persistence. For Docker, restart without deleting the named volume and check saved records again. Only call the recording successful after this rehearsal passes.

This release preparation does not access or modify any host database. The only permitted application database name remains `9120assignment_demo`. No authentication, encrypted transport or push notifications are provided; use fictional data on a trusted local network only.
