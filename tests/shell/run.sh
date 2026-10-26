#!/bin/bash
# 하그라 셸 헤드리스 통합 테스트
#  - labwc를 헤드리스 백엔드(pixman)로 띄우고 hagra-shell을 실행한다.
#  - grim으로 스크린샷을 찍어 패널·실행 메뉴·전원 메뉴가 제 위치에 그려졌는지 픽셀 단위로 검사한다.
#  - layer-shell exclusive zone 이 적용되는지 foot(터미널) 창을 최대화해 확인한다.
# 사용: tests/shell/run.sh [build-dir]   (기본 build/)
set -euo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd)
BUILD=${1:-$REPO/build}
SHELL_BIN=$BUILD/shell/hagra-shell
OUT=${HAGRA_TEST_OUT:-$BUILD/test-out}
mkdir -p "$OUT"

[ -x "$SHELL_BIN" ] || { echo "hagra-shell not built: $SHELL_BIN (run: make shell)"; exit 2; }
for t in labwc grim foot python3; do command -v $t >/dev/null || { echo "missing tool: $t"; exit 2; }; done

export XDG_RUNTIME_DIR=$(mktemp -d /tmp/hagra-test-XXXXXX)
chmod 700 "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
export QT_QUICK_BACKEND=software
export QT_LOGGING_RULES="hagra.*=true"
export HAGRA_QML_IMPORT_PATH=$REPO/libs/hagraui/qml
export XDG_CURRENT_DESKTOP=HAGRA
export HAGRA_TERMINAL=foot
export HAGRA_SHELL=none   # autostart 의 셸 실행은 건너뛰고 테스트가 직접 실행한다
unset WAYLAND_DISPLAY DISPLAY
# 테마: 사용자 설정을 건드리지 않도록 HOME 을 임시로, 테마 팩은 빌드 디렉터리에서
export HOME=$XDG_RUNTIME_DIR/home; mkdir -p "$HOME"; unset XDG_CONFIG_HOME XDG_STATE_HOME HAGRA_THEME
export HAGRA_THEME_PATH=$BUILD/themes
THEME_BIN=$BUILD/tools/theme/hagra-theme
[ -x "$THEME_BIN" ] || { echo "hagra-theme not built: $THEME_BIN"; exit 2; }

cleanup() {
  pkill -P $$ 2>/dev/null || true
  [ -n "${LABWC_PID:-}" ] && kill "$LABWC_PID" 2>/dev/null || true
  rm -rf "$XDG_RUNTIME_DIR"
}
trap cleanup EXIT

# labwc: -C 설정 디렉터리(하그라 테마), -s 시작 명령은 쓰지 않고 소켓을 직접 기다린다.
labwc -C "$REPO/session/labwc" -d > "$OUT/labwc.log" 2>&1 &
LABWC_PID=$!
for i in $(seq 1 50); do
  sock=$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | grep -v '\.lock$' | head -1 || true)
  [ -n "$sock" ] && break
  sleep 0.1
done
[ -n "${sock:-}" ] || { echo "FAIL: labwc did not create a wayland socket"; cat "$OUT/labwc.log"; exit 1; }
export WAYLAND_DISPLAY=$(basename "$sock")
echo "labwc up on $WAYLAND_DISPLAY (pid $LABWC_PID)"

"$SHELL_BIN" > "$OUT/shell.log" 2>&1 &
SHELL_PID=$!
# 패널이 구성될 때까지 기다린다 (최대 20초; 소프트웨어 렌더링·느린 CI 고려)
for i in $(seq 1 40); do
  grep -q 'layer surface "hagra-panel" configured' "$OUT/shell.log" 2>/dev/null && break
  kill -0 $SHELL_PID 2>/dev/null || { echo "FAIL: hagra-shell exited"; cat "$OUT/shell.log"; exit 1; }
  sleep 0.5
done
sleep 1
grep -q "zwlr_layer_shell_v1 bound" "$OUT/shell.log" || { echo "FAIL: layer shell not bound"; cat "$OUT/shell.log"; exit 1; }
grep -q 'layer surface "hagra-panel" configured' "$OUT/shell.log" || { echo "FAIL: panel not configured"; cat "$OUT/shell.log"; exit 1; }

grim -t png "$OUT/01-panel.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/01-panel.png" panel

# 실행 메뉴 토글 (IPC 경로 검증)
"$SHELL_BIN" --toggle-launcher
sleep 1
grep -q 'layer surface "hagra-launcher" configured' "$OUT/shell.log" || { echo "FAIL: launcher not configured"; cat "$OUT/shell.log"; exit 1; }
grim -t png "$OUT/02-launcher.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/02-launcher.png" launcher
"$SHELL_BIN" --toggle-launcher
sleep 0.5

# 전원 메뉴
"$SHELL_BIN" --power
sleep 1
grep -q 'layer surface "hagra-power" configured' "$OUT/shell.log" || { echo "FAIL: power menu not configured"; cat "$OUT/shell.log"; exit 1; }
grim -t png "$OUT/03-power.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/03-power.png" power
"$SHELL_BIN" --power
sleep 0.5

