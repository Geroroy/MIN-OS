#!/usr/bin/env python3
"""MIN Shell 스크린샷 픽셀 검사. 사용: check_screenshot.py <png> <panel|launcher|power|foot>

MinUI Theme 토큰(Graphite)과 docs/DESIGN_LANGUAGE.md 치수를 기준으로 검사한다.
"""
import sys
from PIL import Image

SURFACE = (0x24, 0x24, 0x24)
BORDER = (0x3A, 0x3A, 0x3A)
BORDER_STRONG = (0x5C, 0x5C, 0x5C)
ACCENT = (0x3D, 0x7B, 0xD9)
PANEL_H = 28


def close(a, b, tol=6):
    return all(abs(x - y) <= tol for x, y in zip(a[:3], b[:3]))


def row_mostly(img, y, color, x0=0, x1=None, frac=0.6):
    w = img.width
    x1 = w if x1 is None else x1
    hits = sum(1 for x in range(x0, x1) if close(img.getpixel((x, y)), color))
    return hits / max(1, x1 - x0) >= frac


def fail(msg):
    print("FAIL:", msg)
    sys.exit(1)


def check_panel(img):
    w, h = img.size
    # 패널 상단 테두리 1px
    if not row_mostly(img, h - PANEL_H, BORDER):
        fail(f"panel top border not found at y={h-PANEL_H}")
    # 패널 바탕 (중앙 행, 창 목록 영역은 비어 있으므로 surface)
    if not row_mostly(img, h - PANEL_H // 2, SURFACE, frac=0.5):
        fail("panel background not surface colour")
    # 패널 위는 패널 색이 아니어야 함 (labwc 배경)
    if row_mostly(img, h - PANEL_H - 10, SURFACE, frac=0.5):
        fail("area above panel has panel colour: exclusive zone/anchoring wrong?")
    print(f"ok: panel {w}x{PANEL_H} at bottom")


def region_mostly(img, x0, y0, x1, y1, color, frac=0.5):
    hits = tot = 0
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            tot += 1
            if close(img.getpixel((x, y)), color):
                hits += 1
    return hits / max(1, tot) >= frac


def check_launcher(img):
    w, h = img.size
    # 360x440, 왼쪽 아래, 패널 위
    x0, y0, x1, y1 = 0, h - PANEL_H - 440, 360, h - PANEL_H
    if not region_mostly(img, x0 + 2, y0 + 2, x1 - 2, y1 - 2, SURFACE, frac=0.35):
        fail("launcher body not found at bottom-left above panel")
    # 테두리(borderStrong) 왼쪽/위
    if not any(close(img.getpixel((x0, y)), BORDER_STRONG) for y in range(y0 + 5, y1 - 5, 7)):
        fail("launcher left border missing")
    # 오른쪽 바깥은 launcher 색이 아니어야 함
    if region_mostly(img, x1 + 5, y0 + 5, x1 + 100, y1 - 5, SURFACE, frac=0.5):
        fail("launcher wider than 360px?")
    # 선택된 첫 항목(accent) 존재
    if not any(close(img.getpixel((x, y)), ACCENT) for y in range(y0, y1, 2) for x in range(x0 + 4, x1 - 4, 8)):
        fail("no accent-coloured selected row in launcher")
    print("ok: launcher 360x440 at bottom-left, selection visible")


def check_power(img):
    w, h = img.size
    x0, x1 = w - 200, w
    y1 = h - PANEL_H
    # 높이는 콘텐츠에 따라 결정되지만 4행 * 28 ≈ 112 + 테두리
    y0 = y1 - 110
    if not region_mostly(img, x0 + 2, y0 + 2, x1 - 2, y1 - 2, SURFACE, frac=0.35):
        fail("power menu body not found at bottom-right above panel")
    if not any(close(img.getpixel((x0, y)), BORDER_STRONG) for y in range(y0 + 5, y1 - 5, 5)):
        fail("power menu left border missing")
    print("ok: power menu at bottom-right")


def check_foot(img):
    w, h = img.size
    # 패널은 여전히 보여야 함 (exclusive zone)
    if not row_mostly(img, h - PANEL_H, BORDER):
        fail("panel hidden by terminal window: exclusive zone not honoured")
    if not row_mostly(img, h - PANEL_H // 2, SURFACE, frac=0.3):
        fail("panel background covered")
    # 작업 표시줄에 창 항목(활성 accent 2px 선)이 있어야 함: 시작 버튼(≈56px) 오른쪽
    found = any(close(img.getpixel((x, h - 2)), ACCENT) for x in range(60, 60 + 160, 2))
    if not found:
        fail("no active task indicator in panel (foreign-toplevel)")
    # 터미널 창이 패널 위에 그려졌는지 (foot 기본 배경은 어둡고 labwc 배경과 다름) — 제목 표시줄(SSD) 존재 확인은 테마 색으로
    print("ok: panel visible with terminal running, task indicator present")


def main():
    path, what = sys.argv[1], sys.argv[2]
    img = Image.open(path).convert("RGB")
    {"panel": check_panel, "launcher": check_launcher, "power": check_power, "foot": check_foot}[what](img)


if __name__ == "__main__":
    main()
