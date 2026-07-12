#!/usr/bin/env python3
"""Build the Expedition home-screen mockup: the clean painted map, a title banner
spanning the top, and each story shown as a landscape gold FRAME (generated scene
composited into the frame's opening, title on the frame's ribbon).

Reads:
  - clean map             docs/design-assets/expedition-map-clean.png
  - gold story frame       docs/design-assets/story-frame.png   (outer bg already transparent)
  - generated scenes       design/assets/scenes/<id>.png        (from generate_scenes.py)
  - scene titles/order     design/scenes.json
Writes one self-contained HTML (all images inlined as data-URIs) to --out.

The per-story frame image is composited here in Pillow (scene cover-fit into the
frame opening); the story TITLE is overlaid as live HTML text on the ribbon.
Edit LAYOUT to move a story / change done|active|locked, or FRAME_OPENING to
re-calibrate where the scene sits inside the frame.

Usage (from repo root):
  python3 design/build_map_mockup.py                 # -> design/expedition-home.html
"""
import os, json, base64, argparse
from io import BytesIO
from PIL import Image, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_PNG = os.path.join(ROOT, "docs", "design-assets", "expedition-map-clean.png")
FRAME_PNG = os.path.join(ROOT, "docs", "design-assets", "story-frame.png")
SCENE_DIR = os.path.join(ROOT, "design", "assets", "scenes")
CONFIG = os.path.join(ROOT, "design", "scenes.json")
DEFAULT_OUT = os.path.join(ROOT, "design", "expedition-home.html")

# Where the scene sits inside the frame image, as fractions of the frame (l,t,r,b).
# Measured from the cream opening (see scripts/measure), inset slightly so the
# gold border stays fully visible around the scene.
FRAME_OPENING = dict(l=0.143, t=0.200, r=0.852, b=0.716)
# Ribbon center (fraction of frame height) — where the title text is overlaid.
RIBBON_Y = 0.855

# Story placement on the 330x591 screen: center x/y (%), frame width (%), state, label.
LAYOUT = {
    "creation":       {"x": 33, "y": 22, "w": 45, "state": "done",   "label": "Creation"},
    "red_sea":        {"x": 66, "y": 40, "w": 45, "state": "done",   "label": "The Red Sea"},
    "jesus_children": {"x": 33, "y": 58, "w": 45, "state": "active", "label": "Jesus &amp; the Children"},
    "the_promise":    {"x": 66, "y": 76, "w": 45, "state": "locked", "label": "The Promise"},
}


def data_uri(img, quality=84, fmt="JPEG"):
    buf = BytesIO()
    if fmt == "PNG":
        img.save(buf, format="PNG")
        return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()
    img.convert("RGB").save(buf, format="JPEG", quality=quality)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def map_uri(max_w=900):
    m = Image.open(MAP_PNG)
    if m.width > max_w:
        m = m.resize((max_w, round(m.height * max_w / m.width)), Image.LANCZOS)
    return data_uri(m)


def framed_scene(scene_path, max_w=460):
    """Composite a scene into the gold frame opening; return a transparent-bg PNG data-URI."""
    frame = Image.open(FRAME_PNG).convert("RGBA")
    W, H = frame.size
    o = FRAME_OPENING
    box = (int(o["l"] * W), int(o["t"] * H), int(o["r"] * W), int(o["b"] * H))
    ow, oh = box[2] - box[0], box[3] - box[1]
    scene = ImageOps.fit(Image.open(scene_path).convert("RGBA"), (ow, oh), Image.LANCZOS)
    out = frame.copy()
    out.alpha_composite(scene, (box[0], box[1]))
    if out.width > max_w:
        out = out.resize((max_w, round(out.height * max_w / out.width)), Image.LANCZOS)
    return data_uri(out, fmt="PNG")


