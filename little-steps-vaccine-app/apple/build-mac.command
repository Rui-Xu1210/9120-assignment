#!/bin/zsh
set -eu
cd "$(dirname "$0")"
ROOT="$PWD"
OUTPUT="${1:-$ROOT/../../Little Steps.app}"
mkdir -p "$OUTPUT/Contents/MacOS" "$OUTPUT/Contents/Resources" "$ROOT/.build/module-cache"
swiftc -swift-version 5 -target "$(uname -m)-apple-macos14.0" \
  -module-cache-path "$ROOT/.build/module-cache" -O -parse-as-library \
  "$ROOT"/Sources/*.swift -o "$OUTPUT/Contents/MacOS/LittleSteps"
cp "$ROOT/Info.plist" "$OUTPUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Little Steps' "$OUTPUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable LittleSteps' "$OUTPUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier edu.coursework.littlesteps' "$OUTPUT/Contents/Info.plist"
if [[ -f "$ROOT/AppIcon.icns" ]]; then
  cp "$ROOT/AppIcon.icns" "$OUTPUT/Contents/Resources/AppIcon.icns"
  /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$OUTPUT/Contents/Info.plist"
fi
codesign --force --deep --sign - "$OUTPUT"
printf '\nMac app built: %s\nThis is a local ad-hoc build, not a notarized distribution.\n' "$OUTPUT"
