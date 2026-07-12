#!/usr/bin/env python3
"""Build the Treasures (collection) screen mockup — the gamification layer where
kids see the rewards they've earned by completing stories and milestones.

Data-driven from design/treasures.json; inlines the painted chest hero
(design/assets/ui/treasure_chest.png). Emblems are inline SVG (gold for earned,
muted + lock for not-yet). Grace-not-guilt: locked tiles invite, never shame.

Usage (from repo root):
  python3 design/build_treasures.py            # -> design/treasures.html
"""
import os, json, base64, argparse
from io import BytesIO
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "design", "assets")
CONFIG = os.path.join(ROOT, "design", "treasures.json")
DEFAULT_OUT = os.path.join(ROOT, "design", "treasures.html")


def data_uri(path, max_w=620, quality=84):
    img = Image.open(path).convert("RGB")
    if img.width > max_w:
        img = img.resize((max_w, round(img.height * max_w / img.width)), Image.LANCZOS)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=quality)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def build(out_path):
    cfg = json.load(open(CONFIG))
    cfg["hero_uri"] = data_uri(os.path.join(ASSETS, cfg["hero"]))
    html = HTML_TEMPLATE.replace("__DATA__", json.dumps(cfg))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(html)
    print(f"wrote {out_path}  ({len(html)//1024} KB)")


