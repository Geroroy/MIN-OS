#!/bin/bash
# 헤드리스 labwc 세션 헬퍼 (디자인 캡처용). source 해서 사용한다.
#   hd_start [WIDTHxHEIGHT] [SCALE]   컴포지터 시작, WAYLAND_DISPLAY 설정
#   hd_mode  WIDTHxHEIGHT SCALE       출력 모드/배율 변경 (wlr-randr)
#   hd_stop                           정리
REPO=${REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
BUILD=${BUILD:-$REPO/build}
PREVIEW=$BUILD/tools/preview/hagra-preview
SHELL_BIN=$BUILD/shell/hagra-shell

hd_start() {
  for t in labwc grim wlr-randr swaybg python3; do command -v $t >/dev/null || { echo "missing tool: $t"; exit 2; }; done
  [ -x "$PREVIEW" ] || { echo "hagra-preview not built: $PREVIEW (make shell)"; exit 2; }
  export XDG_RUNTIME_DIR=$(mktemp -d /tmp/hagra-design-XXXXXX); chmod 700 "$XDG_RUNTIME_DIR"
  export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
  export QT_QUICK_BACKEND=software QT_LOGGING_RULES="hagra.*=false"
  export HAGRA_QML_IMPORT_PATH=$REPO/libs/hagraui/qml XDG_CURRENT_DESKTOP=HAGRA HAGRA_SHELL=none
  export HAGRA_ICON_PATH=$REPO/design/assets/icons
  export HAGRA_THEME_PATH=$BUILD/themes            # 테마 팩 (build_themes.py 조립본); HAGRA_THEME=<id> 로 캡처 테마 선택
  export HAGRA_THEME_NO_SESSION_RELOAD=1
  unset WAYLAND_DISPLAY DISPLAY
  # 캡처용 설정: 세션 설정을 복사하되 창 배치를 automatic 으로 바꿔 활성/비활성 창이 겹치지 않게 한다
  mkdir -p "$XDG_RUNTIME_DIR/labwc"; cp "$REPO"/session/labwc/* "$XDG_RUNTIME_DIR/labwc/"
  sed -i 's|<policy>center</policy>|<policy>automatic</policy>|' "$XDG_RUNTIME_DIR/labwc/rc.xml"
  labwc -C "$XDG_RUNTIME_DIR/labwc" > "$XDG_RUNTIME_DIR/labwc.log" 2>&1 &
  HD_LABWC=$!
  for i in $(seq 1 50); do s=$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null | grep -v '\.lock$' | head -1 || true); [ -n "$s" ] && break; sleep 0.1; done
  [ -n "${s:-}" ] || { echo "labwc failed"; cat "$XDG_RUNTIME_DIR/labwc.log"; exit 1; }
  export WAYLAND_DISPLAY=$(basename "$s")
  [ -n "${1:-}" ] && hd_mode "$1" "${2:-1}"
  true
}
hd_theme_suffix() { [ -n "${HAGRA_THEME:-}" ] && [ "$HAGRA_THEME" != hagra-dancheong-light ] && echo "-${HAGRA_THEME#hagra-dancheong-}" || true; }
hd_wallpaper() { "$BUILD/tools/theme/hagra-theme" wallpaper 2>/dev/null || echo "$REPO/session/wallpaper/hagra-dancheong.png"; }
hd_wallpaper_fill() { "$BUILD/tools/theme/hagra-theme" wallpaper-fill 2>/dev/null || echo '#E3ECE6'; }
hd_mode() { wlr-randr --output HEADLESS-1 --custom-mode "${1}@60" --scale "${2:-1}" >/dev/null 2>&1 || wlr-randr --output HEADLESS-1 --scale "${2:-1}" >/dev/null 2>&1; sleep 0.5; }
hd_kill_clients() { pkill -P $$ -f "hagra-preview|hagra-shell|swaybg|foot" 2>/dev/null; sleep 0.3; }
hd_stop() { hd_kill_clients; [ -n "${HD_LABWC:-}" ] && kill "$HD_LABWC" 2>/dev/null; rm -rf "$XDG_RUNTIME_DIR"; }
