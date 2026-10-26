#!/usr/bin/env python3
"""하그라 테마 대비 검사 (WCAG 2.x 상대 휘도). 모든 테마 팩 토큰과 포인트 색 변형에 대해:
  본문 글자(text/surface, textMuted/surface) ≥ 4.5, 패널·사이드바 글자 ≥ 4.5, 선택 글자(selectionText/selection) ≥ 4.5,
  강조 위 글자(accentText/accent) ≥ 4.5, UI 경계·포커스(accent/surface, focusRing/surface, borderStrong/surface) ≥ 3.0.
사용: python3 design/tools/contrast_check.py [--table]   (실패 시 종료 코드 1; make tokens-check 에 포함)
"""
import json, os, sys
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
THEMES = os.path.join(REPO, "design", "themes")

def lum(h):
    h = h.lstrip("#")
    if len(h) == 8: h = h[2:]
    r, g, b = (int(h[i:i+2], 16) / 255 for i in (0, 2, 4))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

def ratio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

CHECKS = [  # (전경, 배경, 최소, 설명)
    ("text", "surface", 4.5, "본문"), ("textMuted", "surface", 4.5, "보조 글자"), ("text", "surfaceRaised", 4.5, "본문(올린 면)"),
    ("panelText", "panel", 4.5, "패널 글자"), ("panelMuted", "panel", 4.5, "패널 보조"), ("sidebarText", "sidebar", 4.5, "사이드바 글자"),
    ("selectionText", "selection", 4.5, "선택 글자"), ("accentText", "accent", 4.5, "강조 위 글자"),
    ("titleText", "titleActive", 4.5, "활성 제목"), ("titleInactiveText", "titleInactive", 4.5, "비활성 제목"),
    ("accent", "surface", 3.0, "강조/본문면"), ("focusRing", "surface", 3.0, "포커스 링/본문면"), ("borderStrong", "surface", 3.0, "강한 경계/본문면"),
    ("focusRingOnDark", "panel", 3.0, "포커스 링/패널"), ("danger", "surface", 3.0, "위험"), ("warning", "surface", 3.0, "경고"),
]

def main():
    table = "--table" in sys.argv
    fails = []
    rows = []
    for tid in sorted(os.listdir(THEMES)):
        meta_p = os.path.join(THEMES, tid, "theme.json")
        if not os.path.isfile(meta_p): continue
        meta = json.load(open(meta_p, encoding="utf-8"))
        tokens = json.load(open(os.path.normpath(os.path.join(THEMES, tid, meta["tokens"])), encoding="utf-8"))
        variants = [("기본", tokens["color"])]
        for a in meta.get("accents", []):
            c = dict(tokens["color"]); c.update({k: v for k, v in a.items() if k in c}); variants.append((a["id"], c))
        for vname, c in variants:
            for fg, bg, mn, desc in CHECKS:
                if fg not in c or bg not in c: continue
                if fg == "focusRingOnDark" and lum(c["panel"]) >= 0.5: continue   # 밝은 패널은 focusRing 을 쓴다 (MButton.onDark 판정)
                r = ratio(c[fg], c[bg])
                ok = r >= mn
                rows.append((tid, vname, desc, f"{c[fg]}/{c[bg]}", f"{r:.2f}", str(mn), "OK" if ok else "FAIL"))
                if not ok: fails.append((tid, vname, desc, c[fg], c[bg], r, mn))
    if table:
        print("| 테마 | 변형 | 역할 | 색 | 대비 | 최소 | 결과 |\n|---|---|---|---|---|---|---|")
        for r in rows: print("| " + " | ".join(r) + " |")
    if fails:
        print("CONTRAST FAIL:")
        for f in fails: print(f"  {f[0]} [{f[1]}] {f[2]}: {f[3]} on {f[4]} = {f[5]:.2f} < {f[6]}")
        sys.exit(1)
    print(f"ok: contrast {len(rows)} checks passed across {len(set(r[0] for r in rows))} themes")

if __name__ == "__main__":
    main()
