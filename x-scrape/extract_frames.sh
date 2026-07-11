#!/bin/bash
# Extract distinct screens from each downloaded video using scene-change
# detection (so we OCR each onboarding screen once, not every frame).
cd "$(dirname "$0")"
mkdir -p video_frames
shopt -s nullglob 2>/dev/null

for mp4 in media/twitter/cesaralvarezll/*.mp4; do
  base=$(basename "$mp4" .mp4)          # e.g. 2036500649446105307_1
  tid="${base%%_*}"                      # tweet id
  outdir="video_frames/$tid"
  mkdir -p "$outdir"
  # sample one frame every 2s (reliable coverage); OCR text-dedup removes
  # redundant screens downstream. Scale down for faster OCR.
  ffmpeg -y -loglevel error -i "$mp4" \
    -vf "fps=1/2,scale=720:-1" \
    "$outdir/frame_%03d.jpg" </dev/null
  n=$(ls "$outdir"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
  echo "  $tid -> $n distinct screens"
done
echo "=== frame extraction done ==="
