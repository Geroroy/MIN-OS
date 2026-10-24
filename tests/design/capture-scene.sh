#!/bin/bash
# 대표 장면 캡처: 하그라 배경 + 셸 패널 + 비활성 창(설정 예제) + 활성 창(파일 예제) [+ 메뉴 | 대화상자]
#   out/design/scene/scene-100-default.png, scene-100-menu.png, scene-100-dialog.png   (1280×720, 100%)
#   out/design/scene/scene-fhd-default.png                                           (1920×1080, 100%, 메모 창 추가)
#   out/design/scene/scene-200-default.png                                           (2560×1440 @ 200% → 논리 1280×720)
# 200% 는 컴포지터 출력 배율(wlr-randr --scale 2)로 적용되어 labwc 창 장식도 함께 확대된다.
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/scene}; mkdir -p "$OUT"
[ -x "$SHELL_BIN" ] || { echo "minos-shell not built"; exit 2; }
trap hd_stop EXIT
hd_start 1280x720 1
capture() { # $1 = tag, $2 = state, $3 = extra windows (notes)
  swaybg -i "$REPO/session/wallpaper/hagra-dancheong.png" -m fill -c '#E3ECE6' >/dev/null 2>&1 &
  "$SHELL_BIN" >/dev/null 2>&1 &
  sleep 2
  if [ "${3:-}" = "notes" ]; then "$PREVIEW" "$REPO/design/scenes/NotesScene.qml" >/dev/null 2>&1 & sleep 1.5; fi
  "$PREVIEW" "$REPO/design/scenes/SettingsScene.qml" >/dev/null 2>&1 &
  sleep 1.5
  "$PREVIEW" "$REPO/design/scenes/FilesScene.qml" --state "$2" >/dev/null 2>&1 &
  sleep "${SETTLE:-4}"
  grim -t png "$OUT/scene-$1-$2.png"
  hd_kill_clients
  echo "captured scene $2 @ $1"
}
for st in default menu dialog; do capture 100 "$st"; done
hd_mode 1920x1080 1
capture fhd default notes
hd_mode 2560x1440 2
capture 200 default
echo "PASS: scene captures in $OUT"
