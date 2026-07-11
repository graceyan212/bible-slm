#!/usr/bin/env python3
"""Fetch English transcripts for a channel's videos.

Reads a <name>_list.tsv (id<TAB>title per line), writes one clean .txt per
video into <outdir>/<##>_<slug>_<id>.txt with the title and watch URL as the
first two lines. Prefers youtube-transcript-api; falls back to yt-dlp
auto-subs (VTT -> de-duplicated plain text) when the api errors or is
rate-limited.
"""
import os
import re
import sys
import glob
import time
import subprocess
import tempfile

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import (
    TranscriptsDisabled,
    NoTranscriptFound,
    VideoUnavailable,
    IpBlocked,
    RequestBlocked,
)

API = YouTubeTranscriptApi()


def slugify(title, maxlen=60):
    s = re.sub(r"[^\w\s-]", "", title, flags=re.UNICODE).strip()
    s = re.sub(r"[\s_-]+", "-", s)
    return s[:maxlen].strip("-") or "untitled"


def clean_api_text(fetched):
    """Join transcript snippets into paragraphs, stripping timestamps."""
    lines = [seg.text.strip() for seg in fetched if seg.text.strip()]
    return "\n".join(lines)


def vtt_to_text(vtt_path):
    """Convert a WebVTT auto-caption file to de-duplicated plain text."""
    with open(vtt_path, encoding="utf-8") as f:
        raw = f.read()
    out = []
    seen_last = None
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith(("WEBVTT", "Kind:", "Language:")):
            continue
        # timestamp cue lines, e.g. 00:00:01.000 --> 00:00:03.000 ...
        if "-->" in line:
            continue
        if re.fullmatch(r"\d+", line):  # sequence numbers
            continue
        # strip inline timing tags <00:00:00.000> and <c> ... </c>
        line = re.sub(r"<[^>]+>", "", line).strip()
        if not line:
            continue
        # de-dup rolling auto-caption repeats
        if line == seen_last:
            continue
        # also skip if this line is contained in the previous (rolling window)
        if seen_last and line in seen_last:
            continue
        out.append(line)
        seen_last = line
    return "\n".join(out)


def fetch_via_ytdlp(video_id):
    """Return plain text from yt-dlp auto-subs, or None."""
    with tempfile.TemporaryDirectory() as td:
        cmd = [
            sys.executable, "-m", "yt_dlp",
            "--skip-download", "--write-auto-subs", "--write-subs",
            "--sub-langs", "en.*", "--sub-format", "vtt",
            "-o", os.path.join(td, "%(id)s.%(ext)s"),
            f"https://www.youtube.com/watch?v={video_id}",
        ]
        subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        vtts = glob.glob(os.path.join(td, "*.vtt"))
        if not vtts:
            return None
        # prefer manual en subs over auto if both present
        vtts.sort(key=lambda p: ("auto" in p, p))
        text = vtt_to_text(vtts[0])
        return text or None


class Blocked(Exception):
    pass


def fetch_transcript(video_id):
    """Return (text, method). Raises Blocked on IP block, RuntimeError otherwise."""
    blocked = False
    try:
        fetched = API.fetch(video_id, languages=["en", "en-US", "en-GB"])
        text = clean_api_text(fetched)
        if text:
            return text, "api"
    except (IpBlocked, RequestBlocked):
        blocked = True
    except (TranscriptsDisabled, NoTranscriptFound, VideoUnavailable):
        # genuinely no transcript via api -> try yt-dlp auto-subs
        pass
    except Exception:
        # network / parse issues -> fall back to yt-dlp
        pass
    text = fetch_via_ytdlp(video_id)
    if text:
        return text, "yt-dlp"
    if blocked:
        raise Blocked("IP blocked by YouTube")
    raise RuntimeError("no transcript from api or yt-dlp")


def main():
    list_file, outdir, channel_name = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(outdir, exist_ok=True)
    with open(list_file, encoding="utf-8") as f:
        rows = [ln.rstrip("\n").split("|||", 1) for ln in f if ln.strip()]

    base_sleep = float(os.environ.get("SLEEP", "2.0"))
    max_block_backoff = 300  # cap single backoff at 5 min

    saved, failed = [], []
    for i, row in enumerate(rows, 1):
        vid = row[0]
        title = row[1] if len(row) > 1 else vid
        url = f"https://www.youtube.com/watch?v={vid}"
        fname = f"{i:02d}_{slugify(title)}_{vid}.txt"
        path = os.path.join(outdir, fname)
        if os.path.exists(path) and os.path.getsize(path) > 200:
            print(f"[{i}/{len(rows)}] skip (exists) {title[:50]}", flush=True)
            saved.append((title, "cached"))
            continue

        # retry with exponential backoff on IP block
        attempt, backoff, done = 0, 30, False
        while not done:
            try:
                text, method = fetch_transcript(vid)
                with open(path, "w", encoding="utf-8") as out:
                    out.write(f"{title}\n{url}\n\n{text}\n")
                print(f"[{i}/{len(rows)}] ok ({method}) {title[:50]}", flush=True)
                saved.append((title, method))
                done = True
            except Blocked:
                attempt += 1
                if attempt > 4:
                    print(f"[{i}/{len(rows)}] FAIL (blocked, gave up) {title[:50]}", flush=True)
                    failed.append((title, vid, "IP blocked"))
                    done = True
                else:
                    wait = min(backoff * attempt, max_block_backoff)
                    print(f"[{i}/{len(rows)}] blocked, backoff {wait}s (attempt {attempt}) {title[:40]}", flush=True)
                    time.sleep(wait)
            except Exception as e:
                print(f"[{i}/{len(rows)}] FAIL {title[:50]} :: {e}", flush=True)
                failed.append((title, vid, str(e)))
                done = True
        time.sleep(base_sleep)  # be gentle

    print(f"\n===== {channel_name} summary =====")
    print(f"videos found:      {len(rows)}")
    print(f"transcripts saved: {len(saved)}")
    print(f"failed:            {len(failed)}")
    for title, vid, why in failed:
        print(f"  - {title[:60]} ({vid}): {why}")


if __name__ == "__main__":
    main()
