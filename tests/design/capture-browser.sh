#!/bin/bash
# 하그라 브라우저 캡처 + 동작 검사: 헤드리스 labwc 에서 hagra-browser 를 띄워
#   1) 시작 페이지(새 탭)  2) 로컬 시험 페이지(file://, 자바스크립트가 제목을 바꿈)  3) 두 번째 실행 → 기존 창에 새 탭(단일 인스턴스)
#   4) 내려받기: 로컬 HTTP 서버의 파일을 열면 ~/Downloads 에 저장되고, 내려받기만 하려고 연 탭은 닫힌다
# 을 확인하고 out/design/browser/browser-*.png 를 남긴다. QML 경고가 있거나 페이지가 안 열리면 종료 코드 1.
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/browser$(hd_theme_suffix)}; mkdir -p "$OUT"
BROWSER=$BUILD/browser/hagra-browser
[ -x "$BROWSER" ] || { echo "hagra-browser not built (qt6-webengine-dev 필요)"; exit 2; }
trap hd_stop EXIT
hd_start 1280x720 1
export HOME=$XDG_RUNTIME_DIR/home; mkdir -p "$HOME"; unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME
export QT_LOGGING_RULES="hagra.*=false;hagra.browser=true"
LOG=$OUT/browser.log; : > "$LOG"
swaybg -i "$(hd_wallpaper)" -m fill -c "$(hd_wallpaper_fill)" >/dev/null 2>&1 &
"$SHELL_BIN" >/dev/null 2>&1 &
sleep 2
wait_log() { # 패턴, 초
  for i in $(seq 1 $(( $2 * 5 ))); do grep -q "$1" "$LOG" && return 0; kill -0 $BP 2>/dev/null || return 1; sleep 0.2; done; return 1
}
fail() { echo "FAIL: $*"; tail -40 "$LOG"; exit 1; }

"$BROWSER" >> "$LOG" 2>&1 &
BP=$!
wait_log "window ready" 30 || fail "browser window did not start"
sleep "${SETTLE:-2}"
grim -t png "$OUT/browser-start.png"; echo "captured start page"

PAGE=$REPO/tests/browser/page.html
"$BROWSER" "$PAGE" >> "$LOG" 2>&1   # 단일 인스턴스: 기존 창에 새 탭으로 보내고 바로 끝난다
wait_log "loaded file://.*page.html" 60 || fail "test page did not load"
sleep "${SETTLE:-3}"
grep -q "시험 페이지 ✓" "$LOG" || fail "javascript did not run (title unchanged)"
grim -t png "$OUT/browser-page.png"; echo "captured test page"
kill -0 $BP || fail "browser exited"

SRV=$XDG_RUNTIME_DIR/srv; mkdir -p "$SRV"; head -c 2000000 /dev/urandom > "$SRV/hagra-test.bin"
PORT=$(python3 -I -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
(cd "$SRV" && exec python3 -I -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1) &
HP=$!
sleep 1
"$BROWSER" "http://127.0.0.1:$PORT/hagra-test.bin" >> "$LOG" 2>&1
wait_log "download finished state 2 2000000 bytes" 60 || { kill $HP; fail "download did not complete"; }
kill $HP 2>/dev/null || true
cmp -s "$SRV/hagra-test.bin" "$HOME/Downloads/hagra-test.bin" || fail "downloaded file differs or missing in ~/Downloads"
sleep 1
grim -t png "$OUT/browser-download.png"; echo "captured download bar"
kill -0 $BP || fail "browser exited"
[ -d "$HOME/.local/share/hagra/browser" ] || fail "profile storage not created in ~/.local/share/hagra/browser"
kill $BP 2>/dev/null || true; wait $BP 2>/dev/null || true

# Qt WebEngine 6.4 자체가 모듈 등록 때 내는 경고("QWebEngine… is neither a QObject …")는 우리 코드와 무관하므로 뺀다
qml_warnings() { grep -E 'qml|QML|TypeError|ReferenceError|is not a type|Unable to assign|Cannot' "$LOG" | grep -v 'hagra.browser' | grep -v 'is neither a QObject, nor default- and copy-constructible' || true; }
if [ -n "$(qml_warnings)" ]; then
  echo "QML WARNINGS:"; qml_warnings | sort | uniq -c | head -40
  exit 1
fi
echo "PASS: browser start page, local page (JS), single instance, download — screenshots in $OUT"
