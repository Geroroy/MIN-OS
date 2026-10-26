#!/usr/bin/env python3
"""하그라 셸 스크린샷 픽셀 검사. 사용: check_screenshot.py <png> <panel|launcher|power|foot>

기준 색·치수는 design/tokens/hagra.tokens.json (단일 원본) 에서 읽는다. 토큰이 바뀌면 검사 기준도 함께 바뀐다.
배치 기준: shell/qml/Panel.qml (띠 8 + 경계 1 + 콘텐츠), Launcher.qml (440×560), PowerMenu.qml (240 너비).
"""
import json
import os
import sys

from PIL import Image

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# 테마 토큰: --tokens PATH 또는 $HAGRA_CHECK_TOKENS, 기본은 기본 테마(연한 단청) 단일 원본
_tok_path = os.environ.get("HAGRA_CHECK_TOKENS") or os.path.join(REPO, "design", "tokens", "hagra.tokens.json")
if "--tokens" in sys.argv:
    _i = sys.argv.index("--tokens"); _tok_path = sys.argv[_i + 1]; del sys.argv[_i:_i + 2]


def rgb(hexstr):
    h = hexstr.lstrip("#")
    if len(h) == 8:  # AARRGGBB
        h = h[2:]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def load_tokens(path):
    """검사 기준 토큰을 바꾼다 (테마별 검사: 부팅 테스트가 깊은 단청 전환 뒤 호출)."""
    global TOK, C, SURFACE, PANEL, PANEL_DARK, OCHRE, BG, BORDER, BORDER_STRONG, ACCENT, SELECTION, S, PANEL_H, BAND_H, BORDER_W
    with open(path, encoding="utf-8") as f:
        TOK = json.load(f)
    C = TOK["color"]
    SURFACE = rgb(C["surface"])
    PANEL = rgb(C.get("panel", C["surface"]))          # 패널 바탕 (역할 토큰; 없으면 surface)
    PANEL_DARK = (0.299 * PANEL[0] + 0.587 * PANEL[1] + 0.114 * PANEL[2]) < 128
    OCHRE = rgb(C.get("ochre", C["accent"]))
    BG = rgb(C["bg"])
    BORDER = rgb(C["border"])
    BORDER_STRONG = rgb(C["borderStrong"])
    ACCENT = rgb(C["accent"])
    SELECTION = rgb(C["selection"])
    S = TOK["size"]
    PANEL_H = S["panelHeight"]
    BAND_H = S["panelBandHeight"]
    BORDER_W = S["borderWidth"]


load_tokens(_tok_path)
LAUNCHER_W, LAUNCHER_H = 440, 560
POWER_W = 240


def close(a, b, tol=6):
    return all(abs(x - y) <= tol for x, y in zip(a[:3], b[:3]))


def row_mostly(img, y, color, x0=0, x1=None, frac=0.6):
    w = img.width
    x1 = w if x1 is None else x1
    hits = sum(1 for x in range(x0, x1) if close(img.getpixel((x, y)), color))
    return hits / max(1, x1 - x0) >= frac


def row_frac_not(img, y, colors, x0=0, x1=None):
    """행에서 colors 중 어느 것과도 가깝지 않은 픽셀 비율 (문양 존재 검사)."""
    w = img.width
    x1 = w if x1 is None else x1
    miss = sum(1 for x in range(x0, x1) if not any(close(img.getpixel((x, y)), c, 10) for c in colors))
    return miss / max(1, x1 - x0)


def region_mostly(img, x0, y0, x1, y1, color, frac=0.5):
    hits = tot = 0
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            tot += 1
            if close(img.getpixel((x, y)), color):
                hits += 1
    return hits / max(1, tot) >= frac


def fail(msg):
    print("FAIL:", msg)
    sys.exit(1)


