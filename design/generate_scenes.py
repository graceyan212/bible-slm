#!/usr/bin/env python3
"""Generate the painted scroll illustrations for the Expedition map, via an
OpenAI-compatible image API (the project's TrueFoundry AI Gateway).

Data-driven: reads scene prompts from design/scenes.json (one entry per map
scroll) and writes one PNG per scene to design/assets/scenes/<id>.png. A shared
`style` string is prepended to every prompt so the whole set looks cohesive
("color only on the story stops" — the map itself stays neutral sepia).

Why this shape (matches eval/run_eval.py):
  TrueFoundry is an OpenAI-COMPATIBLE gateway, so we use the `openai` SDK pointed
  at your gateway base_url with a TrueFoundry token — NOT google-genai. Image
  generation goes through the OpenAI /images endpoints:
    - text-to-image  -> client.images.generate(...)
    - style-from-a-reference-image -> client.images.edit(model=..., image=[ref], ...)
  Gemini image models are not reliably exposed through the gateway; the
  guaranteed model is gpt-image-1 (it ALSO supports reference-image edits).

Config (env vars; first found wins — a .env file at repo root is auto-loaded):
  base_url : IMAGE_BASE_URL | TFY_BASE_URL | JUDGE_BASE_URL | OPENAI_BASE_URL
  api_key  : IMAGE_API_KEY  | TFY_API_KEY  | JUDGE_API_KEY  | OPENAI_API_KEY
  model    : IMAGE_MODEL    (default: openai-main/gpt-image-1)
  Model ids on TrueFoundry look like "<provider_account>/<model>" and are
  account-specific — run --list-models to see exactly what your key can reach.

Usage (from repo root):
  python3 design/generate_scenes.py --list-models        # discover your exact image model id
  python3 design/generate_scenes.py --dry-run            # print composed prompts, call nothing (no key needed)
  python3 design/generate_scenes.py                      # generate every scene
  python3 design/generate_scenes.py --only jesus_children,red_sea
  python3 design/generate_scenes.py --model openai-main/gpt-image-1 --size 1024x1024
  # Style-match to the existing hand-drawn map (uses /images/edits):
  python3 design/generate_scenes.py --style-ref docs/design-assets/expedition-map-reference.png

Setup:
  pip install openai            # already used by eval/run_eval.py
  echo 'IMAGE_BASE_URL=https://gateway.truefoundry.ai' >> .env   # or your org's .../api/llm/api/inference/openai
  echo 'IMAGE_API_KEY=tfy-...'  >> .env                          # TrueFoundry PAT/VAT (get from the LLM Playground "unified code snippet")
  echo 'IMAGE_MODEL=openai-main/gpt-image-1' >> .env             # confirm the exact id with --list-models
"""
import os, sys, json, base64, argparse, mimetypes, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_CONFIG = os.path.join(ROOT, "design", "scenes.json")
DEFAULT_OUT = os.path.join(ROOT, "design", "assets", "scenes")
DEFAULT_MODEL = "openai-main/gpt-image-1"


def load_dotenv(path=os.path.join(ROOT, ".env")):
    """Minimal .env loader (no dependency). Does not override real env vars."""
    if not os.path.exists(path):
        return
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip().strip('"').strip("'")
            os.environ.setdefault(k, v)


def first_env(*names, default=None):
    for n in names:
        v = os.environ.get(n)
        if v:
            return v
    return default


def resolve_config():
    base_url = first_env("IMAGE_BASE_URL", "TFY_BASE_URL", "JUDGE_BASE_URL", "OPENAI_BASE_URL")
    api_key = first_env("IMAGE_API_KEY", "TFY_API_KEY", "JUDGE_API_KEY", "OPENAI_API_KEY")
    model = first_env("IMAGE_MODEL", default=DEFAULT_MODEL)
    return base_url, api_key, model


def make_client(base_url, api_key):
    try:
        from openai import OpenAI
    except ImportError:
        sys.exit("ERROR: the 'openai' package is required. Run: pip install openai")
    if not api_key:
        sys.exit("ERROR: no API key found. Set IMAGE_API_KEY (or TFY_/JUDGE_/OPENAI_API_KEY), "
                 "e.g. in a .env file at the repo root. See --help.")
    # base_url may be None for real OpenAI; for TrueFoundry it must be set.
    return OpenAI(api_key=api_key, base_url=base_url or None)


def compose_prompt(cfg, scene):
    parts = [cfg.get("style", "").strip(), scene["prompt"].strip()]
    neg = cfg.get("negative", "").strip()
    if neg:
        parts.append(neg)
    return "  ".join(p for p in parts if p)


def save_image_item(item, path):
    """Write one images-API result (b64_json or url) to `path`."""
    b64 = getattr(item, "b64_json", None)
    url = getattr(item, "url", None)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if b64:
        with open(path, "wb") as f:
            f.write(base64.b64decode(b64))
    elif url:
        urllib.request.urlretrieve(url, path)
    else:
        raise RuntimeError("response item had neither b64_json nor url")
    return path


