#!/usr/bin/env python3
"""Generate a SEAMLESS, vertically-tiling treasure-map background via the TrueFoundry
image gateway, then guarantee the seam is invisible so the map can scroll infinitely.

Why: the old expedition-map-tall.png was one fixed composite — it had empty stretches
and a hard top/bottom, so a long scroll showed seams. Instead we generate ONE rich map
"tile" and repeat it vertically in the app. To make the repeat invisible, we blend the
image's bottom edge into its top edge and crop the overlap (a standard make-tileable
wrap): the last row then flows into the first row of the next copy with no seam.

Output: a single seamless tile written into the ExpeditionMap imageset (+ docs copy).
The app (PaintedMapBackdrop) tiles it vertically to fill however tall the trail is.

Run:  python3 design/build_seamless_map.py            # generate + make seamless
      python3 design/build_seamless_map.py --reuse    # skip the API, re-process the last raw
"""
import os, sys, base64, argparse, urllib.request
import numpy as np
from PIL import Image, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "design", "assets", "seamless_map_raw.png")
OUT = os.path.join(ROOT, "app/BibleStory/BibleStory/Assets.xcassets/ExpeditionMap.imageset/expedition-map-tall.png")
OUT_COPY = os.path.join(ROOT, "docs/design-assets/expedition-map-tall.png")

STYLE = (
    "A hand-drawn antique treasure map, aged sepia parchment, muted warm browns and "
    "faded greens, fine ink linework and light watercolor wash, storybook cartography "
    "for children. A continuous explorable world seen top-down: rolling hills and "
    "forests, inked mountain ranges, winding rivers and a lake, a rocky coastline meeting "
    "calm sea with a little sailing ship and a spouting whale, a few small islands, a "
    "compass rose, dotted trail paths, and an X-marked treasure spot. Elements spread "
    "evenly across the WHOLE frame with no empty areas and no single large focal subject. "
    "Soft, muted, low-contrast so bright picture frames can sit on top. "
    "NO text, NO labels, NO border or frame, NO vignette, fills the entire canvas edge to edge."
)


def load_dotenv(path=os.path.join(ROOT, ".env")):
    if not os.path.exists(path):
        return
    for line in open(path):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))


def first_env(*names):
    for n in names:
        if os.environ.get(n):
            return os.environ[n]
    return None


def generate_raw():
    from openai import OpenAI
    base_url = first_env("IMAGE_BASE_URL", "TFY_BASE_URL", "JUDGE_BASE_URL", "OPENAI_BASE_URL")
    api_key = first_env("IMAGE_API_KEY", "TFY_API_KEY", "JUDGE_API_KEY", "OPENAI_API_KEY")
    model = first_env("IMAGE_MODEL") or "openai-main/gpt-image-1"
    client = OpenAI(api_key=api_key, base_url=base_url or None)
    print(f"generating raw tile  model={model}  aspect=2:3 …")
    try:
        resp = client.images.generate(model=model, prompt=STYLE, n=1,
                                       extra_body={"aspect_ratio": "2:3"})
    except Exception:
        # models that ignore aspect_ratio: fall back to a portrait size
        resp = client.images.generate(model=model, prompt=STYLE, n=1, size="1024x1536")
    item = resp.data[0]
    os.makedirs(os.path.dirname(RAW), exist_ok=True)
    if getattr(item, "b64_json", None):
        open(RAW, "wb").write(base64.b64decode(item.b64_json))
    elif getattr(item, "url", None):
        urllib.request.urlretrieve(item.url, RAW)
    else:
        sys.exit("response had neither b64_json nor url")
    print(f"  wrote {os.path.relpath(RAW, ROOT)}")


def crop_white_margin(img, inset_frac=0.012):
    """Crop the antique deckled WHITE paper surround so the parchment fills edge to
    edge (no white side/edge borders). Detects near-white rows/cols from each edge,
    then insets a touch more to clear the ragged torn edge."""
    a = np.asarray(img.convert("RGB"))
    h, w, _ = a.shape
    white = (a > 236).all(-1)               # near-white background pixels
    def scan(is_white_line, n):
        i = 0
        while i < int(n * 0.14) and is_white_line(i).mean() >= 0.80:
            i += 1
        return i
    top    = scan(lambda i: white[i, :],     h)
    bottom = scan(lambda i: white[h-1-i, :], h)
    left   = scan(lambda i: white[:, i],     w)
    right  = scan(lambda i: white[:, w-1-i], w)
    fy, fx = int(h * inset_frac), int(w * inset_frac)
    top, bottom = top + fy, bottom + fy
    left, right = left + fx, right + fx
    return img.crop((left, top, w - right, h - bottom))


def make_seamless(img, overlap_frac=0.16):
    """Blend the bottom `k` rows into the top `k` rows and crop the overlap, so the
    image tiles vertically with no visible seam (last row is adjacent to first row)."""
    a = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    k = max(1, int(h * overlap_frac))
    out = a.copy()
    for i in range(k):
        t = i / k                      # 0 at very top → 1 at k
        out[i] = a[i] * t + a[i + h - k] * (1 - t)
    return Image.fromarray(out[: h - k].astype("uint8"), "RGB")


def unify_tone(img):
    """Nudge toward the app's warm parchment + slightly lower saturation/contrast so the
    colorful story frames pop against it (and so tabs can reuse a muted copy)."""
    img = ImageEnhance.Color(img).enhance(0.9)
    img = ImageEnhance.Contrast(img).enhance(0.95)
    parch = Image.new("RGB", img.size, (233, 216, 176))
    return Image.blend(img, parch, 0.12)


def main():
    load_dotenv()
    ap = argparse.ArgumentParser()
    ap.add_argument("--reuse", action="store_true", help="skip API; re-process existing raw")
    args = ap.parse_args()
    if not args.reuse:
        generate_raw()
    if not os.path.exists(RAW):
        sys.exit("no raw image; run without --reuse first")
    img = crop_white_margin(Image.open(RAW))
    tile = unify_tone(make_seamless(img))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    os.makedirs(os.path.dirname(OUT_COPY), exist_ok=True)
    tile.save(OUT); tile.save(OUT_COPY)
    w, h = tile.size
    print(f"seamless tile {w}x{h}  aspect(h/w)={h / w:.4f}  -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
