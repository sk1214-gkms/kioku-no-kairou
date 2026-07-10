#!/usr/bin/env python
"""SD生成画像(2:3等)を中央9:16(360:640)にトリミングして部屋背景として配置する。

使い方:
  python tools/crop_916.py <入力png> <出力png> [--shift-x PX]

- 中央基準で 9:16 に切り出す（幅が余る画像は左右を均等にカット）。
- --shift-x で切り出し中心を左右にずらせる（右方向+）。被写体が中央から外れている時に。
"""
import sys
from PIL import Image

TARGET_RATIO = 360 / 640  # 9:16 = 0.5625


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    src, dst = sys.argv[1], sys.argv[2]
    shift_x = 0
    if "--shift-x" in sys.argv:
        shift_x = int(sys.argv[sys.argv.index("--shift-x") + 1])

    im = Image.open(src).convert("RGB")
    w, h = im.size
    ratio = w / h
    if ratio > TARGET_RATIO:
        # 横長 → 幅を詰める
        new_w = round(h * TARGET_RATIO)
        left = (w - new_w) // 2 + shift_x
        left = max(0, min(left, w - new_w))
        box = (left, 0, left + new_w, h)
    else:
        # 縦長 → 高さを詰める
        new_h = round(w / TARGET_RATIO)
        top = (h - new_h) // 2
        top = max(0, min(top, h - new_h))
        box = (0, top, w, top + new_h)
    out = im.crop(box)
    out.save(dst)
    print(f"{src} {im.size} -> {dst} {out.size} (box={box}, shift_x={shift_x})")


if __name__ == "__main__":
    main()
