#!/bin/bash
# MIN Shell 헤드리스 통합 테스트
#  - labwc를 헤드리스 백엔드(pixman)로 띄우고 minos-shell을 실행한다.
#  - grim으로 스크린샷을 찍어 패널·실행 메뉴·전원 메뉴가 제 위치에 그려졌는지 픽셀 단위로 검사한다.
#  - layer-shell exclusive zone 이 적용되는지 foot(터미널) 창을 최대화해 확인한다.
# 사용: tests/shell/run.sh [build-dir]   (기본 build/)
set -euo pipefail

REPO=$(cd "$(dirname "$0")/../.." && pwd)
BUILD=${1:-$REPO/build}
SHELL_BIN=$BUILD/shell/minos-shell
OUT=${MINOS_TEST_OUT:-$BUILD/test-out}
mkdir -p "$OUT"

[ -x "$SHELL_BIN" ] || { echo "minos-shell not built: $SHELL_BIN (run: make shell)"; exit 2; }
for t in labwc grim foot python3; do command -v $t >/dev/null || { echo "missing tool: $t"; exit 2; }; done

export XDG_RUNTIME_DIR=$(mktemp -d /tmp/minos-test-XXXXXX)
chmod 700 "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless
export WLR_RENDERER=pixman
export WLR_LIBINPUT_NO_DEVICES=1
export QT_QUICK_BACKEND=software
export QT_LOGGING_RULES="minos.*=true"
export MINOS_QML_IMPORT_PATH=$REPO/libs/minui/qml
export XDG_CURRENT_DESKTOP=MIN
export MINOS_TERMINAL=foot
export MINOS_SHELL=none   # autostart 의 셸 실행은 건너뛰고 테스트가 직접 실행한다
unset WAYLAND_DISPLAY DISPLAY

cleanup() {
  pkill -P $$ 2>/dev/null || true
  [ -n "${LABWC_PID:-}" ] && kill "$LABWC_PID" 2>/dev/null || true
  rm -rf "$XDG_RUNTIME_DIR"
}
trap cleanup EXIT

# labwc: -C 설정 디렉터리(MIN 테마), -s 시작 명령은 쓰지 않고 소켓을 직접 기다린다.
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
sleep 2
kill -0 $SHELL_PID 2>/dev/null || { echo "FAIL: minos-shell exited"; cat "$OUT/shell.log"; exit 1; }
grep -q "zwlr_layer_shell_v1 bound" "$OUT/shell.log" || { echo "FAIL: layer shell not bound"; cat "$OUT/shell.log"; exit 1; }
grep -q 'layer surface "minos-panel" configured' "$OUT/shell.log" || { echo "FAIL: panel not configured"; cat "$OUT/shell.log"; exit 1; }

grim -t png "$OUT/01-panel.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/01-panel.png" panel

# 실행 메뉴 토글 (IPC 경로 검증)
"$SHELL_BIN" --toggle-launcher
sleep 1
grep -q 'layer surface "minos-launcher" configured' "$OUT/shell.log" || { echo "FAIL: launcher not configured"; cat "$OUT/shell.log"; exit 1; }
grim -t png "$OUT/02-launcher.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/02-launcher.png" launcher
"$SHELL_BIN" --toggle-launcher
sleep 0.5

# 전원 메뉴
"$SHELL_BIN" --power
sleep 1
grep -q 'layer surface "minos-power" configured' "$OUT/shell.log" || { echo "FAIL: power menu not configured"; cat "$OUT/shell.log"; exit 1; }
grim -t png "$OUT/03-power.png"
python3 -I "$REPO/tests/shell/check_screenshot.py" "$OUT/03-power.png" power
"$SHELL_BIN" --power
sleep 0.5

# exclusive zone: foot 을 최대화하면 패널 영역을 침범하지 않아야 한다 (foreign-toplevel 창 목록도 함께 검사)
foot --app-id minos-test-foot > "$OUT/foot.log" 2>&1 &
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

echo "PASS: MIN Shell headless integration test (screenshots in $OUT)"