def check_panel_frame(img):
    w, h = img.size
    top = h - PANEL_H
    # 장식 띠: 패널 맨 위 8px 는 surface 도 bg 도 아닌 문양 색이 상당 부분 있어야 한다 (띠가 로드됐는지)
    band_rows = [top + BAND_H // 2]
    if not any(row_frac_not(img, y, [PANEL, BG]) >= 0.3 for y in band_rows):
        fail(f"panel ornament band not visible at y={band_rows}")
    # 띠 아래 경계선 (밝은 패널: borderStrong, 어두운 패널: ochre — Panel.qml)
    if not row_mostly(img, top + BAND_H, OCHRE if PANEL_DARK else BORDER_STRONG, frac=0.6):
        fail(f"panel band/content border not found at y={top + BAND_H}")
    # 콘텐츠 영역 바탕 (창 목록 영역은 비어 있으므로 panel 색이 과반)
    body_y = top + BAND_H + BORDER_W + (PANEL_H - BAND_H - BORDER_W) // 2
    if not row_mostly(img, body_y, PANEL, frac=0.4):
        fail(f"panel content background not panel colour {PANEL} at y={body_y}")


def check_panel(img):
    w, h = img.size
    check_panel_frame(img)
    # 패널이 정확히 바닥에 붙어 있어야 함: 띠·경계선이 한 줄 위에는 없어야 한다 (배경색이 패널색과 같은 테마도 있으므로 색 비교 대신 위치 비교)
    top = h - PANEL_H
    line = OCHRE if PANEL_DARK else BORDER_STRONG
    if row_mostly(img, top - 1, line, frac=0.6) or row_frac_not(img, top - BAND_H // 2 - 1, [PANEL, BG]) >= 0.3 and row_mostly(img, top + BAND_H - 1, line, frac=0.6):
        fail("panel band/border found above the expected position: exclusive zone/anchoring wrong?")
    print(f"ok: panel {w}x{PANEL_H} at bottom (band {BAND_H}px + content, theme {TOK['_meta'].get('themeId', '?')})")


def check_launcher(img):
    w, h = img.size
    x0, y0, x1, y1 = 0, h - PANEL_H - LAUNCHER_H, LAUNCHER_W, h - PANEL_H
    if not region_mostly(img, x0 + 4, y0 + 4, x1 - 4, y1 - 4, SURFACE, frac=0.3):
        fail("launcher body not found at bottom-left above panel")
    # 2px 청록 경계: 왼쪽 세로선, 위쪽 가로선 (정확한 y → 패널과 틈이 없어야 한다)
    if not any(close(img.getpixel((x0, y)), BORDER_STRONG) for y in range(y0 + 5, y1 - 5, 7)):
        fail("launcher left border missing")
    if not row_mostly(img, y0, BORDER_STRONG, x0, x1, frac=0.8):
        fail(f"launcher top border not at y={y0}: popup not flush with panel?")
    # 오른쪽 경계(2px borderStrong)가 x1-2..x1-1 에 있고 그 바깥에는 없어야 함 (배경이 surface 와 비슷한 어두운 테마도 판정 가능)
    def col_mostly(x, color, frac=0.6):
        hits = sum(1 for y in range(y0 + 4, y1 - 4) if close(img.getpixel((x, y)), color))
        return hits / max(1, y1 - y0 - 8) >= frac
    if not (col_mostly(x1 - 1, BORDER_STRONG) or col_mostly(x1 - 2, BORDER_STRONG)):
        fail(f"launcher right border not at x={x1 - 1}: launcher not {LAUNCHER_W}px wide?")
    if col_mostly(x1 + 3, BORDER_STRONG) or col_mostly(x1 + 8, BORDER_STRONG):
        fail(f"launcher wider than {LAUNCHER_W}px?")
    # 상단 장식 띠
    if row_frac_not(img, y0 + 2 + S["ornamentBandHeight"] // 2, [SURFACE, BG], x0 + 4, x1 - 4) < 0.3:
        fail("launcher ornament band missing")
    # 선택된 첫 항목: 선택 배경 + accent 막대
    sel = any(close(img.getpixel((x, y)), SELECTION) for y in range(y0, y1, 2) for x in range(x0 + 8, x1 - 8, 8))
    mark = any(close(img.getpixel((x, y)), ACCENT) for y in range(y0, y1, 2) for x in range(x0 + 2, x0 + 8))
    if not (sel and mark):
        fail(f"selected row not visible in launcher (selection bg={sel}, accent marker={mark})")
    print(f"ok: launcher {LAUNCHER_W}x{LAUNCHER_H} at bottom-left, band + selection visible")


def check_power(img):
    w, h = img.size
    x0, x1 = w - POWER_W, w
    y1 = h - PANEL_H
    y0 = y1 - 120  # 아래쪽 일부만 (높이는 콘텐츠에 따라)
    if not region_mostly(img, x0 + 4, y0 + 4, x1 - 4, y1 - 4, SURFACE, frac=0.3):
        fail("power menu body not found at bottom-right above panel")
    if not any(close(img.getpixel((x0, y)), BORDER_STRONG) for y in range(y0 + 5, y1 - 5, 5)):
        fail("power menu left border missing")
    if not row_mostly(img, y1 - 1, BORDER_STRONG, x0, x1, frac=0.8):
        fail(f"power menu bottom border not at y={y1 - 1}: popup not flush with panel?")
    if region_mostly(img, x0 - 100, y0 + 5, x0 - 5, y1 - 5, SURFACE, frac=0.5):
        fail(f"power menu wider than {POWER_W}px?")
    print("ok: power menu at bottom-right")


def check_foot(img):
    w, h = img.size
    # 패널은 여전히 보여야 함 (exclusive zone) — 띠·경계·바탕
    check_panel_frame(img)
    # 작업 표시줄에 활성 창 항목(accent 3px 막대)이 있어야 함: 시작 버튼(≈120px) 오른쪽, 콘텐츠 영역 아래쪽
    ys = range(h - 12, h - 1)
    mark = OCHRE if PANEL_DARK else ACCENT
    found = any(close(img.getpixel((x, y)), mark) for y in ys for x in range(100, 460, 2))
    if not found:
        fail("no active task indicator in panel (foreign-toplevel)")
    print("ok: panel visible with terminal running, task indicator present")


def check_notification(img):
    w, h = img.size
    # 오른쪽 위 모서리 12px 여백 안에 알림 카드(surface 바탕 + borderStrong 테두리)가 있어야 한다 (360 너비)
    x1, y0 = w - 12, 12
    x0 = x1 - 360
    if not region_mostly(img, x0 + 6, y0 + 6, x1 - 6, y0 + 60, SURFACE, frac=0.4):
        fail("notification popup body not found at top-right")
    if not row_mostly(img, y0, BORDER_STRONG, x0, x1, frac=0.7):
        fail(f"notification popup top border not at y={y0}")
    print("ok: notification popup at top-right")


def check_panels2(img):
    """두 출력(각 1280 폭)에 패널이 하나씩: 왼쪽/오른쪽 절반 모두에서 패널 프레임 검사."""
    w, h = img.size
    if w < 2000:
        fail(f"expected a two-output capture, got {w}x{h}")
    for half in (img.crop((0, 0, w // 2, h)), img.crop((w // 2, 0, w, h))):
        check_panel_frame(half)
    print(f"ok: panel on both outputs ({w}x{h})")


def main():
    path, what = sys.argv[1], sys.argv[2]
    img = Image.open(path).convert("RGB")
    {"panel": check_panel, "launcher": check_launcher, "power": check_power, "foot": check_foot,
     "notification": check_notification, "panels2": check_panels2}[what](img)


if __name__ == "__main__":
    main()