# exclusive zone: foot 을 최대화하면 패널 영역을 침범하지 않아야 한다 (foreign-toplevel 창 목록도 함께 검사)
foot --app-id hagra-test-foot > "$OUT/foot.log" 2>&1 &
FOOT_PID=$!
sleep 2
kill -0 $FOOT_PID 2>/dev/null || { echo "FAIL: foot did not start"; cat "$OUT/foot.log"; exit 1; }
grim -t png "$OUT/04-foot.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/04-foot.png" foot
kill $FOOT_PID 2>/dev/null || true
sleep 0.5

"$SHELL_BIN" --quit
sleep 0.5
kill -0 $SHELL_PID 2>/dev/null && { echo "FAIL: shell did not quit on --quit"; exit 1; }

# 테마 왕복: 연한 단청(기본) → 깊은 단청 → 연한 단청. CLI 가 설정을 쓰면 실행 중인 셸이 파일 감시로 따라가고 labwc 는 SIGHUP 재구성.
"$SHELL_BIN" > "$OUT/shell-theme.log" 2>&1 &
SHELL_PID=$!
for i in $(seq 1 40); do grep -q 'layer surface "hagra-panel" configured' "$OUT/shell-theme.log" 2>/dev/null && break; sleep 0.5; done
sleep 1
[ "$("$THEME_BIN" current)" = hagra-dancheong-light ] || { echo "FAIL: default theme is not hagra-dancheong-light"; exit 1; }
"$THEME_BIN" apply hagra-dancheong-deep >/dev/null
sleep 2.5
kill -0 $SHELL_PID 2>/dev/null || { echo "FAIL: shell died on theme change"; cat "$OUT/shell-theme.log"; exit 1; }
grep -q 'applied theme tokens "hagra-dancheong-deep"' "$OUT/shell-theme.log" || { echo "FAIL: shell did not pick up the theme change"; cat "$OUT/shell-theme.log"; exit 1; }
[ "$(grep -c 'read theme' "$OUT/labwc.log")" -ge 2 ] || { echo "FAIL: labwc did not reload its theme on reconfigure"; grep -i theme "$OUT/labwc.log"; exit 1; }
grim -t png "$OUT/06-panel-deep.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" --tokens "$BUILD/themes/hagra-dancheong-deep/tokens.json" "$OUT/06-panel-deep.png" panel
"$SHELL_BIN" --toggle-launcher; sleep 1
grim -t png "$OUT/07-launcher-deep.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" --tokens "$BUILD/themes/hagra-dancheong-deep/tokens.json" "$OUT/07-launcher-deep.png" launcher
"$SHELL_BIN" --toggle-launcher; sleep 0.5
# 저장·복원: 새 프로세스가 같은 선택을 읽는다
[ "$("$THEME_BIN" current)" = hagra-dancheong-deep ] || { echo "FAIL: theme selection not persisted"; exit 1; }
grep -q 'window.active.title.bg.color: #28574A' "$("$THEME_BIN" state-dir)/themerc-override" || { echo "FAIL: managed themerc-override not written for deep theme"; exit 1; }
# 잘못된 ID → 기본 테마 복귀
"$THEME_BIN" apply no-such-theme >/dev/null 2>&1 && { echo "FAIL: unknown theme id accepted"; exit 1; }
[ "$("$THEME_BIN" current)" = hagra-dancheong-light ] || { echo "FAIL: unknown id did not revert to default"; exit 1; }
sleep 2.5
grep -q 'applied theme tokens "hagra-dancheong-light"' "$OUT/shell-theme.log" || { echo "FAIL: shell did not return to the light theme"; cat "$OUT/shell-theme.log"; exit 1; }
grim -t png "$OUT/08-panel-light-again.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/08-panel-light-again.png" panel
echo "ok: theme round trip light → deep → light (persisted, labwc reloaded, unknown id reverted)"
"$SHELL_BIN" --quit; sleep 0.5

# 1920×1080 회귀: 첫 configure 가 QML 초기 폭과 다를 때 셸이 죽지 않고 패널이 전체 폭을 채워야 한다 (layerwindow 생성 중 resize 지연)
if command -v wlr-randr >/dev/null; then
  wlr-randr --output HEADLESS-1 --custom-mode 1920x1080@60 >/dev/null 2>&1 && sleep 0.5
  "$SHELL_BIN" > "$OUT/shell-fhd.log" 2>&1 &
  SHELL_PID=$!
  for i in $(seq 1 40); do
    grep -q 'layer surface "hagra-panel" configured' "$OUT/shell-fhd.log" 2>/dev/null && break
    kill -0 $SHELL_PID 2>/dev/null || { echo "FAIL: hagra-shell exited at 1920x1080"; cat "$OUT/shell-fhd.log"; exit 1; }
    sleep 0.5
  done
  sleep 1.5
  kill -0 $SHELL_PID 2>/dev/null || { echo "FAIL: hagra-shell crashed after configure at 1920x1080"; cat "$OUT/shell-fhd.log"; exit 1; }
  grim -t png "$OUT/05-panel-fhd.png"
  python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/05-panel-fhd.png" panel
  "$SHELL_BIN" --quit; sleep 0.5
fi

echo "PASS: 하그라 셸 headless integration test (screenshots in $OUT)"
