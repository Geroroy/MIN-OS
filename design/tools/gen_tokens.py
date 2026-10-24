#!/usr/bin/env python3
"""하그라 디자인 토큰 생성기.

단일 원본 design/tokens/hagra.tokens.json 에서 다음을 생성한다.
  libs/minui/qml/MinUI/Theme.qml     QML 앱 내부 UI (MinUI)
  session/labwc/themerc-override     labwc 서버 측 창 장식·메뉴·OSD
  session/foot/foot.ini              foot 터미널 색상

사용:  python3 design/tools/gen_tokens.py            # 생성
       python3 design/tools/gen_tokens.py --check    # 생성 결과와 저장소 파일이 다르면 실패 (CI/테스트용)
       python3 design/tools/gen_tokens.py --tokens path/to/other.tokens.json
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_TOKENS = os.path.join(REPO, "design", "tokens", "hagra.tokens.json")
HEADER = "생성된 파일 — 직접 수정하지 말 것. 원본: design/tokens/hagra.tokens.json, 생성기: design/tools/gen_tokens.py"


def q(s):  # QML 문자열 리터럴
    return json.dumps(s, ensure_ascii=False)


def theme_qml(t):
    c, s, f, w, b, m = t["color"], t["size"], t["font"], t["window"], t["brand"], t["motion"]
    lines = [
        f"// {HEADER}",
        f"// 토큰 세트: {t['_meta']['name']} (status: {t['_meta']['status']})",
        "pragma Singleton",
        "import QtQuick",
        "",
        "QtObject {",
        "    // 식별",
        f"    readonly property string tokenSet: {q(t['_meta']['name'])}",
        f"    readonly property string tokenStatus: {q(t['_meta']['status'])}",
        f"    readonly property string brandName: {q(b['name'])}",
        f"    readonly property string brandNameLatin: {q(b['name_latin'])}",
        "",
        "    // 색상",
    ]
    for k, v in c.items():
        if k.startswith("_"):
            continue
        lines.append(f"    readonly property color {k}: {q(v)}")
    lines += ["", "    // 창 장식 (labwc 와 공유하는 값; QML 미리보기 모형·앱 내부 장식에서 사용)"]
    for k in ("activeBorder", "inactiveBorder", "activeTitleBg", "inactiveTitleBg", "activeTitleText", "inactiveTitleText", "buttonHoverBg"):
        lines.append(f"    readonly property color window{k[0].upper()}{k[1:]}: {q(w[k])}")
    lines.append(f"    readonly property int windowBorderWidth: {w['borderWidth']}")
    lines.append(f"    readonly property int windowCornerRadius: {w.get('cornerRadius', 0)}")
    lines += ["", "    // 치수 (QML 논리 픽셀, 배율 1.0 기준)"]
    for k, v in s.items():
        if k.startswith("_"):
            continue
        lines.append(f"    readonly property int {k}: {v}")
    lines += [
        "",
        "    // 글꼴",
        f"    readonly property string fontFamily: {q(f['family'])}",
        f"    readonly property string fontFamilyKo: {q(f['familyKo'])}",
        f"    readonly property string monoFamily: {q(f['monoFamily'])}",
        f"    readonly property int fontSize: {f['size']}",
        f"    readonly property int fontSizeSmall: {f['sizeSmall']}",
        f"    readonly property int fontSizeTitle: {f['sizeTitle']}",
        f"    readonly property real lineHeight: {f['lineHeight']}",
        "",
        "    // 움직임",
        f"    readonly property int motionDuration: {m['durationMs']}",
        "",
        "    // 모듈 자산: libs/minui/qml/MinUI/assets/<name>.svg (모듈과 함께 설치됨). 원본: design/hagra-dancheong-v1/assets/",
        "    function asset(name) { return Qt.resolvedUrl(\"assets/\" + name + \".svg\") }",
        "    // 외부 아이콘 디렉터리(선택): HAGRA_ICON_PATH / --icons. 없으면 빈 문자열 → MIcon 이 자리 표시자를 그린다.",
        "    property string iconBasePath: \"\"",
        "    function iconSource(name) { return iconBasePath.length ? iconBasePath + \"/\" + name + \".svg\" : \"\" }",
        "}",
        "",
    ]
    return "\n".join(lines)


def themerc(t):
    w, m, o = t["window"], t["menu"], t["osd"]
    return f"""# {HEADER}
