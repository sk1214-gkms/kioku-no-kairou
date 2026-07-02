#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
部屋レイアウトの自動点検＋合成レンダリング（開発用）。
- エンジンと同じ 360x640 設計座標に rect を配置し、背景(placeholder)＋ホットスポットを合成。
- 出現物(show_when)を全て満たした状態で、枠の重なり／画面外／空き方向 を検出。
- 使い方: python tools/audit_layouts.py [出力ディレクトリ]
  レポートを標準出力、モンタージュ layout_1_7.png / layout_8_13.png を出力先へ。
依存: Pillow（背景placeholderは gen_placeholders.py で先に生成）
"""
import json, io, os, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOMS = os.path.join(ROOT, "assets", "images", "rooms")
OUT = sys.argv[1] if len(sys.argv) > 1 else ROOT
CW, CH = 360, 640
DIRS = ["north", "east", "south", "west"]
DJ = {"north": "北", "east": "東", "south": "南", "west": "西"}
try:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
except Exception:
    pass

def font(sz):
    for p in [r"C:/Windows/Fonts/YuGothB.ttc", r"C:/Windows/Fonts/msgothic.ttc",
              "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"]:
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            continue
    return ImageFont.load_default()

def load(r):
    return json.load(io.open(os.path.join(ROOT, "data", "deep_rooms", f"r{r}.json"), encoding="utf-8"))

def reveal_state(d):
    st = {}
    for v in d["views"].values():
        for o in v["objects"]:
            if o.get("toggle"):
                st[o["id"]] = (o.get("states") or ["off"])[0]
    for v in d["views"].values():
        for o in v["objects"]:
            sw = o.get("show_when")
            if isinstance(sw, dict):
                for p in sw.get("state", []) or []:
                    st[p["interactable"]] = p["state"]
    return st

def overlaps(a, b):
    ax, ay, aw, ah = a
    bx, by, bw, bh = b
    return not (ax + aw <= bx or bx + bw <= ax or ay + ah <= by or by + bh <= ay)

def flags_of(o, key):
    c = o.get(key)
    return set((c or {}).get("flags") or []) if isinstance(c, dict) else set()

def exclusive(a, b):
    """フラグで相互排他（片方 show_when F・もう片方 hide_when F）＝同時表示されないペア。
    同一rectの“条件付き差し替え”（例: R7 white / white_ow）を重なり誤検出しない。"""
    return bool(flags_of(a, "show_when") & flags_of(b, "hide_when")) or \
           bool(flags_of(b, "show_when") & flags_of(a, "hide_when"))

def main():
    thumbs, prob = {}, 0
    print("=== レイアウト点検（normal＋hard 両表示集合）===")
    for rn in range(1, 14):
        d = load(rn)
        for dr in DIRS:
            allobjs = d["views"][dr]["objects"]
            objs = [o for o in allobjs if not o.get("hard_only")]  # 描画用=normal
            iss = []
            if not objs:
                iss.append("空(0)")
            # normal と hard、両方の表示集合で 画面外/重なり を検査
            for tag, excl in (("N", "hard_only"), ("H", "normal_only")):
                mobjs = [o for o in allobjs if not o.get(excl)]
                rects = [(o["id"], o["rect"]) for o in mobjs]
                for oid, (x, y, w, h) in rects:
                    if x < 0 or y < 0 or x + w > CW or y + h > CH:
                        iss.append(f"[{tag}]画面外:" + oid)
                for i in range(len(rects)):
                    for j in range(i + 1, len(rects)):
                        if overlaps(rects[i][1], rects[j][1]) and \
                                not exclusive(mobjs[i], mobjs[j]):
                            iss.append(f"[{tag}]重なり:{rects[i][0]}x{rects[j][0]}")
            # 同一問題がN/H双方に出たら片方に集約
            iss = sorted(set(iss), key=iss.index)
            dedup = [s for s in iss if not (s.startswith("[H]") and ("[N]" + s[3:]) in iss)]
            iss = dedup
            if iss:
                print(f"  R{rn} {dr}: {len(objs)}個  [!] {', '.join(iss)}")
                prob += 1
            img = Image.new("RGB", (CW, CH), (21, 19, 28))
            bp = os.path.join(ROOMS, f"r{rn}_{dr}.png")
            if os.path.exists(bp):
                img.paste(Image.open(bp).convert("RGB").resize((CW, CH)), (0, 0))
            dd = ImageDraw.Draw(img, "RGBA")
            dd.rectangle([0, 0, CW, 24], fill=(14, 12, 20, 235))
            dd.text((5, 5), f"R{rn} {DJ[dr]} ({len(objs)})", font=font(12), fill=(230, 225, 215, 255))
            for o in objs:
                x, y, w, h = o["rect"]
                dd.rectangle([x, y, x + w, y + h], fill=(103, 58, 183, 89),
                             outline=(255, 255, 255, 180), width=2)
                dd.multiline_text((x + w / 2, y + h / 2), o["label"], font=font(10),
                                  fill=(255, 255, 255, 255), anchor="mm", align="center")
            thumbs[(rn, dr)] = img
    print(f"--- 問題画面 {prob}/52 ---")
    audit_records()
    tw, th = 150, 267
    for rns, fn in ((range(1, 8), "layout_1_7.png"), (range(8, 14), "layout_8_13.png")):
        rns = list(rns)
        M = Image.new("RGB", (4 * (tw + 6) + 6, len(rns) * (th + 6) + 6), (40, 40, 46))
        for ri, rn in enumerate(rns):
            for ci, dr in enumerate(DIRS):
                M.paste(thumbs[(rn, dr)].resize((tw, th)), (6 + ci * (tw + 6), 6 + ri * (th + 6)))
        M.save(os.path.join(OUT, fn))
        print("saved", os.path.join(OUT, fn))

def audit_records():
    """手がかりmemo(record)の漏洩検査：
    - ハードで有効になる record(_hard) の value に含まれる数字列が、
      reveal_hard（無ければ reveal）に現れない → 『文章では伏せたのに記録が漏らす』候補
    - record のラベルが 罠/囮 を自己申告していないか
    規約: recordは観測のみ・導出は書かない／reveal_hardで伏せた値は record_hard で同等に伏せる"""
    import re
    KANJI = {"三十": "30", "二十": "20", "十五": "15", "十九": "19"}
    warn = 0

    def scan(rn, objs):
        nonlocal warn
        for o in objs:
            rh = o.get("record_hard")
            eff = None
            if rh is False:
                eff = None  # ハードでは記録しない＝漏洩なし
            elif isinstance(rh, dict):
                eff = rh
            elif isinstance(o.get("record"), dict):
                eff = o["record"]
            if eff:
                label = str(eff.get("label", ""))
                if "罠" in label or "囮" in label:
                    print(f"  [record] R{rn} {o.get('id')}: ラベルが囮を自己申告 -> '{label}'")
                    warn += 1
                val = str(eff.get("value", ""))
                digs = re.findall(r"[0-9]+", val)
                if digs:
                    rev = str(o.get("reveal_hard") or o.get("reveal") or "")
                    for k, v in KANJI.items():
                        rev = rev.replace(k, v)
                    miss = [t for t in digs if t not in rev]
                    if miss:
                        print(f"  [record] R{rn} {o.get('id')}: 記録値の数字 {miss} が"
                              f" reveal_hard に無い（ハードで記録だけ漏れる候補）")
                        warn += 1
            sub = o.get("subview")
            if isinstance(sub, dict):
                scan(rn, sub.get("objects") or [])

    print("=== record漏洩検査（ハード規約） ===")
    for rn in range(1, 14):
        d = load(rn)
        for v in d["views"].values():
            scan(rn, v["objects"])
    print(f"--- record警告 {warn}件 ---")

if __name__ == "__main__":
    main()
