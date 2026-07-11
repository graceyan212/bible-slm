#!/bin/bash
# Poll with the cookie-free API (no Keychain prompt) until the IP block clears,
# then run the batched, cookie-authenticated yt-dlp fetch (one Keychain prompt)
# for the remaining Tim Gabe videos. Repeats up to 4 passes.
cd "$(dirname "$0")"
PROBE_ID="N0vlBuMggKc"
MAX_WAIT_MIN=240
waited=0

probe() {  # exit 0 == IP works again
  python3 - "$PROBE_ID" <<'PY'
import sys
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import IpBlocked, RequestBlocked
try:
    YouTubeTranscriptApi().fetch(sys.argv[1], languages=["en"]); print("OK"); sys.exit(0)
except (IpBlocked, RequestBlocked):
    print("BLOCKED"); sys.exit(1)
except Exception as e:
    print("OK-ish:", type(e).__name__); sys.exit(0)
PY
}

missing() {
  python3 - <<'PY'
import os, glob
rows=[l for l in open("tim-gabe_list.tsv",encoding="utf-8") if l.strip()]
have=len([f for f in glob.glob("tim-gabe/*.txt") if os.path.getsize(f)>200])
print(len(rows)-have)
PY
}

echo "[driver] waiting for IP block to clear (polling cookie-free API)..."
while (( waited < MAX_WAIT_MIN )); do
  if probe; then
    echo "[driver] IP cooled after ${waited} min"
    break
  fi
  echo "[driver] still blocked (${waited} min); sleeping 5 min"
  sleep 300
  waited=$(( waited + 5 ))
done

if (( waited >= MAX_WAIT_MIN )); then
  echo "[driver] gave up after ${MAX_WAIT_MIN} min still blocked"; exit 1
fi

for pass in 1 2 3 4; do
  echo "[driver] ===== batch pass $pass ====="
  python3 fetch_batch.py tim-gabe_list.tsv tim-gabe "Tim Gabe"
  m=$(missing)
  echo "[driver] missing after pass $pass: $m"
  [ "$m" -le 0 ] && break
  echo "[driver] cooling down 5 min before next pass"
  sleep 300
done
echo "[driver] DONE. final missing: $(missing)"
