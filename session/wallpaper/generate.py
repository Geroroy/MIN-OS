#!/usr/bin/env python3
"""하그라 임시 배경 생성: 단색 (워드마크 없음). 확정 배경·로고는 design/assets/wallpaper 로 교체한다.
사용: python3 generate.py [out.png] [width] [height] [--wordmark]   (--wordmark: 이전 하그라 블록 글자, 보관용)"""
import sys
from PIL import Image, ImageDraw

args = [a for a in sys.argv[1:] if not a.startswith("--")]
WORDMARK = "--wordmark" in sys.argv
out = args[0] if len(args) > 0 else "graphite.png"
W = int(args[1]) if len(args) > 1 else 1920
H = int(args[2]) if len(args) > 2 else 1080
BG, LINE = (0x1A, 0x1A, 0x1A), (0x3A, 0x3A, 0x3A)

img = Image.new("RGB", (W, H), BG)
d = ImageDraw.Draw(img)
if not WORDMARK:
    img.save(out, optimize=True)
    print(out, W, H, "(plain)")
    sys.exit(0)

# 블록 글자 M I N (각 글자 5x7 격자, 셀 크기 s)
glyphs = {
    "M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X", "X...X", "X...X"],
    "I": ["XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "XXXXX"],
    "N": ["X...X", "XX..X", "X.X.X", "X..XX", "X...X", "X...X", "X...X"],
}
s = max(4, W // 240)          # 1920 → 8px 셀
gap = s * 2
total_w = 3 * 5 * s + 2 * gap
x0 = W - total_w - W // 24     # 오른쪽 아래
y0 = H - 7 * s - H // 14 - 28  # 패널 위
x = x0
for ch in "HAGRA":
    for r, row in enumerate(glyphs[ch]):
        for c, cell in enumerate(row):
            if cell == "X":
                d.rectangle([x + c * s, y0 + r * s, x + (c + 1) * s - 1, y0 + (r + 1) * s - 1], fill=LINE)
    x += 5 * s + gap
# 워드마크 아래 1px 선
d.line([(x0, y0 + 7 * s + s), (x0 + total_w - 1, y0 + 7 * s + s)], fill=LINE)
img.save(out, optimize=True)
print(out, W, H)
