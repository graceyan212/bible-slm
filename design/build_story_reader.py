#!/usr/bin/env python3
"""Build the Story Reader mockup: the reading experience that opens when a kid
taps a story cover on the map. Renders one story (design/stories/<id>.json) as a
storyboard of phone screens — illustrated narrative pages, the app-retrieved
verse card, and the closing Christ Connection + treasure reward.

Grounded in behavior-spec.md + data/story_pedagogy.md:
  - narrative is a warm RETELL, never verbatim Scripture;
  - the exact verse is shown in a DISTINCT card, labelled as retrieved from the
    family's own Bible translation ("Approach B" — the product's differentiator);
  - the story ends gospel-centered (the Christ Connection), invitational;
  - the reward lands only at completion, so the story itself stays un-gamified.

Reads the page art from design/assets/story_<id>/ (see generate_scenes.py).
Writes a self-contained HTML (images inlined) to --out.

Usage (from repo root):
  python3 design/build_story_reader.py                    # -> design/story-reader.html
  python3 design/build_story_reader.py --story creation
"""
import os, json, base64, argparse
from io import BytesIO
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "design", "assets")
DEFAULT_OUT = os.path.join(ROOT, "design", "story-reader.html")


def data_uri(path, max_w=620, quality=84):
    img = Image.open(path).convert("RGB")
    if img.width > max_w:
        img = img.resize((max_w, round(img.height * max_w / img.width)), Image.LANCZOS)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=quality)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def build(story_id, out_path):
    cfg = json.load(open(os.path.join(ROOT, "design", "stories", f"{story_id}.json")))
    pages = []
    for p in cfg["pages"]:
        pages.append({"art": data_uri(os.path.join(ASSETS, p["art"])),
                      "heading": p["heading"], "text": p["text"]})
    payload = {"title": cfg["title"], "subtitle": cfg["subtitle"], "pages": pages,
               "verse": cfg["verse"], "cc": cfg["christ_connection"], "reward": cfg["reward"]}
    html = HTML_TEMPLATE.replace("__DATA__", json.dumps(payload))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w") as f:
        f.write(html)
    print(f"wrote {out_path}  ({len(html)//1024} KB)")


