#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
一貫したプレースホルダ アイテムアイコンを生成（透過PNG）。
共通トークン(角丸プレート＋枠)＋カテゴリ別の簡易ピクトグラムで画風を統一。
本番は同じパス assets/images/items/<itemId>.png に上書きで差し替わる。

使い方:  python tools/gen_item_icons.py
依存:    Pillow
"""
import os, math
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(ROOT, "assets", "images", "items")
S = 256
INK   = (222, 214, 198, 255)
INK2  = (222, 214, 198, 140)
RED   = (190, 44, 40, 255)
METAL = (176, 184, 192, 255)
AMBER = (206, 150, 60, 235)
TOKEN = (26, 28, 31, 235)
BORDER= (186, 176, 156, 120)

CAT = {
    "item_r1_key": "key", "item_knob": "knob",
    "item_frag_a": "paper", "item_frag_b": "paper", "item_frag_c": "paper",
    "item_chart_half": "paper_half", "item_pass": "pass", "item_pass_valid": "pass_valid",
    "item_stamp": "stamp",
    "item_syringe_empty": "syr_empty", "item_syringe_loaded": "syr_loaded",
    "item_syringe_full": "syr_full", "item_needle": "needle",
    "item_vial": "vial", "item_culprit_evidence": "tube",
}

def token():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([16, 16, S - 16, S - 16], radius=34, fill=TOKEN, outline=BORDER, width=3)
    d.line([34, 30, S - 34, 30], fill=(255, 255, 255, 26), width=2)  # 上ハイライト
    return img, d

def key(d):
    d.ellipse([60, 100, 116, 156], outline=INK, width=10)
    d.line([112, 128, 196, 128], fill=INK, width=10)
    d.line([176, 128, 176, 150], fill=INK, width=8)
    d.line([196, 128, 196, 146], fill=INK, width=8)

def knob(d):
    d.ellipse([96, 78, 176, 158], outline=INK, width=9)
    d.line([136, 158, 136, 184], fill=INK, width=12)
    d.rounded_rectangle([108, 182, 164, 198], radius=4, outline=INK, width=6)

def _doc(d, torn=False, x0=82, y0=54, x1=174, y1=202):
    pts = [(x0, y0), (x1 - 18, y0), (x1, y0 + 18), (x1, y1), (x0, y1)]
    d.polygon(pts, outline=INK, width=6)
    d.line([(x1 - 18, y0), (x1 - 18, y0 + 18), (x1, y0 + 18)], fill=INK, width=5)  # 折れ角
    for k in range(4):
        yy = y0 + 40 + k * 28
        d.line([x0 + 16, yy, x1 - 16, yy], fill=INK2, width=4)
    if torn:
        d.rectangle([x0 - 2, y1 - 30, x1 + 2, y1 + 6], fill=(0, 0, 0, 0))
        zig = []
        for i in range(9):
            zig.append((x0 + i * (x1 - x0) / 8, y1 - 28 + (10 if i % 2 else -6)))
        d.line(zig, fill=INK, width=6)

def paper(d): _doc(d)
def paper_half(d): _doc(d, torn=True)
def pass_(d):
    _doc(d)
    d.ellipse([120, 150, 162, 192], outline=RED, width=6)
def pass_valid(d):
    _doc(d)
    d.ellipse([118, 146, 164, 192], outline=RED, width=6)
    d.line([128, 170, 140, 184], fill=RED, width=7)
    d.line([140, 184, 158, 156], fill=RED, width=7)

def stamp(d):
    d.rounded_rectangle([116, 56, 152, 120], radius=10, outline=INK, width=7)   # 柄
    d.rounded_rectangle([92, 120, 176, 150], radius=6, outline=INK, width=7)    # 台
    d.ellipse([108, 170, 160, 200], outline=RED, width=6)                       # 朱印

def _syringe(d, filled=False, needle=True):
    d.rounded_rectangle([74, 116, 178, 142], radius=6, outline=INK, width=6)    # 筒
    if filled:
        d.rectangle([80, 122, 150, 136], fill=AMBER)
    d.line([74, 129, 40, 129], fill=INK, width=7)                               # 押し棒
    d.line([40, 118, 40, 140], fill=INK, width=8)                               # 親指当て
    if needle:
        d.line([178, 129, 220, 129], fill=METAL, width=4)
        d.line([178, 122, 188, 136], fill=INK, width=6)                         # 針基
def syr_empty(d): _syringe(d, filled=False, needle=False)
def syr_loaded(d): _syringe(d, filled=False, needle=True)
def syr_full(d): _syringe(d, filled=True, needle=True)

def needle(d):
    d.polygon([(70, 118), (96, 124), (96, 134), (70, 140)], outline=INK, width=5)  # 針基
    d.line([96, 129, 210, 129], fill=METAL, width=4)

def vial(d):
    d.rounded_rectangle([108, 70, 148, 92], radius=4, outline=INK, width=6)     # 首
    d.rounded_rectangle([96, 92, 160, 196], radius=14, outline=INK, width=6)    # 胴
    d.rounded_rectangle([102, 150, 154, 190], radius=10, fill=AMBER)            # 薬液
    d.rectangle([112, 60, 144, 72], outline=INK, width=5)                       # 蓋

def tube(d):
    d.rounded_rectangle([100, 64, 156, 198], radius=24, outline=METAL, width=7) # 円筒
    d.ellipse([100, 56, 156, 84], outline=METAL, width=6)                       # 上面
    d.line([116, 92, 116, 176], fill=(255, 255, 255, 90), width=5)              # ハイライト

DRAW = {"key": key, "knob": knob, "paper": paper, "paper_half": paper_half,
        "pass": pass_, "pass_valid": pass_valid, "stamp": stamp,
        "syr_empty": syr_empty, "syr_loaded": syr_loaded, "syr_full": syr_full,
        "needle": needle, "vial": vial, "tube": tube}

def make(cat):
    img, d = token()
    DRAW.get(cat, lambda dd: dd.ellipse([110, 110, 146, 146], outline=INK, width=8))(d)
    return img

def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for item_id, cat in CAT.items():
        make(cat).save(os.path.join(OUT, f"{item_id}.png"), optimize=True)
        n += 1
    print(f"generated {n} item icons -> {OUT}")

if __name__ == "__main__":
    main()
