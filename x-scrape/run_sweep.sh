#!/bin/bash
# Scrape each X account's timeline via Firefox (throwaway) cookies, one per file.
# Conservative pacing; César deepest (the requirement), acquisition accounts light.
cd "$(dirname "$0")"
mkdir -p raw

# handle:range  (César first = the requirement; acquisition accounts lighter)
ACCTS=(
  "cesaralvarezll:500"
  "filippkowalski:250"
  "yasirmohiuddin:250"
  "YoniSmolyar:250"
  "ZachYadegari:250"
  "athcanft:250"
  "alexcooldev:250"
  "jaxxdwyer:120"
  "LukasPakter:120"
  "adriamatz:120"
)

for entry in "${ACCTS[@]}"; do
  handle="${entry%%:*}"; range="${entry##*:}"
  echo "=== @$handle (range 1-$range) ==="
  python3 -m gallery_dl --cookies-from-browser firefox -j \
    -o extractor.twitter.text-tweets=true \
    --sleep-request 2.0 --range "1-$range" \
    "https://x.com/$handle/timeline" > "raw/$handle.json" 2> "raw/$handle.err"
  n=$(python3 -c "
import json,sys
try:
    d=json.load(open('raw/$handle.json'))
    print(sum(1 for it in d if isinstance(it,list) and len(it)>=3 and isinstance(it[2],dict) and 'content' in it[2]))
except: print('ERR')
")
  echo "    -> $n metadata items ($(grep -c 'guest token' raw/$handle.err 2>/dev/null | tr -d ' ') guest-token warnings)"
  sleep 3   # gap between accounts
done
echo "=== sweep done ==="