HTML_TEMPLATE = r"""<script src="https://unpkg.com/@phosphor-icons/web"></script>
<style>
@import url('https://fonts.googleapis.com/css2?family=IM+Fell+English:ital@0;1&family=IM+Fell+English+SC&family=Atkinson+Hyperlegible:wght@400;700;800&display=swap');
body{background:#e7dcc4;margin:0}
.h2{font-family:'IM Fell English',serif;color:#4a3520;margin:10px 0 2px;text-align:center}
.sub{font-family:'Atkinson Hyperlegible',sans-serif;color:#6b5a3e;font-size:13px;text-align:center;max-width:720px;margin:0 auto 14px;line-height:1.5}
.row{display:flex;gap:22px;flex-wrap:wrap;justify-content:center;align-items:flex-start;padding:6px 10px 30px}
.unit{display:flex;flex-direction:column;align-items:center;gap:6px}
.cap{font-family:'Atkinson Hyperlegible',sans-serif;font-weight:700;font-size:11px;color:#8a7350;letter-spacing:.3px}
.phone{border-radius:40px;padding:11px;background:linear-gradient(160deg,#2c2116,#1a130c);box-shadow:0 18px 40px rgba(0,0,0,.4)}
.screen{position:relative;width:300px;height:700px;border-radius:30px;overflow:hidden;background:#F6EDD7;display:flex;flex-direction:column}
/* paper grain */
.screen::before{content:"";position:absolute;inset:0;pointer-events:none;opacity:.5;
  background:radial-gradient(circle at 30% 20%,rgba(255,255,255,.5),transparent 60%),radial-gradient(circle at 80% 90%,rgba(180,150,100,.14),transparent 55%)}
.top{position:relative;z-index:2;height:44px;flex:0 0 auto;display:flex;align-items:center;justify-content:space-between;padding:0 12px;color:#5b4630}
.top .ttl{font-family:'IM Fell English',serif;font-size:16px}
.top i{font-size:19px;color:#7a5a34}
.top .rt{display:flex;align-items:center;gap:10px}
.art{position:relative;z-index:1;width:100%;height:200px;object-fit:cover;flex:0 0 auto;border-top:1.5px solid #d8c39a;border-bottom:1.5px solid #d8c39a}
.body{position:relative;z-index:2;flex:1 1 auto;overflow-y:auto;padding:14px 18px 8px}
.body h3{font-family:'IM Fell English',serif;font-weight:400;font-size:21px;color:#7a4a12;margin:0 0 7px}
.body p{font-family:'Atkinson Hyperlegible',sans-serif;font-size:14px;line-height:1.62;color:#4a3520;margin:0 0 10px}
.body p .drop{float:left;font-family:'IM Fell English',serif;font-size:40px;line-height:.8;padding:2px 6px 0 0;color:#B07E2C}
/* verse card — the app-retrieved Scripture, visibly distinct from the retell */
.verse{position:relative;margin:12px 0 6px;padding:12px 14px 10px 16px;background:#F0E4C4;border:1px solid #d9c188;border-radius:8px;box-shadow:0 1px 3px rgba(90,60,20,.18)}
.verse::before{content:"";position:absolute;left:0;top:0;bottom:0;width:4px;background:linear-gradient(#E7C877,#C89A3E);border-radius:8px 0 0 8px}
.verse .vr{font-family:'IM Fell English SC',serif;font-size:12px;letter-spacing:2px;color:#8a5f22;margin-bottom:3px}
.verse .vt{font-family:'IM Fell English',serif;font-style:italic;font-size:15.5px;line-height:1.45;color:#3f2f1c}
.verse .vtag{margin-top:8px;display:inline-flex;align-items:center;gap:4px;font-family:'Atkinson Hyperlegible',sans-serif;font-weight:700;font-size:9px;letter-spacing:.4px;color:#8a7350;background:#e6d4a8;border:1px solid #cbb27a;border-radius:20px;padding:2px 8px}
.verse .vtag i{font-size:11px}
/* footer nav */
.foot{position:relative;z-index:2;flex:0 0 auto;padding:8px 16px 14px;display:flex;align-items:center;justify-content:space-between;gap:10px}
.dots{display:flex;gap:5px}.dots span{width:7px;height:7px;border-radius:50%;background:#d3bd8e}.dots span.on{background:#B07E2C}
.btn{font-family:'IM Fell English SC',serif;font-size:14px;letter-spacing:1.5px;color:#5E3A16;background:linear-gradient(#F6D062,#D19A34);border:1.5px solid #8A5A22;border-radius:22px;padding:9px 20px;display:inline-flex;align-items:center;gap:7px;box-shadow:0 2px 0 #9a6b25;cursor:default}
.btn.ghost{background:none;border:none;box-shadow:none;color:#8a6a3e;font-family:'Atkinson Hyperlegible',sans-serif;font-weight:800;font-size:12px;letter-spacing:0}
/* completion screen */
.complete{position:relative;z-index:2;flex:1 1 auto;display:flex;flex-direction:column;align-items:center;text-align:center;padding:22px 20px;overflow-y:auto}
.reward{position:relative;width:96px;height:96px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:6px 0 4px;
  background:radial-gradient(circle at 50% 40%,#FBE7A6,#D9A94E);border:3px solid #B07E2C;box-shadow:0 0 0 6px rgba(217,169,78,.25),0 4px 10px rgba(90,60,20,.35)}
.reward svg{width:56px;height:56px}
.rays{position:absolute;width:150px;height:150px;left:50%;top:48px;transform:translate(-50%,-50%);z-index:1;opacity:.5}
.complete .earned{font-family:'Atkinson Hyperlegible',sans-serif;font-weight:800;font-size:11px;letter-spacing:1px;color:#8a5f22;margin-top:4px}
.complete .rname{font-family:'IM Fell English',serif;font-size:20px;color:#4a3520;margin:1px 0 2px}
.complete h3{font-family:'IM Fell English',serif;font-weight:400;font-size:22px;color:#7a4a12;margin:16px 0 6px}
.complete p{font-family:'Atkinson Hyperlegible',sans-serif;font-size:13.5px;line-height:1.6;color:#4a3520;margin:0 0 10px}
.complete .hr{width:46px;height:2px;background:#cbb27a;border-radius:2px;margin:6px 0 2px}
</style>

<h2 class="h2">Story Reader — tap a cover to read</h2>
<p class="sub">The reading flow for one story: warm retold pages (never verbatim Scripture), the exact verse shown from <b>your family's Bible</b> (the app's retrieval — visibly distinct from the retelling), then the gospel-centered <b>Christ Connection</b> and the treasure earned at the end.</p>

<div class="row" id="row"></div>

<script>
const D=__DATA__;
const row=document.getElementById('row');
const total=D.pages.length;

function topbar(showProgress, idx){
  return `<div class="top">
    <i class="ph ph-arrow-left"></i>
    <span class="ttl">${D.title}</span>
    <span class="rt"><i class="ph-fill ph-speaker-high"></i>${showProgress?`<span class="dots">${D.pages.map((_,i)=>`<span class="${i===idx?'on':''}"></span>`).join('')}</span>`:''}</span>
  </div>`;
}
function phone(inner, cap){
  const u=document.createElement('div'); u.className='unit';
  u.innerHTML=`<div class="phone"><div class="screen">${inner}</div></div><div class="cap">${cap}</div>`;
  row.appendChild(u);
}

// story pages (drop-cap on first paragraph); verse card on the LAST page
D.pages.forEach((p,i)=>{
  const first=p.text.charAt(0), rest=p.text.slice(1);
  const verse = (i===total-1) ? `
    <div class="verse">
      <div class="vr">${D.verse.ref}</div>
      <div class="vt">“${D.verse.text}”</div>
      <span class="vtag"><i class="ph-fill ph-book-bookmark"></i>${D.verse.translation} · shown from your family’s Bible</span>
    </div>` : '';
  const inner = `${topbar(true,i)}
    <img class="art" src="${p.art}" alt="">
    <div class="body"><h3>${p.heading}</h3><p><span class="drop">${first}</span>${rest}</p>${verse}</div>
    <div class="foot"><span class="dots">${D.pages.map((_,j)=>`<span class="${j===i?'on':''}"></span>`).join('')}</span>
      <span class="btn">${i<total-1?'NEXT':'FINISH'} <i class="ph-bold ph-arrow-right"></i></span></div>`;
  phone(inner, `Page ${i+1} of ${total}${i===total-1?' · verse from your Bible':''}`);
});

// completion: Christ Connection + treasure reward
const rose = `<svg viewBox="0 0 64 64"><g fill="#5E3A16">
  <polygon points="32,6 37,30 32,34 27,30"/><polygon points="32,58 37,34 32,30 27,34" opacity=".85"/>
  <polygon points="6,32 30,27 34,32 30,37"/><polygon points="58,32 34,27 30,32 34,37" opacity=".85"/>
  <polygon points="14,14 31,29 29,31 14,14" opacity=".6"/><polygon points="50,14 35,29 33,27 50,14" opacity=".6"/>
  <polygon points="14,50 29,35 31,33 14,50" opacity=".6"/><polygon points="50,50 33,35 35,33 50,50" opacity=".6"/></g>
  <circle cx="32" cy="32" r="5" fill="#7a4a12"/></svg>`;
const rays = `<svg class="rays" viewBox="0 0 100 100">${Array.from({length:12},(_,k)=>`<rect x="49" y="2" width="2" height="16" fill="#E7C877" transform="rotate(${k*30} 50 50)"/>`).join('')}</svg>`;
const done = `${topbar(false)}
  <div class="complete">
    ${rays}<div class="reward">${rose}</div>
    <div class="earned">TREASURE EARNED</div>
    <div class="rname">${D.reward.name}</div>
    <div class="hr"></div>
    <h3>${D.cc.heading}</h3>
    <p>${D.cc.text}</p>
    <p style="color:#8a6a3e;font-size:12.5px">${D.reward.text}</p>
    <span class="btn" style="margin-top:6px"><i class="ph-fill ph-compass"></i> BACK TO THE MAP</span>
  </div>`;
phone(done, 'Complete · Christ Connection + reward');
</script>
"""

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--story", default="creation")
    ap.add_argument("--out", default=DEFAULT_OUT)
    a = ap.parse_args()
    build(a.story, a.out)