HTML_TEMPLATE = r"""<script src="https://unpkg.com/@phosphor-icons/web"></script>
<style>
@import url('https://fonts.googleapis.com/css2?family=IM+Fell+English:ital@0;1&family=IM+Fell+English+SC&family=Atkinson+Hyperlegible:wght@400;700;800&display=swap');
body{background:#e7dcc4;margin:0}
.h2{font-family:'IM Fell English',serif;color:#4a3520;margin:10px 0 2px;text-align:center}
.sub{font-family:'Atkinson Hyperlegible',sans-serif;color:#6b5a3e;font-size:13px;text-align:center;max-width:680px;margin:0 auto 14px;line-height:1.5}
.stage{display:flex;justify-content:center;padding:6px 0 30px}
.phone{border-radius:40px;padding:11px;background:linear-gradient(160deg,#2c2116,#1a130c);box-shadow:0 18px 40px rgba(0,0,0,.4)}
.screen{position:relative;width:300px;height:720px;border-radius:30px;overflow:hidden;background:#F6EDD7;display:flex;flex-direction:column}
.scroll{flex:1 1 auto;overflow-y:auto}
/* hero */
.hero{position:relative}
.hero img{width:100%;height:186px;object-fit:cover;display:block}
.hero .scrim{position:absolute;inset:0;background:linear-gradient(to bottom,rgba(40,25,10,.05) 40%,rgba(40,25,10,.65))}
.hero .cap{position:absolute;left:0;right:0;bottom:10px;text-align:center;color:#FBF3DC}
.hero .cap h1{font-family:'IM Fell English',serif;font-weight:400;font-size:27px;margin:0;letter-spacing:1px;text-shadow:0 2px 4px rgba(0,0,0,.5)}
.hero .cap .cnt{font-family:'Atkinson Hyperlegible',sans-serif;font-weight:800;font-size:11px;letter-spacing:.5px;color:#F2DFA9}
/* summary pills */
.pills{display:flex;justify-content:center;gap:10px;padding:10px 0 4px}
.pill{display:inline-flex;align-items:center;gap:5px;font-family:'Atkinson Hyperlegible',sans-serif;font-weight:800;font-size:12px;color:#6b4a2a;background:#efe0be;border:1px solid #d6bd88;border-radius:20px;padding:4px 11px}
.pill i{font-size:15px}.pill .fl{color:#E8802B}.pill .gm{color:#3F8FBF}
/* sections + grid */
.sec{padding:6px 14px 2px}
.sec h2{font-family:'IM Fell English',serif;font-weight:400;font-size:17px;color:#7a4a12;margin:8px 0 2px;display:flex;align-items:center;gap:7px}
.sec h2::after{content:"";flex:1;height:1px;background:#d8c39a}
.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:6px 4px;padding:8px 0 4px}
.t{display:flex;flex-direction:column;align-items:center;text-align:center;gap:3px}
.medal{position:relative;width:58px;height:58px;border-radius:50%;display:flex;align-items:center;justify-content:center}
.medal.on{background:radial-gradient(circle at 50% 38%,#FBE7A6,#D9A94E);border:2.5px solid #B07E2C;box-shadow:0 2px 4px rgba(90,60,20,.35),inset 0 2px 3px rgba(255,255,255,.5)}
.medal.off{background:#e4d6b4;border:2px dashed #c3ac7d}
.medal svg{width:32px;height:32px}
.medal.on svg{fill:#6E4514}
.medal.off svg{fill:#b6a480}
.medal .lk{position:absolute;right:-2px;bottom:-2px;width:19px;height:19px;border-radius:50%;background:#8a7350;border:2px solid #F6EDD7;display:flex;align-items:center;justify-content:center}
.medal .lk i{font-size:10px;color:#fff}
.medal .chk{position:absolute;right:-3px;bottom:-3px;width:19px;height:19px;border-radius:50%;background:#7E8B52;border:2px solid #F6EDD7;display:flex;align-items:center;justify-content:center}
.medal .chk i{font-size:10px;color:#fff}
.t .nm{font-family:'Atkinson Hyperlegible',sans-serif;font-weight:800;font-size:8.5px;line-height:1.05;color:#5b4630}
.t.locked .nm{color:#9a8763}
.t .hint{font-family:'Atkinson Hyperlegible',sans-serif;font-weight:700;font-size:7.5px;color:#a2895f}
/* bottom nav */
.nav{flex:0 0 auto;height:54px;display:flex;justify-content:space-around;align-items:center;background:#EBDBB4;border-top:1.5px solid #C7A566}
.nav .tab{display:flex;flex-direction:column;align-items:center;gap:1px;font-family:'Atkinson Hyperlegible',sans-serif;font-weight:700;font-size:9px;color:#6b4a2a}
.nav .tab i{font-size:20px}
.nav .tab.on{color:#B07E2C}
</style>

<h2 class="h2">Treasures — the collection</h2>
<p class="sub">The gamified reward layer, kept separate from the sacred story. Earned by finishing stories &amp; milestones; locked tiles invite ("keep exploring"), never shame (grace-not-guilt).</p>

<div class="stage"><div class="phone"><div class="screen" id="screen"></div></div></div>

<script>
const D=__DATA__;
const EMBLEMS={
  compass:'<svg viewBox="0 0 32 32"><polygon points="16,3 19,15 16,17 13,15"/><polygon points="16,29 19,17 16,15 13,17" opacity=".8"/><polygon points="3,16 15,13 17,16 15,19"/><polygon points="29,16 17,13 15,16 17,19" opacity=".8"/><circle cx="16" cy="16" r="2.4"/></svg>',
  waves:'<svg viewBox="0 0 32 32"><path d="M4 20c3 0 3-8 7-8s4 8 7 8 3-8 7-8v6c-4 0-4 6-7 6s-4-6-7-6-3 6-7 6z"/><path d="M4 11c3 0 3-6 7-6s4 6 7 6 3-6 7-6" fill="none" stroke="currentColor" stroke-width="2" style="stroke:inherit" opacity=".55"/></svg>',
  heart:'<svg viewBox="0 0 32 32"><path d="M16 27C6 20 3 15 3 11a6 6 0 0 1 11-3 6 6 0 0 1 11 3c0 4-3 9-9 16z"/></svg>',
  dove:'<svg viewBox="0 0 32 32"><path d="M28 8c-3 0-6 2-8 5-2-1-9-2-13 2 3 0 4 1 4 1-3 1-6 4-6 8 2-3 5-3 5-3-1 2-1 5 1 7 1-5 5-8 10-9 4-1 7-4 7-8 0-1 0-2-1-3 1 0 2-1 1-3z"/></svg>',
  boot:'<svg viewBox="0 0 32 32"><circle cx="10" cy="7" r="3"/><circle cx="20" cy="12" r="2.4"/><circle cx="12" cy="15" r="2.4"/><circle cx="22" cy="20" r="2.4"/><circle cx="14" cy="23" r="2.2"/><circle cx="24" cy="27" r="2.2"/></svg>',
  flame:'<svg viewBox="0 0 32 32"><path d="M17 3c1 5-3 6-5 10-2 3 0 8 4 8 3 0 6-3 6-7 0-2-1-4-2-5 0 2-1 3-2 3 1-4-1-7-1-9z"/><path d="M12 15c-2 2-3 4-3 7 0 5 4 8 8 8-3-1-5-3-5-6 0-3 2-4 2-6-1 0-2-1-2-3z"/></svg>',
  map:'<svg viewBox="0 0 32 32"><path d="M4 8l8-3 8 3 8-3v19l-8 3-8-3-8 3z"/><path d="M12 5v19M20 8v19" fill="none" stroke="#F6EDD7" stroke-width="1.4"/></svg>',
  gem:'<svg viewBox="0 0 32 32"><path d="M9 5h14l6 8-13 15L3 13z"/><path d="M3 13h26M16 5l-5 8 5 15 5-15z" fill="none" stroke="#F6EDD7" stroke-width="1.2" opacity=".7"/></svg>',
  sun:'<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="7"/><g>'+[...Array(8)].map((_,k)=>`<rect x="15" y="1" width="2" height="5" transform="rotate(${k*45} 16 16)"/>`).join('')+'</g></svg>',
  crown:'<svg viewBox="0 0 32 32"><path d="M4 24l-1-13 8 6 5-9 5 9 8-6-1 13z"/><rect x="4" y="24" width="24" height="4"/></svg>'
};
function medal(t){
  const emb=EMBLEMS[t.emblem]||'';
  const badge = t.earned ? '<div class="chk"><i class="ph-bold ph-check"></i></div>' : '<div class="lk"><i class="ph-fill ph-lock-simple"></i></div>';
  const sub = t.earned ? t.from : (t.hint||t.from);
  return `<div class="t ${t.earned?'':'locked'}">
    <div class="medal ${t.earned?'on':'off'}">${emb}${badge}</div>
    <div class="nm">${t.earned?t.name:'???'}</div>
    <div class="hint">${sub}</div></div>`;
}
const sections = D.sections.map(s=>`
  <div class="sec"><h2>${s.title}</h2><div class="grid">${s.items.map(medal).join('')}</div></div>`).join('');

document.getElementById('screen').innerHTML = `
  <div class="scroll">
    <div class="hero">
      <img src="${D.hero_uri}" alt="">
      <div class="scrim"></div>
      <div class="cap"><h1>Treasures</h1><div class="cnt">${D.found} of ${D.total} found</div></div>
    </div>
    <div class="pills">
      <span class="pill"><i class="ph-fill ph-flame fl"></i>${D.streak}-day streak</span>
      <span class="pill"><i class="ph-fill ph-diamond gm"></i>${D.gems} gems</span>
    </div>
    ${sections}
    <div style="height:6px"></div>
  </div>
  <div class="nav">
    <div class="tab"><i class="ph-fill ph-compass"></i>Map</div>
    <div class="tab"><i class="ph-fill ph-book-open"></i>Stories</div>
    <div class="tab"><i class="ph-fill ph-chat-circle-dots"></i>Ask</div>
    <div class="tab on"><i class="ph-fill ph-treasure-chest"></i>Treasures</div>
  </div>`;
</script>
"""

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=DEFAULT_OUT)
    build(ap.parse_args().out)
