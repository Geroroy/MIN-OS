#!/usr/bin/env python3
"""하그라 테마 팩 조립기.

design/themes/<id>/theme.json (상대 경로로 토큰·자산·배경·미리보기를 가리킴) →
OUT/<id>/ 에 자급 팩을 만든다:
  theme.json      (팩 안의 상대 경로로 정규화: tokens.json, assets/, wallpaper.png, preview.png, labwc/themerc)
  tokens.json     저장소 토큰 스키마 (design/tokens/hagra.tokens.json 과 같은 구조)
  assets/*.svg    장식·폴더·문서 자산 (테마별)
  wallpaper.png   사전 렌더링 배경
  preview.png     설정 화면 미리보기 (저장소의 사전 렌더링 480×270, design/tools/make_previews.py)
  labwc/themerc   gen_tokens.py 의 themerc 생성 결과 (labwc 가 지원하는 키만)
  foot/foot.ini   터미널 팔레트 (토큰에 terminal 이 있을 때). 셸이 foot -c <state>/foot.ini 로 띄운다
  theme.json 에 appearance(light|dark) 와 accents(포인트 색 변형) 도 복사된다

사용: python3 design/tools/build_themes.py OUT_DIR        (CMake 가 build/themes 로 호출)
      python3 design/tools/build_themes.py OUT_DIR --check (팩이 최신인지 확인; 아니면 1)
설치 위치: /usr/share/hagra/themes/<id>/ (CMake install). 런타임은 libs/hagratheme 의 ThemeManager 가 읽는다.
"""
import json
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
THEMES_SRC = os.path.join(REPO, "design", "themes")
sys.path.insert(0, HERE)
import gen_tokens  # noqa: E402


def resolve(base, rel):
    return os.path.normpath(os.path.join(os.path.dirname(base), rel))


def copy_if_changed(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst) and open(src, "rb").read() == open(dst, "rb").read():
        return False
    shutil.copyfile(src, dst)
    return True


def write_if_changed(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path) and open(path, "rb").read() == data:
        return False
    with open(path, "wb") as fh:
        fh.write(data)
    return True


def build_preview(src, dst):
    # 미리보기는 저장소에 사전 렌더링된 PNG(design/themes/<id>/preview.png, make_previews.py)를 그대로 복사한다 (이미지 빌드 환경에 Pillow 없음)
    return copy_if_changed(src, dst)


def build(out, check=False):
    changed = []
    ids = []
    for name in sorted(os.listdir(THEMES_SRC)):
        meta_path = os.path.join(THEMES_SRC, name, "theme.json")
        if not os.path.isfile(meta_path):
            continue
        meta = json.load(open(meta_path, encoding="utf-8"))
        tid = meta["id"]
        if tid != name:
            raise SystemExit(f"theme id {tid!r} must match directory name {name!r}")
        ids.append(tid)
        dst = os.path.join(out, tid)
        tokens_src = resolve(meta_path, meta["tokens"])
        tokens = json.load(open(tokens_src, encoding="utf-8"))
        if tokens.get("_meta", {}).get("themeId", tid) != tid:
            raise SystemExit(f"{tokens_src}: _meta.themeId != {tid}")
        if copy_if_changed(tokens_src, os.path.join(dst, "tokens.json")):
            changed.append(f"{tid}/tokens.json")
        # 자산
        assets_src = resolve(meta_path, meta["assets"])
        for f in sorted(os.listdir(assets_src)):
            if f.endswith(".svg") and f != "wallpaper.svg":
                if copy_if_changed(os.path.join(assets_src, f), os.path.join(dst, "assets", f)):
                    changed.append(f"{tid}/assets/{f}")
        if copy_if_changed(resolve(meta_path, meta["wallpaper"]), os.path.join(dst, "wallpaper.png")):
            changed.append(f"{tid}/wallpaper.png")
        if build_preview(resolve(meta_path, meta["preview"]), os.path.join(dst, "preview.png")):
            changed.append(f"{tid}/preview.png")
        if write_if_changed(os.path.join(dst, "labwc", "themerc"), gen_tokens.themerc(tokens).encode("utf-8")):
            changed.append(f"{tid}/labwc/themerc")
        if "terminal" in tokens and write_if_changed(os.path.join(dst, "foot", "foot.ini"), gen_tokens.foot_ini(tokens).encode("utf-8")):
            changed.append(f"{tid}/foot/foot.ini")
        pack_meta = {
            "id": tid, "displayName": meta["displayName"], "description": meta.get("description", ""),
            "default": bool(meta.get("default", False)),
            "tokens": "tokens.json", "assets": "assets", "wallpaper": "wallpaper.png", "preview": "preview.png",
            "labwcThemerc": "labwc/themerc",
            "footConfig": "foot/foot.ini" if "terminal" in tokens else "",
            "wallpaperFill": tokens["color"]["bg"],
            "appearance": meta.get("appearance", "light"),
            **{k: v for k, v in meta.items() if k.startswith("displayName_") or k.startswith("description_")},
            "accents": meta.get("accents", []),
        }
        if write_if_changed(os.path.join(dst, "theme.json"), (json.dumps(pack_meta, ensure_ascii=False, indent=2) + "\n").encode("utf-8")):
            changed.append(f"{tid}/theme.json")
    defaults = [i for i in ids if json.load(open(os.path.join(THEMES_SRC, i, "theme.json"), encoding="utf-8")).get("default")]
    if len(defaults) != 1:
        raise SystemExit(f"exactly one theme must be default, got {defaults}")
    if check:
        if changed:
            print("THEME PACKS OUT OF DATE:", *changed, sep="\n  ")
            sys.exit(1)
        print(f"ok: theme packs up to date ({', '.join(ids)})")
    else:
        print(f"themes: {', '.join(ids)} → {out}" + (f" ({len(changed)} files updated)" if changed else " (unchanged)"))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    build(os.path.abspath(sys.argv[1]), check="--check" in sys.argv)
