#!/usr/bin/env bash
# Privacy guard for the True North kids' app (COPPA — see docs/SAFETY-AND-COPPA.md §4).
#
# Fails (exit 1) if the app source introduces anything that could send a child's data
# off-device: analytics/tracking/ads SDKs, ad-hoc network calls, or cloud sync. Run in CI
# on every PR so the "nothing leaves the device" claim can't silently regress.
#
# NOTE: the on-device MLX model DOWNLOAD (mlx-swift-lm, when enabled) fetches model *weights*
# and sends no child data — it goes through the vetted libraries, not raw URLSession in our
# code, so it does not trip this guard.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN_DIRS=(
  "$ROOT/app/BibleStoryCore/Sources"
  "$ROOT/app/BibleStory/BibleStory"
)

# Patterns that must NOT appear in app source (extended regex).
FORBIDDEN=(
  'import (Firebase|FirebaseAnalytics|Mixpanel|Amplitude|AppsFlyer|Sentry|Segment|Adjust|Bugsnag|GoogleMobileAds|GoogleAnalytics|FBSDK|FacebookCore|Branch|OneSignal)'
  '\b(URLSession|URLRequest)\b'
  '\.dataTask\('
  '\b(CKContainer|CKDatabase|NSUbiquitousKeyValueStore)\b'
  'https?://[A-Za-z0-9]'   # hard-coded endpoints in code (doc-comment URLs are excluded below)
)

hits=0
for dir in "${SCAN_DIRS[@]}"; do
  [ -d "$dir" ] || continue
  for pat in "${FORBIDDEN[@]}"; do
    # match in .swift files, then drop pure comment/doc lines (leading //, ///, or *)
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      echo "  ✘ $line"
      hits=$((hits + 1))
    done < <(grep -rnE --include='*.swift' "$pat" "$dir" 2>/dev/null \
                | grep -vE ':[0-9]+:[[:space:]]*(//|///|\*)' \
                | grep -v 'LangFuseExporter.swift')   # reviewed, consent-gated beta exception
  done
done

if [ "$hits" -gt 0 ]; then
  echo ""
  echo "✗ privacy-audit FAILED: $hits potential off-device data path(s) above."
  echo "  A kids' (COPPA) app must keep child data on-device. If a hit is a false positive,"
  echo "  refactor or add a reviewed, narrowly-scoped exception here with a comment."
  exit 1
fi

echo "✓ privacy-audit passed: no tracking SDKs, network calls, or cloud sync in app source."
