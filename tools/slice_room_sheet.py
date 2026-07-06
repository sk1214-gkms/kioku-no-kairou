#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Geminiで「1枚にまとめて生成した部屋シート」を4方向の背景PNGにスライスする。

狙い：4方向を別々に作るとトーンがブレて「別々の小箱」に見える問題を、
      "1枚に4壁をまとめて生成"（床・天井・光・色が同一生成で揃う）で解決する。

対応レイアウト:
  grid   … 2x2（既定）  左上=北 右上=東 左下=南 右下=西
  hstrip … 横1列×4      左→右で 北・東・南・西（アンロール・パノラマ向き）
  vstrip … 縦4段×1      上→下で 北・東・南・西

各セルは 9:16（縦）に中央クロップ→指定サイズにリサイズして保存。
（アプリは360x640=9:16にcover表示なので、9:16に揃えるとホットスポットと完全一致）

使い方:
  python tools/slice_room_sheet.py <sheet.png> --room r1
  python tools/slice_room_sheet.py sheet.png --room r3 --layout grid --gutter 8
  python tools/slice_room_sheet.py sheet.png --room r3 --suffix lit      # 状態差分 r3_north_lit.png ...
  python tools/slice_room_sheet.py sheet.png --room r1 --order north,east,south,west

依存: Pillow  (pip install pillow)
"""
import os
import sys
import argparse
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "images", "rooms")
TARGET_AR = 9 / 16  # 幅/高さ


def crop_to_aspect(im, ar=TARGET_AR):
    """中央基準で指定アスペクト比(幅/高さ)に切り抜く。"""
    w, h = im.size
    cur = w / h
    if cur > ar:  # 横に広い → 幅を削る
        nw = max(1, int(round(h * ar)))
        x = (w - nw) // 2
        return im.crop((x, 0, x + nw, h))
    else:         # 縦に長い → 高さを削る
        nh = max(1, int(round(w / ar)))
        y = (h - nh) // 2
        return im.crop((0, y, w, y + nh))


def cell_boxes(size, layout, gutter):
    """レイアウト別に4セルの(left,top,right,bottom)を返す（読み順＝北東南西の並び）。"""
    W, H = size
    g = gutter
    if layout == "grid":
        cw, ch = W // 2, H // 2
        origins = [(0, 0), (cw, 0), (0, ch), (cw, ch)]  # TL,TR,BL,BR
        cells = [(x, y, x + cw, y + ch) for (x, y) in origins]
    elif layout == "hstrip":
        cw, ch = W // 4, H
        cells = [(i * cw, 0, (i + 1) * cw, ch) for i in range(4)]
    elif layout == "vstrip":
        cw, ch = W, H // 4
        cells = [(0, i * ch, cw, (i + 1) * ch) for i in range(4)]
    else:
        raise ValueError(f"unknown layout: {layout}")
    # ガター(パネル間の隙間)を内側に削る
    if g:
        cells = [(l + g, t + g, r - g, b - g) for (l, t, r, b) in cells]
    return cells


def main():
    ap = argparse.ArgumentParser(description="部屋シートを4方向背景にスライス")
    ap.add_argument("sheet", help="Geminiで作った1枚のシート画像パス")
    ap.add_argument("--room", required=True, help="部屋ID 例: r1")
    ap.add_argument("--layout", default="grid", choices=["grid", "hstrip", "vstrip"])
    ap.add_argument("--order", default="north,east,south,west",
                    help="セルを割り当てる方向の並び（読み順に対応）")
    ap.add_argument("--suffix", default="", help="状態差分用の接尾辞 例: lit → r1_north_lit.png")
    ap.add_argument("--size", default="720x1280", help="出力サイズ WxH（既定 720x1280＝9:16）")
    ap.add_argument("--gutter", type=int, default=0, help="パネル間の隙間を内側に削るpx")
    args = ap.parse_args()

    dirs = [d.strip() for d in args.order.split(",") if d.strip()]
    if len(dirs) != 4:
        sys.exit(f"--order は4方向を指定してください（例 north,east,south,west）: {args.order}")
    try:
        tw, th = (int(x) for x in args.size.lower().split("x"))
    except Exception:
        sys.exit(f"--size は WxH 形式で: {args.size}")

    if not os.path.exists(args.sheet):
        sys.exit(f"シート画像が見つかりません: {args.sheet}")
    os.makedirs(OUT_DIR, exist_ok=True)

    im = Image.open(args.sheet).convert("RGB")
    boxes = cell_boxes(im.size, args.layout, args.gutter)
    suffix = f"_{args.suffix}" if args.suffix else ""

    for d, box in zip(dirs, boxes):
        cell = im.crop(box)
        cell = crop_to_aspect(cell, TARGET_AR)
        cell = cell.resize((tw, th), Image.LANCZOS)
        name = f"{args.room}_{d}{suffix}.png"
        path = os.path.join(OUT_DIR, name)
        cell.save(path, optimize=True)
        print(f"  saved {name}  ({box[2]-box[0]}x{box[3]-box[1]} -> {tw}x{th})")

    print(f"done: {args.layout} を {args.room}{suffix} の4方向へ -> {OUT_DIR}")


if __name__ == "__main__":
    main()
