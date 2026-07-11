#!/usr/bin/env python3
"""Build César's onboarding-breakdown corpus: caption + OCR'd screen text.

Reads the raw timeline JSON for captions/metadata, OCRs downloaded images
(and any extracted video frames) with macOS Vision, groups everything by
tweet, and writes one readable corpus file newest-first.

Usage: python3 build_cesar_corpus.py
"""
import os
import re
import glob
import json
from collections import defaultdict
from ocr_vision import ocr_image

RAW = "raw/cesaralvarezll.json"
IMG_DIR = "media/twitter/cesaralvarezll"
FRAME_DIR = "video_frames"          # <tweet_id>/frame_*.jpg (deduped OCR text)
OUT = "accounts/cesaralvarezll_BREAKDOWNS.txt"


def load_meta():
    d = json.load(open(RAW, encoding="utf-8"))
    meta = {}
    for it in d:
        if isinstance(it, list) and len(it) >= 3 and isinstance(it[2], dict) and "content" in it[2]:
            m = it[2]
            meta.setdefault(m.get("tweet_id"), m)
    return meta


def tid_from_name(path):
    m = re.match(r"(\d+)_", os.path.basename(path))
    return int(m.group(1)) if m else None


def dedup_lines(blocks):
    """Merge OCR text blocks, dropping consecutive/again-seen duplicate lines."""
    seen, out = set(), []
    for block in blocks:
        for ln in block.splitlines():
            ln = ln.strip()
            if len(ln) < 2:
                continue
            key = ln.lower()
            if key in seen:
                continue
            seen.add(key)
            out.append(ln)
    return out


def main():
    meta = load_meta()

    # OCR images, grouped by tweet
    img_text = defaultdict(list)
    imgs = sorted(glob.glob(os.path.join(IMG_DIR, "*.jpg")))
    print(f"[corpus] OCR {len(imgs)} images...")
    for i, p in enumerate(imgs, 1):
        tid = tid_from_name(p)
        if tid is None:
            continue
        img_text[tid].append(ocr_image(p))
        if i % 50 == 0:
            print(f"  ...{i}/{len(imgs)}")

    # video-frame OCR text, if any frames were extracted+OCR'd already
    frame_text = {}
    if os.path.isdir(FRAME_DIR):
        for tdir in glob.glob(os.path.join(FRAME_DIR, "*")):
            tid = int(os.path.basename(tdir)) if os.path.basename(tdir).isdigit() else None
            if tid is None:
                continue
            blocks = [ocr_image(f) for f in sorted(glob.glob(os.path.join(tdir, "*.jpg")))]
            frame_text[tid] = dedup_lines(blocks)

    # emit newest-first over every tweet that has caption or any OCR text
    all_tids = set(meta) | set(img_text) | set(frame_text)
    rows = sorted(all_tids, key=lambda t: (meta.get(t, {}).get("date") or ""), reverse=True)

    n_img = n_vid = 0
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("@cesaralvarezll — onboarding/paywall breakdowns\n")
        f.write("caption + OCR'd on-screen text (images + sampled video frames)\n")
        f.write("=" * 70 + "\n\n")
        for tid in rows:
            m = meta.get(tid, {})
            caption = (m.get("content") or "").strip()
            date = (m.get("date") or "")[:10]
            views = m.get("view_count") or 0
            has_img = tid in img_text
            has_vid = tid in frame_text
            if not (caption or has_img or has_vid):
                continue
            kind = "VIDEO" if has_vid else ("IMAGE" if has_img else "TEXT")
            f.write(f"--- {date} [{kind}] {views} views\n")
            f.write(f"https://x.com/cesaralvarezll/status/{tid}\n")
            if caption:
                f.write(f"CAPTION: {caption}\n")
            if has_img:
                n_img += 1
                screen = "\n".join(dedup_lines(img_text[tid]))
                if screen.strip():
                    f.write(f"SCREEN TEXT (image):\n{screen}\n")
            if has_vid:
                n_vid += 1
                f.write("SCREEN TEXT (video frames):\n" + "\n".join(frame_text[tid]) + "\n")
            f.write("\n")
    print(f"[corpus] wrote {OUT}: {n_img} image-tweets, {n_vid} video-tweets")


if __name__ == "__main__":
    main()
