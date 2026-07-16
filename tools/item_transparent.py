#!/usr/bin/env python
"""アイテム画像（フラットなグレー背景＋インク輪郭）を透過PNGにする。

- 四隅/四辺から floodfill で“背景に繋がったグレー”だけを抜く（内部の陰影は残す＝穴あき防止）。
- 右下の✦ウォーターマークを除去（右下14%を透明化）。
- 主役の bbox にトリミング → 最大256pxに縮小 → 透過PNG保存。
- --split left/right で、割れた紙などを左右半分に切り出す（対で組み合わさる用）。

使い方:
  python tools/item_transparent.py <入力> <出力.png> [--split left|right] [--max 256]
"""
import sys
from PIL import Image, ImageDraw, ImageChops


def keep_largest(alpha):
    """透過マスクの最大連結成分だけを残す（残留背景の島・✦透かしを除去）。"""
    w, h = alpha.size
    scale = min(1.0, 420 / max(w, h))
    sw, sh = max(1, int(w * scale)), max(1, int(h * scale))
    small = alpha.resize((sw, sh), Image.NEAREST)
    px = small.load()
    seen = bytearray(sw * sh)
    best, best_size = None, 0
    for sy in range(sh):
        for sx in range(sw):
            if px[sx, sy] > 0 and not seen[sy * sw + sx]:
                stack, comp = [(sx, sy)], []
                seen[sy * sw + sx] = 1
                while stack:
                    cx, cy = stack.pop()
                    comp.append((cx, cy))
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < sw and 0 <= ny < sh and \
                                not seen[ny * sw + nx] and px[nx, ny] > 0:
                            seen[ny * sw + nx] = 1
                            stack.append((nx, ny))
                if len(comp) > best_size:
                    best_size, best = len(comp), comp
    if not best:
        return alpha
    keep_small = Image.new('L', (sw, sh), 0)
    kp = keep_small.load()
    for cx, cy in best:
        kp[cx, cy] = 255
    keep_big = keep_small.resize((w, h), Image.NEAREST)
    return ImageChops.multiply(alpha, keep_big)


def remove_bg(src, thresh=170, fill_holes=False):
    base = Image.open(src).convert('RGB')
    w, h = base.size
    flood = base.copy()
    # 背景色サンプル（四隅の平均）
    cs = [base.getpixel(p) for p in
          ((2, 2), (w - 3, 2), (2, h - 3), (w - 3, h - 3))]
    bg = tuple(sum(c[i] for c in cs) // len(cs) for i in range(3))
    key = (255, 0, 255)
    # 境界を細かくシードして floodfill（グラデ背景でも局所シェードごとに抜ける）。
    # 物体は太い黒インク輪郭で囲まれているので、輪郭を越えて内部へは漏れない。
    seeds = []
    step = max(6, w // 24)
    for x in range(2, w - 2, step):
        seeds += [(x, 2), (x, h - 3)]
    for y in range(2, h - 2, step):
        seeds += [(2, y), (w - 3, y)]
    for s in seeds:
        ImageDraw.floodfill(flood, s, key, thresh=thresh)
    alpha = Image.new('L', (w, h))
    alpha.putdata([0 if px == key else 255 for px in flood.getdata()])
    if fill_holes:
        # 輪郭に囲まれた背景色の穴（針金の輪の内側など）を色一致で除去。
        # グレー地の金属アイテムには使わないこと（本体に穴が空くため）。
        ap = alpha.load()
        bp = base.load()
        for y in range(h):
            for x in range(w):
                if ap[x, y]:
                    r, g, b = bp[x, y]
                    if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) < 110:
                        ap[x, y] = 0
    # 最大連結成分だけ残す＝残留背景の島＆右下の✦透かし（孤立小島）を自動除去。
    alpha = keep_largest(alpha)
    img = base.convert('RGBA')
    img.putalpha(alpha)
    bbox = alpha.getbbox()
    return img.crop(bbox) if bbox else img


def fit(im, mx):
    w, h = im.size
    s = min(mx / w, mx / h, 1.0)
    return im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    src, dst = sys.argv[1], sys.argv[2]
    split = None
    mx = 256
    thresh = 170
    if '--split' in sys.argv:
        split = sys.argv[sys.argv.index('--split') + 1]
    if '--max' in sys.argv:
        mx = int(sys.argv[sys.argv.index('--max') + 1])
    if '--thresh' in sys.argv:
        thresh = int(sys.argv[sys.argv.index('--thresh') + 1])
    fill_holes = '--fill-holes' in sys.argv
    paper = remove_bg(src, thresh, fill_holes)
    w, h = paper.size
    if split == 'left':
        paper = paper.crop((0, 0, int(w * 0.56), h))
    elif split == 'right':
        paper = paper.crop((int(w * 0.44), 0, w, h))
    # 分割後に再度 bbox で余白を詰める
    bb = paper.getchannel('A').getbbox()
    if bb:
        paper = paper.crop(bb)
    out = fit(paper, mx)
    out.save(dst)
    print(f"{src} -> {dst} {out.size} split={split}")


if __name__ == '__main__':
    main()
