#!/usr/bin/env python3
"""테마 팩 미리보기 재생성: 대표 장면 캡처 → design/themes/<id>/preview.png (480×270). Pillow 필요 (호스트 전용)."""
import os, sys
from PIL import Image
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PAIRS = {"hagra-dancheong-light": "out/design/scene/scene-100-default.png", "hagra-dancheong-deep": "out/design/scene-deep/scene-100-default.png",
         "hagra-dancheong-night": "out/design/scene-night/scene-100-default.png"}
for tid, src in PAIRS.items():
    s = os.path.join(REPO, src)
    if not os.path.exists(s):
        print("missing capture:", src, "(run tests/design/capture-scene.sh, HAGRA_THEME=... for deep)"); continue
    im = Image.open(s).convert("RGB"); im.thumbnail((480, 270))
    im.save(os.path.join(REPO, "design", "themes", tid, "preview.png"), optimize=True); print("wrote", tid)
