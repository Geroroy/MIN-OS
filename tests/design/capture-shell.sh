#!/bin/bash
# 셸 팝업 캡처 (문서용): 달력 · 소리 · 알림 센터 · 창 메뉴(터미널 하나 띄움) · 위쪽 패널 변형. → out/design/shell/
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/shell$(hd_theme_suffix)}; mkdir -p "$OUT"
[ -x "$SHELL_BIN" ] || { echo "hagra-shell not built"; exit 2; }
trap 'hd_stop; [ -n "${DBUS_PID:-}" ] && kill "$DBUS_PID" 2>/dev/null || true' EXIT
hd_start 1280x720 1
export HOME=$XDG_RUNTIME_DIR/home; mkdir -p "$HOME/.config/hagra"; unset XDG_CONFIG_HOME XDG_STATE_HOME
if command -v dbus-daemon >/dev/null; then
  eval "$(dbus-daemon --session --fork --print-address=1 --print-pid=1 --address="unix:path=$XDG_RUNTIME_DIR/bus" | { read -r a; read -r p; echo "export DBUS_SESSION_BUS_ADDRESS='$a'; DBUS_PID=$p"; })"
fi
swaybg -i "$(hd_wallpaper)" -m fill -c "$(hd_wallpaper_fill)" >/dev/null 2>&1 &
"$SHELL_BIN" > "$OUT/shell.log" 2>&1 &
sleep 2.5
foot --app-id hagra-cap-foot >/dev/null 2>&1 & sleep 1.5
"$SHELL_BIN" --calendar; sleep 1; grim -t png "$OUT/shell-calendar.png"; "$SHELL_BIN" --calendar; sleep 0.3
if command -v busctl >/dev/null && [ -n "${DBUS_PID:-}" ]; then
  busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Notify 'susssasa{sv}i' "하그라 설정" 0 "" "테마가 적용되었습니다" "깊은 단청 · 포인트 색 주홍" 2 "default" "열기" 0 0 >/dev/null
  busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications Notify 'susssasa{sv}i' "배터리" 0 "" "배터리 부족" "남은 용량 9%. 전원을 연결하세요." 0 1 urgency y 2 0 >/dev/null
  sleep 1; grim -t png "$OUT/shell-notifications.png"
  "$SHELL_BIN" --notifications; sleep 1; grim -t png "$OUT/shell-notification-center.png"; "$SHELL_BIN" --notifications; sleep 0.3
fi
# 창 메뉴: 첫 창 항목 위치(시작 버튼 오른쪽 ≈ 140px)에서 우클릭을 흉내낼 수 없으므로 IPC 는 없고, 문서용으로 패널 자체만 캡처
grim -t png "$OUT/shell-panel-with-window.png"
# 위쪽 패널 변형
printf '[panel]\nposition=top\nclockSeconds=true\n' > "$HOME/.config/hagra/panel.conf"; sleep 1.5
"$SHELL_BIN" --toggle-launcher; sleep 1; grim -t png "$OUT/shell-panel-top-launcher.png"; "$SHELL_BIN" --toggle-launcher
rm -f "$HOME/.config/hagra/panel.conf"; sleep 1
"$SHELL_BIN" --quit; sleep 0.5
grep -iE 'qml|TypeError|ReferenceError|Unable|Cannot' "$OUT/shell.log" | grep -v 'hagra\.' | sort | uniq -c && { echo "QML WARNINGS above"; exit 1; } || true
echo "PASS: shell popup captures in $OUT"
