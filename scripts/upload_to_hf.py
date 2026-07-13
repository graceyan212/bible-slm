#!/usr/bin/env python3
"""
Push the True North model to the Hugging Face Hub.

Uploads the merged fp16 model to the repo root, the LoRA adapter to an
`adapter/` subfolder (if present), and MODEL_CARD.md as the repo README.

Prereqs
-------
    pip install -U "huggingface_hub>=1.0"
    export HF_TOKEN=hf_xxx          # a WRITE token from https://huggingface.co/settings/tokens

Run
---
    # merged only (adapter still on your Drive? upload it later with --adapter)
    python scripts/upload_to_hf.py --repo graceyan212/true-north-sbc-kids-4b

    # merged + adapter in one go
    python scripts/upload_to_hf.py --repo graceyan212/true-north-sbc-kids-4b \
        --merged ./sbc-merged --adapter ./sbc-lora
"""
import argparse
import os
import sys

from huggingface_hub import HfApi


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="e.g. graceyan212/true-north-sbc-kids-4b")
    ap.add_argument("--merged", default="./sbc-merged", help="merged fp16 model dir")
    ap.add_argument("--adapter", default=None, help="LoRA adapter dir (optional)")
    ap.add_argument("--card", default="./MODEL_CARD.md")
    ap.add_argument("--private", action="store_true", help="create the repo private")
    ap.add_argument("--token", default=os.environ.get("HF_TOKEN"))
    args = ap.parse_args()

    if not args.token:
        sys.exit("No token. Set HF_TOKEN (a WRITE token) or pass --token.")
    if not os.path.isdir(args.merged):
        sys.exit(f"Merged model dir not found: {args.merged}")

    api = HfApi(token=args.token)
    api.create_repo(args.repo, repo_type="model", exist_ok=True, private=args.private)
    print(f"repo ready: https://huggingface.co/{args.repo}")

    # 1) merged model → root (8GB; upload_large_folder resumes on flaky connections)
    print(f"uploading merged model from {args.merged} …")
    api.upload_large_folder(repo_id=args.repo, repo_type="model", folder_path=args.merged)

    # 2) adapter → adapter/ subfolder
    if args.adapter:
        if not os.path.isdir(args.adapter):
            sys.exit(f"--adapter given but dir not found: {args.adapter}")
        print(f"uploading adapter from {args.adapter} → adapter/ …")
        api.upload_folder(repo_id=args.repo, repo_type="model",
                          folder_path=args.adapter, path_in_repo="adapter")

    # 3) model card → README.md
    if os.path.isfile(args.card):
        print("uploading model card → README.md …")
        api.upload_file(path_or_fileobj=args.card, path_in_repo="README.md",
                        repo_id=args.repo, repo_type="model")

    print(f"\n✅ done → https://huggingface.co/{args.repo}")
    if not args.adapter:
        print("   (adapter not uploaded — rerun with --adapter ./sbc-lora once you have it from Drive)")


if __name__ == "__main__":
    main()
