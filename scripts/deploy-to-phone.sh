#!/usr/bin/env bash
# Deploy True North to the connected iPhone — the CLI equivalent of Xcode's Cmd-R
# to a device: regenerate the project, build+sign for the phone, install, launch.
#
# Usage:  scripts/deploy-to-phone.sh
# Requires: the iPhone plugged in (or on the same Wi-Fi, paired) and UNLOCKED to
# actually launch (install works while locked; launching an app needs it unlocked).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPDIR="$ROOT/app/BibleStory"
BID="com.graceyan.treasuretrail"
DERIVED="/tmp/bsdevice"

echo "▸ Finding a connected iPhone…"
xcrun devicectl list devices --json-output /tmp/tn-devices.json >/dev/null 2>&1 || true
read -r DEVID UDID < <(python3 - <<'PY'
import json
try:
    devs = json.load(open("/tmp/tn-devices.json"))["result"]["devices"]
except Exception:
    devs = []
for d in devs:
    hw = d.get("hardwareProperties", {})
    if hw.get("platform") == "iOS" and hw.get("udid"):
        print(d["identifier"], hw["udid"]); break
PY
)
if [ -z "${DEVID:-}" ]; then
    echo "✗ No connected iPhone found. Plug it in, unlock, and 'Trust' this Mac."; exit 1
fi
echo "  device: $DEVID  (udid $UDID)"

cd "$APPDIR"
echo "▸ xcodegen + build (signed for device)…"
xcodegen generate >/dev/null
xcodebuild -scheme BibleStory \
    -destination "platform=iOS,id=$UDID" \
    -derivedDataPath "$DERIVED" -allowProvisioningUpdates build >/tmp/tn-build.log 2>&1 \
    || { echo "✗ build failed — see /tmp/tn-build.log"; tail -20 /tmp/tn-build.log; exit 1; }

APP="$DERIVED/Build/Products/Debug-iphoneos/BibleStory.app"
echo "▸ Installing to phone…"
xcrun devicectl device install app --device "$DEVID" "$APP" >/dev/null

echo "▸ Launching (needs the phone unlocked)…"
if xcrun devicectl device process launch --device "$DEVID" --terminate-existing "$BID" >/dev/null 2>&1; then
    echo "✅ True North is running on your phone."
else
    echo "✅ Installed & updated. Unlock the phone and tap True North (launch needs it unlocked)."
fi