def generate_one(client, model, prompt, size, out_path, style_refs=None, aspect=None):
    """Text-to-image, or reference-conditioned edit when style_refs is given.

    Gemini image models ignore the OpenAI `size` param but honor an `aspect_ratio`
    passed via extra_body (e.g. "3:2" landscape to fit the story frames).
    """
    kw = {"model": model, "prompt": prompt, "n": 1}
    if aspect:
        kw["extra_body"] = {"aspect_ratio": aspect}
    else:
        kw["size"] = size
    if style_refs:
        files = [open(p, "rb") for p in style_refs]
        try:
            resp = client.images.edit(image=files, **kw)
        finally:
            for f in files:
                f.close()
    else:
        resp = client.images.generate(**kw)
    return save_image_item(resp.data[0], out_path)


def main():
    load_dotenv()
    ap = argparse.ArgumentParser(description="Generate map-scroll illustrations via an OpenAI-compatible image API.")
    ap.add_argument("--config", default=DEFAULT_CONFIG, help="scene config JSON (default design/scenes.json)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="output dir (default design/assets/scenes)")
    ap.add_argument("--only", help="comma-separated scene ids to generate (default: all)")
    ap.add_argument("--model", help="override image model id (else env IMAGE_MODEL / default)")
    ap.add_argument("--size", help="override image size, e.g. 1024x1024 / 1536x1024 / 1024x1536 (else config)")
    ap.add_argument("--aspect", help="Gemini aspect_ratio, e.g. 3:2 / 1:1 / 16:9 (else config aspect_ratio). Overrides --size for Gemini.")
    ap.add_argument("--style-ref", action="append", default=[],
                    help="path to a reference image for style conditioning (repeatable). Uses /images/edits.")
    ap.add_argument("--list-models", action="store_true", help="list model ids your key can reach, then exit")
    ap.add_argument("--dry-run", action="store_true", help="print composed prompts and exit; call nothing")
    args = ap.parse_args()

    base_url, api_key, env_model = resolve_config()
    model = args.model or env_model

    with open(args.config) as f:
        cfg = json.load(f)
    size = args.size or cfg.get("size", "1024x1024")
    aspect = args.aspect or cfg.get("aspect_ratio")
    scenes = cfg.get("scenes", [])
    if args.only:
        wanted = {s.strip() for s in args.only.split(",")}
        scenes = [s for s in scenes if s["id"] in wanted]
        missing = wanted - {s["id"] for s in scenes}
        if missing:
            print(f"WARN: unknown scene id(s): {', '.join(sorted(missing))}", file=sys.stderr)

    if args.dry_run:
        print(f"# DRY RUN — model={model}  aspect={aspect or size}  style_refs={args.style_ref or 'none'}")
        print(f"# base_url={base_url or '(default OpenAI)'}  key={'set' if api_key else 'MISSING'}\n")
        for s in scenes:
            print(f"=== {s['id']} — {s.get('title','')} ===")
            print(compose_prompt(cfg, s))
            print()
        print(f"{len(scenes)} scene(s). Remove --dry-run to generate.")
        return

    client = make_client(base_url, api_key)

    if args.list_models:
        try:
            ids = sorted(m.id for m in client.models.list().data)
        except Exception as e:
            sys.exit(f"ERROR listing models: {e}")
        print(f"# {len(ids)} model(s) reachable via {base_url or 'OpenAI'}:")
        for mid in ids:
            mark = "  <- image?" if any(k in mid.lower() for k in ("image", "dall", "imagen", "canvas", "banana")) else ""
            print(f"  {mid}{mark}")
        return

    for f in args.style_ref:
        if not os.path.exists(f):
            sys.exit(f"ERROR: --style-ref not found: {f}")

    print(f"Generating {len(scenes)} scene(s)  model={model}  {'aspect=' + aspect if aspect else 'size=' + size}"
          f"{'  (style-ref: ' + ', '.join(args.style_ref) + ')' if args.style_ref else ''}")
    ok, fail = [], []
    for s in scenes:
        out_path = os.path.join(args.out, f"{s['id']}.png")
        prompt = compose_prompt(cfg, s)
        try:
            generate_one(client, model, prompt, size, out_path, style_refs=args.style_ref or None, aspect=aspect)
            print(f"  OK  {s['id']:16s} -> {os.path.relpath(out_path, ROOT)}")
            ok.append(s["id"])
        except Exception as e:
            print(f"  ERR {s['id']:16s} {type(e).__name__}: {e}", file=sys.stderr)
            fail.append(s["id"])

    print(f"\nDone: {len(ok)} ok, {len(fail)} failed."
          + (f" Failed: {', '.join(fail)}" if fail else ""))
    if fail:
        sys.exit(1)


if __name__ == "__main__":
    main()
