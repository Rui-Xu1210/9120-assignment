from pathlib import Path
import json
import subprocess
import tempfile
import struct


root = Path(__file__).resolve().parent
source = root.parent / "frontend" / "icon-512.png"
assets = root / "Assets.xcassets"
appicon = assets / "AppIcon.appiconset"
appicon.mkdir(parents=True, exist_ok=True)
(assets / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2))
images = []
with tempfile.TemporaryDirectory() as temporary:
    iconset = Path(temporary) / "AppIcon.iconset"
    iconset.mkdir()
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            filename = f"icon_{size}x{size}" + ("@2x" if scale == 2 else "") + ".png"
            target = iconset / filename
            pixels = str(size * scale)
            subprocess.run(["sips", "-z", pixels, pixels, str(source), "--out", str(target)], check=True, capture_output=True)
            destination = appicon / filename
            destination.write_bytes(target.read_bytes())
            images.append({"idiom": "mac", "size": f"{size}x{size}", "scale": f"{scale}x", "filename": filename})
    chunks = []
    for identifier, filename in [(b"icp4", "icon_16x16.png"), (b"icp5", "icon_32x32.png"), (b"icp6", "icon_32x32@2x.png"), (b"ic07", "icon_128x128.png"), (b"ic08", "icon_256x256.png"), (b"ic09", "icon_512x512.png"), (b"ic10", "icon_512x512@2x.png")]:
        payload = (iconset / filename).read_bytes()
        chunks.append(identifier + struct.pack(">I", len(payload) + 8) + payload)
    payload = b"".join(chunks)
    (root / "AppIcon.icns").write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)
    phone_icon = appicon / "ios-1024.png"
    subprocess.run(["sips", "-z", "1024", "1024", str(source), "--out", str(phone_icon)], check=True, capture_output=True)
    images.append({"idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": phone_icon.name})
(appicon / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2))
print("Created native Mac and iOS app icons from the existing project icon.")
