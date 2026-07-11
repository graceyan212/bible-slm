#!/usr/bin/env python3
"""Batched, cookie-authenticated transcript fetch for the still-missing videos.

Runs yt-dlp ONCE over all missing videos (one Brave-cookie read => at most one
Keychain prompt), paced with --sleep-* to avoid re-triggering the IP throttle,
then converts each VTT to clean text with title + URL headers.

Usage: python3 fetch_batch.py <list.tsv> <outdir> "<Channel Name>"
"""
import os
import re
import sys
import glob
import subprocess
import tempfile

# reuse the cleaners from the main script
from fetch_transcripts import slugify, vtt_to_text


def missing_rows(list_file, outdir):
    with open(list_file, encoding="utf-8") as f:
        rows = [ln.rstrip("\n").split("|||", 1) for ln in f if ln.strip()]
    out = []
    for i, row in enumerate(rows, 1):
        vid = row[0]
        title = row[1] if len(row) > 1 else vid
        fname = f"{i:02d}_{slugify(title)}_{vid}.txt"
        path = os.path.join(outdir, fname)
        if os.path.exists(path) and os.path.getsize(path) > 200:
            continue
        out.append((i, vid, title, path))
    return rows, out


def main():
    list_file, outdir, channel = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(outdir, exist_ok=True)
    all_rows, todo = missing_rows(list_file, outdir)
    if not todo:
        print(f"[batch] nothing missing for {channel}")
        return
    print(f"[batch] {channel}: {len(todo)} missing of {len(all_rows)}")

    with tempfile.TemporaryDirectory() as td:
        batch = os.path.join(td, "urls.txt")
        with open(batch, "w") as f:
            for _, vid, _, _ in todo:
                f.write(f"https://www.youtube.com/watch?v={vid}\n")

        cmd = [
            sys.executable, "-m", "yt_dlp",
            "--cookies-from-browser", "brave",
            "--skip-download", "--write-auto-subs", "--write-subs",
            "--sub-langs", "en.*", "--sub-format", "vtt",
            "--sleep-requests", "2",           # pace metadata requests
            "--sleep-subtitles", "2",          # pace subtitle downloads
            "--retries", "15", "--extractor-retries", "5",
            "--retry-sleep", "http:exp=2:120",  # backoff on 429 up to 120s
            "--ignore-errors",                  # keep going past failures
            "-o", os.path.join(td, "%(id)s.%(ext)s"),
            "--batch-file", batch,
        ]
        print("[batch] running yt-dlp over the batch (this reads Brave cookies once)...")
        subprocess.run(cmd)

        saved, failed = [], []
        for idx, vid, title, path in todo:
            url = f"https://www.youtube.com/watch?v={vid}"
            vtts = glob.glob(os.path.join(td, f"{vid}.*.vtt"))
            vtts.sort(key=lambda p: ("auto" in p, p))  # prefer manual over auto
            text = vtt_to_text(vtts[0]) if vtts else None
            if text:
                with open(path, "w", encoding="utf-8") as out:
                    out.write(f"{title}\n{url}\n\n{text}\n")
                saved.append(title)
            else:
                failed.append((title, vid))

    print(f"\n===== {channel} batch summary =====")
    print(f"attempted: {len(todo)}  saved: {len(saved)}  still failed: {len(failed)}")
    for title, vid in failed:
        print(f"  - {title[:60]} ({vid})")


if __name__ == "__main__":
    main()
