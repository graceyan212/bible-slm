#!/usr/bin/env python3
"""Regenerate the 'Jesus & the Children' page art so Jesus is the SAME character on
every page (p1 was the good one — long brown hair, short beard, cream robe, tan sash;
p2 came out bald, p3 had a different robe/style).

Approach: condition each new page on p1 as a REFERENCE image (OpenAI-compatible
/images/edits through the TrueFoundry gateway, gemini image model), with a locked
character description, so the model keeps Jesus's face/hair/robe consistent while
drawing each page's scene. p1 is kept as-is and used as the anchor.

Run:  python3 design/regen_jesus_children.py           # regenerate p2 + p3
      python3 design/regen_jesus_children.py --all      # also redo p1 (from itself)
"""
import os, sys, base64, argparse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "app/BibleStory/BibleStory/Assets.xcassets")
REF = os.path.join(ASSETS, "StoryJesusChildrenP1.imageset/jesus_p1.png")

STYLE = (
    "Children's Bible storybook illustration for ages 7-9: soft flat cartoon with clean "
    "dark outlines and gentle watercolor shading, warm and bright, the scene FILLS the "
    "whole frame edge to edge with NO border and NO text. "
    "Keep the EXACT SAME Jesus as the reference image — a kind man with long wavy brown "
    "hair to his shoulders, a short brown beard, warm light skin, a calm gentle smile, "
    "wearing a cream/off-white robe with a tan sash belt and brown sandals. Same face, "
    "same proportions, same robe colors as the reference on every page. "
)

PAGES = {
    "StoryJesusChildrenP2.imageset/jesus_p2.png":
        "Scene: Jesus kneeling down on the grass with open, welcoming arms, smiling warmly "
        "as a diverse group of happy young children run toward him to be near him; one or "
        "two adult disciples stand back looking surprised. Green rolling hills, a river, "
        "flowers, blue sky with a sun.",
    "StoryJesusChildrenP3.imageset/jesus_p3.png":
        "Scene: Jesus sitting on the ground with his arms wrapped gently around several "
        "diverse young children hugging close to him, blessing them, everyone peaceful and "
        "loved. Green grass, trees and bushes, warm golden sky.",
}


def env(*names):
    for n in names:
        if os.environ.get(n): return os.environ[n]
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()

    # load .env
    p = os.path.join(ROOT, ".env")
    if os.path.exists(p):
        for line in open(p):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

    from openai import OpenAI
    client = OpenAI(api_key=env("IMAGE_API_KEY", "TFY_API_KEY", "JUDGE_API_KEY", "OPENAI_API_KEY"),
                    base_url=env("IMAGE_BASE_URL", "TFY_BASE_URL", "JUDGE_BASE_URL", "OPENAI_BASE_URL") or None)
    model = env("IMAGE_MODEL") or "gemini-3-pro-image-preview"

    targets = dict(PAGES)
    if args.all:
        targets["StoryJesusChildrenP1.imageset/jesus_p1.png"] = (
            "Scene: Jesus standing on a grassy hill warmly welcoming families and their "
            "young children walking toward him, reaching out a hand, gentle smile. Blue sky, sun.")

    for rel, scene in targets.items():
        out = os.path.join(ASSETS, rel)
        prompt = STYLE + scene
        print(f"▸ {rel.split('/')[0]} …")
        try:
            with open(REF, "rb") as f:
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