def build(out_path):
    with open(CONFIG) as f:
        cfg = json.load(f)
    stories = []
    for s in cfg["scenes"]:
        if s["id"] not in LAYOUT:
            continue
        png = os.path.join(SCENE_DIR, f"{s['id']}.png")
        if not os.path.exists(png):
            print(f"  skip {s['id']} (no image — run generate_scenes.py)")
            continue
        lay = LAYOUT[s["id"]]
        stories.append({"img": framed_scene(png), "label": lay["label"],
                        "x": lay["x"], "y": lay["y"], "w": lay["w"], "state": lay["state"]})

    html = (HTML_TEMPLATE
            .replace("__MAP__", map_uri())
            .replace("__STORIES__", json.dumps(stories))
            .replace("__RIBBONY__", str(RIBBON_Y * 100)))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(html)
    print(f"wrote {out_path}  ({len(html)//1024} KB, {len(stories)} framed stories)")


HTML_TEMPLATE = r"""<script src="https://unpkg.com/@phosphor-icons/web"></script>
<style>
@import url('https://fonts.googleapis.com/css2?family=IM+Fell+English:ital@0;1&family=IM+Fell+English+SC&family=Atkinson+Hyperlegible:wght@700;800&display=swap');
body{background:#efe6d4}
.h2{font-family:'IM Fell English',serif;color:#4a3520;margin:0 0 2px;text-align:center}
.sub{font-family:'Atkinson Hyperlegible',sans-serif;color:#6b5a3e;font-size:13px;text-align:center;max-width:640px;margin:0 auto 14px;line-height:1.5}
.stage{display:flex;justify-content:center;padding:6px}
.phone{border-radius:44px;padding:12px;background:linear-gradient(160deg,#2c2116,#1a130c);box-shadow:0 24px 54px rgba(0,0,0,.45)}
.screen{position:relative;width:330px;height:591px;border-radius:32px;overflow:hidden;background:#e9dcbf}
.screen img.bg{position:absolute;inset:0;width:100%;height:100%;object-fit:fill;display:block}
.ov{position:absolute;inset:0}
/* ---- title banner across the top ---- */
.banner{position:absolute;top:1.2%;left:2%;width:96%;filter:drop-shadow(0 3px 5px rgba(60,40,15,.4))}
/* ---- story frames ---- */
.story{position:absolute;transform:translate(-50%,-50%)}
.story img.frame{width:100%;display:block;filter:drop-shadow(0 4px 7px rgba(50,32,12,.5))}
.story .stitle{position:absolute;left:50%;top:__RIBBONY__%;transform:translate(-50%,-50%);width:74%;text-align:center;
  font-family:'IM Fell English',serif;font-size:11px;line-height:1;color:#4a3520}
.story.locked{filter:grayscale(.5) opacity(.7)}
.story.active .stitle{color:#7a4a12}
.badge{position:absolute;top:6%;right:2%;width:22px;height:22px;border-radius:50%;display:flex;align-items:center;justify-content:center;box-shadow:0 1px 3px rgba(0,0,0,.4);z-index:3}
.badge.done{background:#7E8B52;border:2px solid #5c6a3a}
.badge.locked{background:#8a7350;border:2px solid #6b5636}
.badge i{color:#fff;font-size:12px}
.glow{position:absolute;left:50%;top:42%;width:126%;height:150%;transform:translate(-50%,-50%);border-radius:50%;z-index:-1;
  background:radial-gradient(circle,rgba(255,214,120,.9) 0%,rgba(243,195,74,.34) 48%,rgba(243,195,74,0) 72%);pointer-events:none}
/* ---- bottom nav on the map's cream bar ---- */
.nav{position:absolute;left:0;right:0;bottom:1%;height:7.5%;display:flex;justify-content:space-around;align-items:center;padding:0 5%}
.nav .tab{display:flex;flex-direction:column;align-items:center;gap:1px;font-family:'Atkinson Hyperlegible',sans-serif;font-weight:700;font-size:8px;color:#6b4a2a}
.nav .tab i{font-size:16px}
.nav .tab.on{color:#B07E2C}
@keyframes breathe{0%,100%{opacity:.72}50%{opacity:1}}
@media (prefers-reduced-motion:no-preference){.glow{animation:breathe 3.4s ease-in-out infinite}}
</style>

<h2 class="h2">The Expedition — clean map · top banner · framed stories</h2>
<p class="sub">Title banner spans the top; each story is a landscape gold frame (Nano Banana scene inside, title on the ribbon). Green ✓ done · glow = current · lock = not yet.</p>

<div class="stage">
  <div class="phone"><div class="screen">
    <img class="bg" src="__MAP__" alt="Expedition map">
    <div class="ov" id="ov"></div>
  </div></div>
</div>

<script>
const STORIES=__STORIES__;
const ov=document.getElementById('ov');

// title banner (SVG ribbon) spanning the top
ov.insertAdjacentHTML('beforeend', `
<svg class="banner" viewBox="0 0 620 96">
  <defs>
    <linearGradient id="bandg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#F6ECCF"/><stop offset="1" stop-color="#E7D3A6"/></linearGradient>
    <linearGradient id="tailg" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#D9BE83"/><stop offset="1" stop-color="#B9975A"/></linearGradient>
  </defs>
  <!-- end tails -->
  <path d="M40,26 L8,26 L22,48 L8,70 L40,70 Z" fill="url(#tailg)" stroke="#6B4A2E" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M580,26 L612,26 L598,48 L612,70 L580,70 Z" fill="url(#tailg)" stroke="#6B4A2E" stroke-width="2.5" stroke-linejoin="round"/>
  <!-- main band -->
  <path d="M34,14 Q26,48 34,82 L586,82 Q594,48 586,14 Z" fill="url(#bandg)" stroke="#6B4A2E" stroke-width="3"/>
  <path d="M34,14 Q26,48 34,82 L586,82 Q594,48 586,14 Z" fill="none" stroke="#B9975A" stroke-width="1" transform="translate(0,0) scale(.998)" opacity=".8"/>
  <line x1="52" y1="22" x2="568" y2="22" stroke="#C7A566" stroke-width="1" opacity=".6"/>
  <line x1="52" y1="74" x2="568" y2="74" stroke="#C7A566" stroke-width="1" opacity=".6"/>
  <text x="310" y="42" text-anchor="middle" font-family="IM Fell English SC" font-size="17" letter-spacing="5" fill="#7a5a34">THE</text>
  <text x="310" y="72" text-anchor="middle" font-family="IM Fell English" font-size="30" letter-spacing="2" fill="#4A3520">EXPEDITION</text>
</svg>
`);

// story frames
STORIES.forEach(s=>{
  const d=document.createElement('div');
  d.className='story '+s.state;
  d.style.left=s.x+'%'; d.style.top=s.y+'%'; d.style.width=s.w+'%';
  const glow = s.state==='active' ? '<div class="glow"></div>' : '';
  const badge = s.state==='done' ? '<div class="badge done"><i class="ph-bold ph-check"></i></div>'
             : s.state==='locked' ? '<div class="badge locked"><i class="ph-fill ph-lock-simple"></i></div>' : '';
  d.innerHTML=`${glow}<img class="frame" src="${s.img}" alt="">${badge}<div class="stitle">${s.label}</div>`;
  ov.appendChild(d);
});

// bottom nav
ov.insertAdjacentHTML('beforeend', `
  <div class="nav">
    <div class="tab on"><i class="ph-fill ph-compass"></i>Map</div>
    <div class="tab"><i class="ph-fill ph-book-open"></i>Stories</div>
    <div class="tab"><i class="ph-fill ph-chat-circle-dots"></i>Ask</div>
    <div class="tab"><i class="ph-fill ph-treasure-chest"></i>Treasures</div>
  </div>
`);
</script>
"""

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=DEFAULT_OUT)
    build(ap.parse_args().out)
