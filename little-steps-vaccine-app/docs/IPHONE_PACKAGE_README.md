# Little Steps iPhone source package

This is the native SwiftUI Xcode project for the group coursework demonstration. It is not an IPA, App Store download, web shortcut, or standalone backend. It requires iOS 17 or later and compatible full Xcode on a Mac. iOS compilation and device installation have not been verified in the preparation environment.

1. Obtain `Little-Steps-GitHub-Source.zip` as well. Extract `little-steps-vaccine-app` and follow its `DOCKER_SETUP.md` to run the API and isolated database.
2. Open `apple/LittleSteps.xcodeproj` in Xcode, select LittleSteps, enable automatic signing and choose your own Team. Make the bundle identifier unique if necessary.
3. Connect and trust the iPhone, follow Developer Mode prompts, select the phone and Run.
4. Keep the Mac and iPhone on the same trusted Wi-Fi. In Server settings enter the Mac's LAN URL, for example `http://192.168.1.10:8000`, not localhost. Allow Local Network access.
5. Use `docs/INSTALLATION_AND_VIDEO_GUIDE.md` and `docs/VIDEO_SCRIPT.md` for the demonstration. Only one recording phone is needed.

No Apple credentials, certificates, provisioning profiles or database passwords are included. Use only fictional coursework data. Current limitations and checks are in `docs/RELEASE_STATUS.md`.
