#!/usr/bin/env python3
"""Regenerate story-page art with a CONSISTENT recurring character, driven by a small
JSON config. See design/ART-GUIDELINES.md.

Config JSON:
{
  "anchor": "app/.../Story<X>P1.imageset/<x>_p1.png",   # canonical character reference (kept as-is)
  "character": "Jesus = long wavy brown hair..., cream robe + tan sash, sandals",  # locked description
  "targets": {                                             # pages to regenerate → scene prompt
    "app/.../Story<X>P2.imageset/<x>_p2.png": "Scene: ...",
    "app/.../Story<X>P3.imageset/<x>_p3.png": "Scene: ..."
  }
}

Each target is generated with client.images.edit(image=[anchor], prompt=STYLE+character+scene),
so the model keeps the anchor's character design while drawing the new scene.

Run:  python3 design/regen_story.py --config /tmp/<story>.json
"""
import os, sys, json, base64, argparse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STYLE = (
    "Children's Bible storybook illustration for ages 7-9: soft flat cartoon with clean dark "
    "outlines and gentle watercolor shading, warm and bright. The scene FILLS the whole frame "
    "edge to edge with NO border and NO text. Match the art style and the EXACT character "
    "design of the reference image (same faces, hair, skin, clothing colors, proportions). "
)


def env(*names):
    for n in names:
        if os.environ.get(n): return os.environ[n]
    return None


def load_dotenv():
    p = os.path.join(ROOT, ".env")
    if os.path.exists(p):
        for line in open(p):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    args = ap.parse_args()
    load_dotenv()
    cfg = json.load(open(args.config))
    anchor = cfg["anchor"] if os.path.isabs(cfg["anchor"]) else os.path.join(ROOT, cfg["anchor"])
    character = cfg.get("character", "")
    style = cfg.get("style", STYLE)

    from openai import OpenAI
    client = OpenAI(api_key=env("IMAGE_API_KEY", "TFY_API_KEY", "JUDGE_API_KEY", "OPENAI_API_KEY"),
                    base_url=env("IMAGE_BASE_URL", "TFY_BASE_URL", "JUDGE_BASE_URL", "OPENAI_BASE_URL") or None)
    model = env("IMAGE_MODEL") or "gemini-3-pro-image-preview"

    for rel, scene in cfg["targets"].items():
        out = rel if os.path.isabs(rel) else os.path.join(ROOT, rel)
        prompt = f"{style} Character(s): {character}. {scene}"
        print(f"▸ {os.path.basename(out)} …")
        try:
            with open(anchor, "rb") as f:
                resp = client.images.edit(model=model, image=[f], prompt=prompt, n=1,
                                          extra_body={"aspect_ratio": "3:2"})
            item = resp.data[0]
            if getattr(item, "b64_json", None):
                open(out, "wb").write(base64.b64decode(item.b64_json))
            elif getattr(item, "url", None):
                urllib.request.urlretrieve(item.url, out)
            else:
                print("  ! no image data"); continue
            print(f"  wrote {rel}")
        except Exception as e:
            print(f"  ERR {type(e).__name__}: {e}")


if __name__ == "__main__":
    main()
