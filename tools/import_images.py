#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gemini出力画像の取り込みツール — アムネジィ・ケース

data/image/ に置いた生成画像（jpg/png）を一括で：
  1) 右下の Gemini 透かし（星マーク）を、すぐ左の床をコピーして塗り消す
  2) PNG に変換
  3) ファイル名で振り分けて正しいフォルダへ配置
       r<番号>_<方角>[...]  -> assets/images/rooms/   (例: r1_north, r3_north_lit)
       item_*               -> assets/images/items/
       それ以外             -> assets/images/_staging/ (door_*, mem_*, bg_*, ED_*, title_* 等。
                                                        今のエンジンは未使用なので退避)

使い方（プロジェクト直下で）:
    python tools/import_images.py            # data/image/ の全画像を処理
    python tools/import_images.py --keep-watermark   # 透かしを消さずに変換だけ
    python tools/import_images.py --dry-run  # 実際には書き込まず、振り分け予定だけ表示

※ 元画像（data/image/）は消しません。出力先に同名があれば上書きします（git管理下なので復元可）。
※ 透かしの位置・大きさが違う時は下の WATERMARK_BOX を調整してください。
"""

import sys
import re
from pathlib import Path
from PIL import Image

# ── 設定 ──────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = ROOT / "data" / "image"
ROOMS_DIR = ROOT / "assets" / "images" / "rooms"
ITEMS_DIR = ROOT / "assets" / "images" / "items"
STAGING_DIR = ROOT / "assets" / "images" / "_staging"  # 未使用アセットの退避先（pubspec未登録＝ビルドに含まれない）

# 透かし(星マーク)を覆う矩形。画像サイズに対する割合 [x0, y0, x1, y1]。右下を広めに。
WATERMARK_BOX = (0.80, 0.88, 1.00, 1.00)

# 部屋背景のファイル名パターン: r1_north / r12_south / r3_north_lit / r10_east_on など
ROOM_RE = re.compile(r"^r\d+_(north|east|south|west)(_[a-z0-9]+)?$", re.IGNORECASE)
ITEM_RE = re.compile(r"^item_", re.IGNORECASE)


def clean_watermark(img: Image.Image) -> Image.Image:
    """右下の透かし領域を、すぐ左の同じ高さ帯のピクセルで上書きして消す。"""
    img = img.convert("RGB")
    w, h = img.size
    fx0, fy0, fx1, fy1 = WATERMARK_BOX
    x0, y0, x1, y1 = int(w * fx0), int(h * fy0), int(w * fx1), int(h * fy1)
    box_w = x1 - x0
    if box_w <= 0 or y1 - y0 <= 0:
        return img

    # コピー元 = 透かし矩形のすぐ左の同じ高さ帯
    src_x0 = max(0, x0 - box_w)
    src_x1 = src_x0 + box_w
    if src_x1 > x0:  # 画像が狭すぎて左に十分な帯が取れない場合はミラーで代用
        src_x0, src_x1 = 0, box_w
    patch = img.crop((src_x0, y0, src_x1, y1))
    # 自然になじむよう左右反転して貼る（床の流れの不自然な反復を避ける）
    patch = patch.transpose(Image.FLIP_LEFT_RIGHT)
    img.paste(patch, (x0, y0))
    return img


def dest_for(stem: str) -> Path:
    if ROOM_RE.match(stem):
        return ROOMS_DIR
    if ITEM_RE.match(stem):
        return ITEMS_DIR
    return STAGING_DIR


def main(argv):
    keep_wm = "--keep-watermark" in argv
    dry = "--dry-run" in argv

    if not SRC_DIR.is_dir():
        print(f"[!] ソースフォルダがありません: {SRC_DIR}")
        return 1

    exts = {".jpg", ".jpeg", ".png", ".webp"}
    files = sorted(p for p in SRC_DIR.iterdir()
                   if p.is_file() and p.suffix.lower() in exts and not p.name.startswith("_"))
    if not files:
        print(f"[i] 処理対象が見つかりません: {SRC_DIR}")
        return 0

    counts = {"rooms": 0, "items": 0, "staging": 0}
    for src in files:
        stem = src.stem.rstrip(". ")  # 末尾の余分なドット/空白を除去（例: "r4_east." -> "r4_east"）
        dest_dir = dest_for(stem)
        out = dest_dir / (stem + ".png")
        label = {ROOMS_DIR: "rooms", ITEMS_DIR: "items", STAGING_DIR: "staging"}[dest_dir]
        counts[label] += 1

        rel = out.relative_to(ROOT).as_posix()
        if dry:
            print(f"  {src.name:28s} -> {rel}")
            continue

        dest_dir.mkdir(parents=True, exist_ok=True)
        with Image.open(src) as im:
            im = im if keep_wm else clean_watermark(im)
            im.convert("RGB").save(out, "PNG")
        print(f"  [OK] {src.name:28s} -> {rel}")

    print("\n--- 集計 ---")
    print(f"  背景(rooms)   : {counts['rooms']}")
    print(f"  アイテム(items): {counts['items']}")
    print(f"  退避(_staging) : {counts['staging']}  (door_* 等・現エンジン未使用)")
    if dry:
        print("  ※ --dry-run のため書き込みは行っていません")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
