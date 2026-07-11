#!/usr/bin/env python3
"""Convert gallery-dl `-j` (dump-json) output into clean per-account text files.

Groups tweets into threads by conversation_id, orders chronologically, strips
media-only duplicate items, and writes one .txt per account with a header and
lightweight engagement stats. Retweets are dropped (originals only).

Usage: python3 x_to_text.py <gallerydl_dump.json> <outdir>
"""
import os
import re
import sys
import json
from collections import defaultdict


def slugify(s, maxlen=50):
    s = re.sub(r"[^\w\s-]", "", s or "", flags=re.UNICODE).strip()
    s = re.sub(r"[\s_-]+", "-", s)
    return s[:maxlen].strip("-") or "x"


def load_tweets(dump_path, only_handle=None):
    """Return dict handle -> {tweet_id -> tweet-meta}, de-duped, no retweets.

    If only_handle is given, keep only tweets authored by that handle (used with
    conversation-mode dumps, which also contain other users' replies).
    """
    with open(dump_path, encoding="utf-8") as f:
        data = json.load(f)
    by_user = defaultdict(dict)
    for item in data:
        if not (isinstance(item, list) and len(item) >= 3):
            continue
        m = item[2]
        if not isinstance(m, dict) or "content" not in m:
            continue
        if m.get("retweet_id"):            # drop retweets, keep originals
            continue
        handle = (m.get("author") or {}).get("name") or m.get("user", {}).get("name") or "unknown"
        if only_handle and handle.lower() != only_handle.lower():
            continue
        tid = m.get("tweet_id")
        if tid is None:
            continue
        # a tweet can appear once per media item; keep a single copy
        by_user[handle][tid] = m
    return by_user


def render_user(handle, tweets):
    nick = ""
    for m in tweets.values():
        nick = (m.get("author") or {}).get("nick") or ""
        break
    lines = [f"@{handle}" + (f"  ({nick})" if nick else ""),
             f"https://x.com/{handle}",
             f"tweets captured: {len(tweets)}",
             "=" * 70, ""]

    # group into threads by conversation_id
    threads = defaultdict(list)
    for m in tweets.values():
        threads[m.get("conversation_id") or m.get("tweet_id")].append(m)

    # order threads by the date of their earliest tweet (newest first)
    def thread_key(tw):
        return min((t.get("date") or "") for t in tw)
    ordered = sorted(threads.values(), key=thread_key, reverse=True)

    for tw in ordered:
        tw.sort(key=lambda t: (t.get("date") or "", t.get("tweet_id") or 0))
        head = tw[0]
        is_thread = len(tw) > 1
        date = (head.get("date") or "")[:10]
        eng = (f"♥{head.get('favorite_count',0)} "
               f"↻{head.get('retweet_count',0)} "
               f"💬{head.get('reply_count',0)} "
               f"👁{head.get('view_count',0)}")
        lines.append(f"--- {date} {'[THREAD]' if is_thread else ''} {eng}".rstrip())
        lines.append(f"https://x.com/{handle}/status/{head.get('tweet_id')}")
        for i, t in enumerate(tw):
            txt = (t.get("content") or "").strip()
            if not txt:
                continue
            if is_thread:
                lines.append(f"[{i+1}/{len(tw)}] {txt}")
            else:
                lines.append(txt)
        lines.append("")
    return "\n".join(lines)


def main():
    dump, outdir = sys.argv[1], sys.argv[2]
    only_handle = sys.argv[3] if len(sys.argv) > 3 else None
    os.makedirs(outdir, exist_ok=True)
    by_user = load_tweets(dump, only_handle)
    if not by_user:
        print(f"[convert] no tweets found in {dump}")
        return
    for handle, tweets in sorted(by_user.items(), key=lambda kv: -len(kv[1])):
        path = os.path.join(outdir, f"{slugify(handle)}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(render_user(handle, tweets))
        print(f"[convert] @{handle}: {len(tweets)} tweets -> {os.path.basename(path)}")


if __name__ == "__main__":
    main()
