#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
一貫性のあるプレースホルダ背景を生成する（13室×4方向＝52枚）。
コードで全ピクセルを描くので“同じ館”に必ず揃う＝Fireflyの一貫性問題が起きない。
本番アートは同じパス(assets/images/rooms/<id>_<dir>.png)に上書きすればそのまま差し替わる。

使い方:  python tools/gen_placeholders.py
出力:    assets/images/rooms/r1_north.png ... r13_west.png
依存:    Pillow
"""
import os, io, json, math, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, "assets", "images", "rooms")
W, H = 540, 960  # プレースホルダ（BoxFit.coverで拡大されるので十分）
DIRS = ["north", "east", "south", "west"]
DIRJP = {"north": "北", "east": "東", "south": "南", "west": "西"}

# 章ごとの基調色（くすんだティール＆セピア＋血の赤の差し色＝館のDNA）
def chapter_top(idx):  # idx: 0-based room index (R1=0)
    if idx <= 3:   return (46, 40, 33)   # ch1 セピア寄り
    if idx <= 8:   return (32, 43, 45)   # ch2 ティール寄り
    return (42, 33, 42)                  # ch3 寒色＋崩壊
BOTTOM = (9, 8, 11)
RED = (150, 26, 26)

def load_font(size):
    for p in [  # Windows
              r"C:/Windows/Fonts/YuGothB.ttc", r"C:/Windows/Fonts/meiryob.ttc",
              r"C:/Windows/Fonts/meiryo.ttc", r"C:/Windows/Fonts/msgothic.ttc",
              r"C:/Windows/Fonts/YuGothM.ttc", r"C:/Windows/Fonts/yumin.ttf",
              # Linux（CI: fonts-noto-cjk）
              "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
              "/usr/share/fonts/opentype/noto/NotoSansCJKjp-Bold.otf",
              "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc",
              "/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

def vgrad(top, bottom):
    base = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        base.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return base.resize((W, H))

def radial(cx, cy, inner, outer, w=W, h=H):
    """中心(cx,cy)が明(255)→外周が暗(0) のグレースケール。"""
    img = Image.new("L", (w, h), 0)
    px = img.load()
    maxd = math.hypot(max(cx, w - cx), max(cy, h - cy))
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            d = math.hypot(x - cx, y - cy) / maxd
            v = int(255 * max(0.0, min(1.0, (outer - d) / (outer - inner))))
            px[x, y] = v
            if x + 1 < w: px[x + 1, y] = v
            if y + 1 < h: px[x, y + 1] = v
            if x + 1 < w and y + 1 < h: px[x + 1, y + 1] = v
    return img.filter(ImageFilter.GaussianBlur(40))

def light_center(direction):
    return {"north": (W * 0.5, H * 0.30), "east": (W * 0.78, H * 0.45),
            "south": (W * 0.5, H * 0.62), "west": (W * 0.22, H * 0.45)}[direction]

def make(room, idx, direction, seed):
    random.seed(seed)
    top = chapter_top(idx)
    img = vgrad(top, BOTTOM)
    # 光源（方向で位置が変わる＝4方向が違って見えるが同じ画風）
    cx, cy = light_center(direction)
    glow = radial(cx, cy, 0.0, 0.85)
    light = Image.new("RGB", (W, H), tuple(min(255, c + 40) for c in top))
    img = Image.composite(light, img, glow.point(lambda v: int(v * 0.5)))
    # ビネット（周辺を締める）
    vig = radial(W / 2, H / 2, 0.15, 1.15).point(lambda v: 60 + int(v * 195 / 255))
    img = ImageChops.multiply(img, Image.merge("RGB", [vig] * 3))
    # 粒状（フィルムの一体感・控えめ＝圧縮を効かせる）
    noise = Image.effect_noise((W, H), 12).filter(ImageFilter.GaussianBlur(0.6)).convert("RGB")
    img = ImageChops.overlay(img, noise.point(lambda v: 118 + (v - 128) // 6))
    # 透明オーバーレイに描いて合成（RGB直描きだとalphaが効かないため）
    ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    sf_dir = int(W * 0.045)
    # 大きなグリフ（トラウマ文字／無ければ室番）を“うっすら”焼き込む
    letter = room.get("letter") or ""
    gtxt = letter if letter.strip() else f"{idx+1}"
    gf = load_font(int(W * 0.78))
    bb = d.textbbox((0, 0), gtxt, font=gf)
    gw, gh = bb[2] - bb[0], bb[3] - bb[1]
    d.text(((W - gw) / 2 - bb[0], (H - gh) / 2 - bb[1] - 50), gtxt,
           font=gf, fill=(208, 198, 178, 34))
    # 血の差し色（細い斜めの滲み＝全室共通モチーフ）
    rx = random.randint(int(W * 0.20), int(W * 0.70))
    for k in range(7):
        a = 70 - k * 8
        d.line([(rx + k * 5, H * 0.16), (rx - 24 + k * 5, H * 0.36)],
               fill=(RED[0], RED[1], RED[2], max(0, a)), width=3)
    # 下部キャプション帯
    d.rectangle([0, H - 84, W, H], fill=(0, 0, 0, 150))
    nf = load_font(int(W * 0.062)); sf = load_font(int(W * 0.040))
    d.text((24, H - 74), room["name"], font=nf, fill=(225, 220, 210, 235))
    d.text((24, H - 36), f"{DIRJP[direction]}  —  placeholder", font=sf,
           fill=(168, 162, 156, 205))
    dw = d.textbbox((0, 0), DIRJP[direction], font=nf)
    d.text((W - (dw[2] - dw[0]) - 22, H - 74), DIRJP[direction], font=nf,
           fill=(200, 70, 70, 215))
    # ほんのり外周フレーム
    d.rectangle([6, 6, W - 7, H - 7], outline=(255, 255, 255, 22), width=2)
    img = Image.alpha_composite(img.convert("RGBA"), ov)
    # 軽いソフト化（プレースホルダ＝鮮鋭不要、PNG圧縮も効く）
    return img.filter(ImageFilter.GaussianBlur(0.5)).convert("RGB")

def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for i in range(1, 14):
        room = json.load(io.open(os.path.join(ROOT, "data", "deep_rooms", f"r{i}.json"), encoding="utf-8"))
        for j, dr in enumerate(DIRS):
            img = make(room, i - 1, dr, seed=i * 10 + j)
            img.save(os.path.join(OUT, f"r{i}_{dr}.png"), optimize=True)
            n += 1
    print(f"generated {n} backgrounds -> {OUT}")

if __name__ == "__main__":
    main()
