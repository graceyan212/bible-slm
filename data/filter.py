#!/usr/bin/env python3
"""Deterministic quality gate + merge for the SBC kids' Bible SFT data.

Reads all data/gen/*.jsonl (teacher batches), applies the deterministic layers of the
Quality Gate (schema, verse-regex, dedup, train/eval disjointness), and writes the kept
records to data/train_v2.jsonl. Pure stdlib (no deps).

The LLM-judge + claim-contradiction layers and human review are NOT done here (they need
the judge harness / a reviewer) — this handles everything mechanical. Re-runnable.

Usage:  python3 data/filter.py            # from repo root
"""
import json, glob, re, os, sys, collections, difflib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEN_GLOB = os.path.join(ROOT, "data", "gen", "*.jsonl")
OUT = os.path.join(ROOT, "data", "train_v2.jsonl")
CLAIMS = os.path.join(ROOT, "data", "bfm_claims.json")
EVAL = os.path.join(ROOT, "eval", "scenarios.json")

REQUIRED = ["tier", "behavior_class", "topic", "claim_ids", "messages"]
TIERS = {"closed", "open", "deflect", "na"}
CLASSES = {"hold", "acknowledge", "deflect", "safe_core", "benign_offtopic", "adversarial", "danger"}

# chapter:verse reference, e.g. "John 3:16", "1 Cor 6:19", "Genesis 1:1"
VERSE_RE = re.compile(r"\b(?:[1-3]\s?)?[A-Z][a-z]+\.?\s?\d{1,3}:\d{1,3}\b")

def norm(s):
    return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()

def first_user(rec):
    for m in rec.get("messages", []):
        if m.get("role") == "user":
            return m.get("content", "")
    return ""

def assistant_text(rec):
    return " ".join(m.get("content", "") for m in rec.get("messages", []) if m.get("role") == "assistant")

def validate_schema(rec):
    for k in REQUIRED:
        if k not in rec:
            return f"missing:{k}"
    if rec["tier"] not in TIERS:
        return f"bad_tier:{rec['tier']}"
    if rec["behavior_class"] not in CLASSES:
        return f"bad_class:{rec['behavior_class']}"
    if not isinstance(rec["claim_ids"], list):
        return "claim_ids_not_list"
    msgs = rec.get("messages")
    if not isinstance(msgs, list) or len(msgs) < 3:
        return "messages_too_short"
    if msgs[0].get("role") != "system":
        return "no_system_first"
    roles = [m.get("role") for m in msgs[1:]]
    if roles[0] != "user" or roles[-1] != "assistant":
        return "bad_turn_order"
    if any(not m.get("content", "").strip() for m in msgs):
        return "empty_message"
    return None

def main():
    claim_ids = {c["claim_id"] for c in json.load(open(CLAIMS))["claims"]}
    eval_turns = []
    for s in json.load(open(EVAL))["scenarios"]:
        eval_turns += [norm(t) for t in s["turns"]]

    raw, cuts = [], collections.Counter()
    files = sorted(glob.glob(GEN_GLOB))
    if not files:
        print("No batches found in data/gen/*.jsonl — nothing to merge yet."); sys.exit(0)

    for fp in files:
        for i, line in enumerate(open(fp), 1):
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except Exception:
                cuts["bad_json"] += 1; continue
            raw.append((os.path.basename(fp), i, rec))

    kept, seen_norms = [], []
    for src, ln, rec in raw:
        err = validate_schema(rec)
        if err:
            cuts[f"schema:{err}"] += 1; continue
        bad = [c for c in rec["claim_ids"] if c not in claim_ids]
        if bad:
            cuts["unknown_claim_id"] += 1; continue
        atext = assistant_text(rec)
        if VERSE_RE.search(atext):
            cuts["verbatim_verse"] += 1; continue
        u = norm(first_user(rec))
        if not u:
            cuts["empty_user"] += 1; continue
        # train/eval disjointness
        if any(difflib.SequenceMatcher(None, u, e).ratio() > 0.90 for e in eval_turns):
            cuts["eval_leak"] += 1; continue
        # near-duplicate within kept set
        if any(difflib.SequenceMatcher(None, u, k).ratio() > 0.92 for k in seen_norms):
            cuts["near_dup"] += 1; continue
        seen_norms.append(u)
        # recompute turns from messages
        rec["turns"] = sum(1 for m in rec["messages"] if m.get("role") == "user")
        kept.append(rec)

    with open(OUT, "w") as f:
        for rec in kept:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")

    print(f"batches: {len(files)} | raw records: {len(raw)} | KEPT: {len(kept)} -> {os.path.relpath(OUT, ROOT)}")
    print("cuts:", dict(cuts) or "none")
    print("kept by behavior_class:", dict(collections.Counter(r["behavior_class"] for r in kept)))
    print("kept by tier:", dict(collections.Counter(r["tier"] for r in kept)))
    print("kept by topic:", dict(collections.Counter(r["topic"] for r in kept)))
    mt = sum(1 for r in kept if r["turns"] > 1)
    print(f"multi-turn kept: {mt} ({100*mt//max(len(kept),1)}%)")
    review = sum(1 for r in kept if r.get("review") == "human")
    print(f"records needing human review (danger/complementarian): {review}")
    print("\nNOTE: deterministic gate only. Remaining gate steps: LLM-judge on-spec filter,")
    print("tier-aware claim-contradiction check, and human review of the review=human rows.")

if __name__ == "__main__":
    main()
