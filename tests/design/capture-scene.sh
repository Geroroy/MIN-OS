#!/bin/bash
# 대표 장면 캡처: 배경 + 셸 패널 + 비활성 창(메모) + 활성 창(파일) [+ 메뉴 | 대화상자]
#   out/design/scene/scene-100-default.png, scene-100-menu.png, scene-100-dialog.png, scene-200-default.png
# 200% 는 컴포지터 출력 배율(wlr-randr --scale 2, 2560x1440 → 논리 1280x720)로 적용되어 labwc 창 장식도 함께 확대된다.
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/scene}; mkdir -p "$OUT"
[ -x "$SHELL_BIN" ] || { echo "minos-shell not built"; exit 2; }
trap hd_stop EXIT
hd_start 1280x720 1
capture() { # $1 = pct, $2 = state
  swaybg -i "$REPO/session/wallpaper/min-graphite.png" -m fit -c '#1a1a1a' >/dev/null 2>&1 &
  "$SHELL_BIN" >/dev/null 2>&1 &
  sleep 2
  "$PREVIEW" "$REPO/design/scenes/NotesScene.qml" >/dev/null 2>&1 &
  sleep 1.5
  "$PREVIEW" "$REPO/design/scenes/FilesScene.qml" --state "$2" >/dev/null 2>&1 &
  sleep "${SETTLE:-4}"
  grim -t png "$OUT/scene-$1-$2.png"
  hd_kill_clients
  echo "captured scene $2 @ $1%"
}
for st in default menu dialog; do capture 100 "$st"; done
hd_mode 2560x1440 2
capture 200 default
echo "PASS: scene captures in $OUT"