# labwc themerc — 하그라 창 장식 (토큰 세트: {t['_meta']['name']})
border.width: {w['borderWidth']}
padding.height: {w['titlePaddingY']}
padding.width: {w['titlePaddingX']}

window.active.border.color: {w['activeBorder']}
window.inactive.border.color: {w['inactiveBorder']}
window.active.title.bg.color: {w['activeTitleBg']}
window.inactive.title.bg.color: {w['inactiveTitleBg']}
window.active.label.text.color: {w['activeTitleText']}
window.inactive.label.text.color: {w['inactiveTitleText']}
window.label.text.justify: {w['titleJustify']}

window.active.button.unpressed.image.color: {w['activeTitleText']}
window.inactive.button.unpressed.image.color: {w['inactiveTitleText']}
window.active.button.hover.bg.color: {w['buttonHoverBg']}
window.inactive.button.hover.bg.color: {w.get('inactiveButtonHoverBg', w['buttonHoverBg'])}

menu.border.width: {m['borderWidth']}
menu.border.color: {m['border']}
menu.items.bg.color: {m['bg']}
menu.items.text.color: {m['text']}
menu.items.active.bg.color: {m['activeBg']}
menu.items.active.text.color: {m['activeText']}
menu.separator.color: {m['separator']}
menu.separator.width: 1
menu.items.padding.x: {m['paddingX']}
menu.items.padding.y: {m['paddingY']}

osd.bg.color: {o['bg']}
osd.border.color: {o['border']}
osd.border.width: {o['borderWidth']}
osd.label.text.color: {o['text']}
osd.window-switcher.width: {o['switcherWidth']}
osd.window-switcher.padding: {o['switcherPadding']}
osd.window-switcher.item.padding.x: {o['itemPaddingX']}
osd.window-switcher.item.padding.y: {o['itemPaddingY']}
osd.window-switcher.item.active.border.width: {o['itemActiveBorderWidth']}

snapping.overlay.region.bg.color: {o['snapOverlay']}
snapping.overlay.edge.bg.color: {o['snapOverlay']}
"""


def foot_ini(t):
    c = t["terminal"]
    reg = "\n".join(f"regular{i}={v}" for i, v in enumerate(c["regular"]))
    bri = "\n".join(f"bright{i}={v}" for i, v in enumerate(c["bright"]))
    return f"""# {HEADER}
# 하그라 기본 터미널(foot) 설정 — /etc/xdg/foot/foot.ini
[main]
font={c['font']}
pad=8x8
term=xterm-256color
title=Terminal
app-id=org.codeberg.dnkl.foot

[scrollback]
lines=10000

[cursor]
style=block
blink=no

[csd]
preferred=server

[colors]
background={c['background']}
foreground={c['foreground']}
{reg}
{bri}
selection-background={c['selectionBackground']}
selection-foreground={c['selectionForeground']}
"""


TARGETS = {
    "libs/minui/qml/MinUI/Theme.qml": theme_qml,
    "session/labwc/themerc-override": themerc,
    "session/foot/foot.ini": foot_ini,
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tokens", default=DEFAULT_TOKENS)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    with open(a.tokens, encoding="utf-8") as fh:
        t = json.load(fh)
    drift = []
    for rel, fn in TARGETS.items():
        path = os.path.join(REPO, rel)
        new = fn(t)
        try:
            old = open(path, encoding="utf-8").read()
        except FileNotFoundError:
            old = None
        if a.check:
            if old != new:
                drift.append(rel)
            continue
        if old != new:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new)
            print("wrote", rel)
        else:
            print("unchanged", rel)
    if a.check:
        if drift:
            print("TOKEN DRIFT: 다음 파일이 토큰 원본과 다릅니다 (python3 design/tools/gen_tokens.py 로 재생성):")
            for d in drift:
                print("  ", d)
            sys.exit(1)
        print("ok: generated files match design/tokens/hagra.tokens.json")


if __name__ == "__main__":
    main()
