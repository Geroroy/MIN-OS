#!/bin/bash
# 설정 앱 페이지 캡처 + QML 경고 수집: 헤드리스 labwc 에서 hagra-settings 를 페이지별로 띄워 스크린샷을 찍는다.
#   out/design/settings/settings-<page>.png, settings.log (QML 경고가 있으면 종료 코드 1)
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/settings$(hd_theme_suffix)}; mkdir -p "$OUT"
SETTINGS=$BUILD/settings/hagra-settings
[ -x "$SETTINGS" ] || { echo "hagra-settings not built"; exit 2; }
trap hd_stop EXIT
hd_start 1280x720 1
export HOME=$XDG_RUNTIME_DIR/home; mkdir -p "$HOME"; unset XDG_CONFIG_HOME XDG_STATE_HOME
export HAGRA_LABWC_CONF=$XDG_RUNTIME_DIR/labwc HAGRA_LABWC_SYSCONF=$REPO/session/labwc
swaybg -i "$(hd_wallpaper)" -m fill -c "$(hd_wallpaper_fill)" >/dev/null 2>&1 &
"$SHELL_BIN" >/dev/null 2>&1 &
sleep 2
: > "$OUT/settings.log"
PAGES=${PAGES:-appearance wallpaper display sound input locale network notifications power accessibility about}
for p in $PAGES; do
  "$SETTINGS" --page "$p" >> "$OUT/settings.log" 2>&1 &
  SP=$!
  sleep "${SETTLE:-3}"
  kill -0 $SP 2>/dev/null || { echo "FAIL: hagra-settings exited on page $p"; cat "$OUT/settings.log"; exit 1; }
  grim -t png "$OUT/settings-$p.png"
  kill $SP 2>/dev/null || true; wait $SP 2>/dev/null || true
  echo "captured settings page $p"
done
if grep -E 'qml|QML|TypeError|ReferenceError|is not a type|Unable to assign|Cannot' "$OUT/settings.log" | grep -v 'hagra.settings' | grep -q .; then
  echo "QML WARNINGS:"; grep -E 'qml|QML|TypeError|ReferenceError|is not a type|Unable to assign|Cannot' "$OUT/settings.log" | grep -v 'hagra.settings' | sort | uniq -c | head -40
  exit 1
fi
echo "PASS: settings pages captured without QML warnings in $OUT"
