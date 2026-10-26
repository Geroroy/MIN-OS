#!/usr/bin/env python3
"""밤 단청 배경 생성 (절차적, Pillow): 먹빛 소나무 녹색 바탕 + 전통 운문(雲紋) 윤곽 타일 + 오른쪽 위 연화 자리.
사용: python3 design/tools/make_wallpaper.py OUT.png [W H]   (기본 1920×1080). 저장소에는 결과 PNG 를 커밋한다."""
import math, sys
from PIL import Image, ImageDraw

out = sys.argv[1] if len(sys.argv) > 1 else "wallpaper.png"
W = int(sys.argv[2]) if len(sys.argv) > 2 else 1920
H = int(sys.argv[3]) if len(sys.argv) > 3 else 1080
BG_TOP, BG_BOT = (0x0F, 0x26, 0x22), (0x12, 0x2E, 0x29)
INK = (0x1F, 0x4A, 0x41)        # 운문 윤곽 (낮은 대비)
INK2 = (0x2A, 0x5C, 0x51)
OCHRE = (0xED, 0xC4, 0x86)

img = Image.new("RGB", (W, H), BG_TOP)
d = ImageDraw.Draw(img)
for y in range(H):  # 세로 그러데이션
    t = y / max(1, H - 1)
    col = tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOT))
    d.line([(0, y), (W, y)], fill=col)

def cloud(cx, cy, s, ink):
    """전통 운문: 세 개의 둥근 봉우리 + 꼬리. s = 단위 크기."""
    pts = [(cx - 1.6 * s, cy + 0.2 * s), (cx + 1.6 * s, cy + 0.2 * s)]
    d.line(pts, fill=ink, width=2)
    for ox, r in ((-0.9, 0.55), (0, 0.8), (0.9, 0.55)):
        d.arc([cx + ox * s - r * s, cy + 0.2 * s - 2 * r * s, cx + ox * s + r * s, cy + 0.2 * s], 180, 360, fill=ink, width=2)
    d.arc([cx + 1.6 * s, cy - 0.5 * s, cx + 2.6 * s, cy + 0.2 * s], 180, 300, fill=ink, width=2)  # 꼬리
    d.arc([cx - 2.6 * s, cy - 0.3 * s, cx - 1.6 * s, cy + 0.3 * s], 240, 360, fill=ink, width=2)

s = max(18, W // 60)
step_x, step_y = int(s * 7.5), int(s * 4.2)
row = 0
for y in range(-step_y, H + step_y, step_y):
    off = (step_x // 2) if row % 2 else 0
    for x in range(-step_x, W + step_x, step_x):
        cloud(x + off, y, s, INK if (row // 2) % 2 == 0 else INK2)
    row += 1

# 오른쪽 위: 큰 원 안의 연화 (황토 윤곽, 낮은 불투명도 느낌을 위해 어두운 황토)
cx, cy, R = W - W // 7, H // 5, min(W, H) // 6
dim = tuple(round(a * 0.35 + b * 0.65) for a, b in zip(OCHRE, BG_TOP))
d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=dim, width=3)
for i in range(8):  # 꽃잎 8장
    a0 = i * 45
    r1, r2 = R * 0.25, R * 0.78
    pts = []
    for k in range(0, 61):
        t = k / 60
        ang = math.radians(a0 - 20 + 40 * t)
        rr = r1 + (r2 - r1) * math.sin(math.pi * t)
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.line(pts, fill=dim, width=2)
d.ellipse([cx - R * 0.18, cy - R * 0.18, cx + R * 0.18, cy + R * 0.18], outline=dim, width=2)
img.save(out, optimize=True)
print(out, W, H)
