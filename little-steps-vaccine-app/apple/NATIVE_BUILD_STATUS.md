# Current revision: native delete operations

The native source now includes child, record and parent deletion with confirmation sheets. This revision has not been built with Xcode in this environment. Earlier build notes below refer to the previous source.

# Native build and verification

Historical native verification notes follow. For the 21 October 2026 handoff, use `../docs/RELEASE_STATUS.md` for current test counts and outstanding limitations. In particular, a successful build and signature do not establish that the native GUI launches.

## Passed

- Shared SwiftUI source compiled as an arm64 macOS executable, minimum macOS 14.
- `.app` structure, Info.plist, icon resources and local ad-hoc signature verification.
- Xcode project and Info.plist property-list syntax checks.
- 24 native assertions in `NATIVE_TEST_RESULTS.txt`, including read-only live checks of the supplied Python API and authorized PostgreSQL database.
- Existing Python suite: 30 passed, including two real PostgreSQL tests. Temporary test schemas are confined to `9120assignment_demo` and removed afterward.

## Not passed / not yet verified

- Mac GUI launch: LaunchServices returned `kLSNoExecutableErr` in the current execution environment, including when testing a temporary POSIX-path copy. Direct executable launch exited 134. Native screen rendering and interactive UI flows have not been verified. No native screenshot is supplied.
- iPhone: full Xcode and iOS platform SDK are not installed here. Project syntax checks are not an iOS compile. Signing, installation, device network access and actual recording still require the user's Mac/Xcode/iPhone.
- The earlier screenshots show the optional browser UI, not this native app.

The built Mac executable is not notarized and does not bundle Python or PostgreSQL. Refer to `../docs/INSTALLATION_AND_VIDEO_GUIDE.md` for setup, installation and the remaining verification steps. Do not reinitialize the existing demo database.
