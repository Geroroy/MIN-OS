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


COLOR_KEYS_NOTE = "색상·창 장식·치수·글꼴은 런타임에 ThemeManager(libs/hagratheme) 가 applyTokens() 로 바꿀 수 있다. 아래 값은 기본 테마의 초기값."


def light_icons():
    d = os.path.join(REPO, "libs", "minui", "qml", "MinUI", "assets")
    return sorted(f[:-len("-light.svg")] for f in os.listdir(d) if f.endswith("-light.svg"))


def theme_qml(t):
    c, s, f, w, b, m = t["color"], t["size"], t["font"], t["window"], t["brand"], t["motion"]
    color_keys = [k for k in c if not k.startswith("_")]
    size_keys = [k for k in s if not k.startswith("_")]
    win_keys = ("activeBorder", "inactiveBorder", "activeTitleBg", "inactiveTitleBg", "activeTitleText", "inactiveTitleText", "buttonHoverBg")
    lines = [
        f"// {HEADER}",
        f"// 토큰 세트: {t['_meta']['name']} (status: {t['_meta']['status']}) — 기본 테마. {COLOR_KEYS_NOTE}",
        "pragma Singleton",
        "import QtQuick",
        "",
        "QtObject {",
        "    id: theme",
        "    // 식별",
        f"    readonly property string tokenSet: {q(t['_meta']['name'])}",
        f"    readonly property string tokenStatus: {q(t['_meta']['status'])}",
        f"    readonly property string brandName: {q(b['name'])}",
        f"    readonly property string brandNameLatin: {q(b['name_latin'])}",
        "",
        "    // 현재 테마 (applyTokens 로 바뀐다). themeAssets: 테마 팩 assets/ 의 name → url",
        f"    property string themeId: {q(t['_meta'].get('themeId', t['_meta']['name']))}",
        f"    property string themeName: {q(t['_meta'].get('displayName', ''))}",
        "    property var themeAssets: ({})",
        "",
        "    // 색상",
    ]
    for k in color_keys:
        lines.append(f"    property color {k}: {q(c[k])}")
    lines += ["", "    // 창 장식 (labwc 와 공유하는 값; QML 미리보기 모형·앱 내부 장식에서 사용)"]
    for k in win_keys:
        lines.append(f"    property color window{k[0].upper()}{k[1:]}: {q(w[k])}")
    lines.append(f"    property int windowBorderWidth: {w['borderWidth']}")
    lines.append(f"    property int windowCornerRadius: {w.get('cornerRadius', 0)}")
    lines += ["", "    // 치수 (QML 논리 픽셀, 배율 1.0 기준)"]
    for k in size_keys:
        lines.append(f"    property int {k}: {s[k]}")
    lines += [
        "",
        "    // 글꼴",
        f"    property string fontFamily: {q(f['family'])}",
        f"    property string fontFamilyKo: {q(f['familyKo'])}",
        f"    property string monoFamily: {q(f['monoFamily'])}",
        f"    property int fontSize: {f['size']}",
        f"    property int fontSizeSmall: {f['sizeSmall']}",
        f"    property int fontSizeTitle: {f['sizeTitle']}",
        f"    property real lineHeight: {f['lineHeight']}",
        "",
        "    // 움직임",
        f"    readonly property int motionDuration: {m['durationMs']}",
        "",
        "    // 토큰 키 목록 (applyTokens 가 이 키만 받는다)",
        f"    readonly property var colorKeys: {json.dumps(color_keys)}",
        f"    readonly property var sizeKeys: {json.dumps(size_keys)}",
        f"    readonly property var windowKeys: {json.dumps(list(win_keys))}",
        "",
        "    // 테마 토큰 적용: t = { themeId, displayName, color:{}, window:{}, size:{}, font:{}, assets:{name:url} } (ThemeManager.tokens 형식).",
        "    // 없는 키는 그대로 둔다. 치수는 정수만 받는다.",
        "    function applyTokens(t) {",
        "        if (!t) return",
        "        var i, k",
        "        var c = t.color || {}",
        "        for (i = 0; i < colorKeys.length; ++i) { k = colorKeys[i]; if (c[k] !== undefined) theme[k] = c[k] }",
        "        var w = t.window || {}",
        "        for (i = 0; i < windowKeys.length; ++i) { k = windowKeys[i]; if (w[k] !== undefined) theme[\"window\" + k.charAt(0).toUpperCase() + k.slice(1)] = w[k] }",
        "        if (w.borderWidth !== undefined) windowBorderWidth = w.borderWidth",
        "        if (w.cornerRadius !== undefined) windowCornerRadius = w.cornerRadius",
        "        var s = t.size || {}",
        "        for (i = 0; i < sizeKeys.length; ++i) { k = sizeKeys[i]; if (s[k] !== undefined && isFinite(s[k])) theme[k] = Math.round(s[k]) }",
        "        var f = t.font || {}",
        "        if (f.family) fontFamily = f.family",
        "        if (f.familyKo) fontFamilyKo = f.familyKo",
        "        if (f.monoFamily) monoFamily = f.monoFamily",
        "        if (f.size) fontSize = f.size",
        "        if (f.sizeSmall) fontSizeSmall = f.sizeSmall",
        "        if (f.sizeTitle) fontSizeTitle = f.sizeTitle",
        "        if (f.lineHeight) lineHeight = f.lineHeight",
        "        themeAssets = t.assets || ({})",
        "        if (t.themeId) themeId = t.themeId",
        "        if (t.displayName) themeName = t.displayName",
        "    }",
        "",
        "    // 자산: 1) 현재 테마 팩 assets/<name>.svg  2) 모듈 assets/<name>.svg (libs/minui/qml/MinUI/assets, 모듈과 함께 설치)",
        "    function asset(name) { var u = themeAssets[name]; return u ? u : Qt.resolvedUrl(\"assets/\" + name + \".svg\") }",
        "    // 외부 아이콘 디렉터리(선택): HAGRA_ICON_PATH / --icons. 없으면 빈 문자열 → MIcon 이 자리 표시자를 그린다.",
        "    property string iconBasePath: \"\"",
        "    function iconSource(name) { return iconBasePath.length ? iconBasePath + \"/\" + name + \".svg\" : \"\" }",
        "    // 분백 잉크 변형(<name>-light.svg)이 있는 조작 아이콘 (생성 시 모듈 assets/ 를 스캔). MIcon { light: true } 가 이 목록에 있을 때만 변형을 찾는다.",
        f"    readonly property var lightIcons: {json.dumps(light_icons())}",
        "    // 어두운 면 판정 (패널·사이드바 위의 글자·아이콘·포커스 링 선택용). c 는 color 값.",
        "    function isDark(c) { return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) < 0.5 }",
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
    ap.add_argument("--themerc", metavar="OUT", help="토큰 파일의 labwc themerc 만 OUT 에 쓴다 (테마 팩 조립용, 저장소 파일은 건드리지 않음)")
    a = ap.parse_args()
    with open(a.tokens, encoding="utf-8") as fh:
        t = json.load(fh)
    if a.themerc:
        os.makedirs(os.path.dirname(os.path.abspath(a.themerc)) or ".", exist_ok=True)
        with open(a.themerc, "w", encoding="utf-8") as fh:
            fh.write(themerc(t))
        return
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
