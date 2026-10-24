#!/bin/bash
# MIN 세션 파일 설치 (소스: /tmp/minos-src/session)
set -euo pipefail
SRC=/tmp/minos-src/session

install -Dm755 "$SRC/bin/minos-session" /usr/bin/minos-session
install -d /etc/minos/labwc
install -m644 "$SRC/labwc/rc.xml" "$SRC/labwc/menu.xml" "$SRC/labwc/environment" "$SRC/labwc/themerc-override" /etc/minos/labwc/
install -m755 "$SRC/labwc/autostart" /etc/minos/labwc/autostart
install -Dm644 "$SRC/labwc/themerc-override" /usr/share/themes/MIN/labwc/themerc
install -Dm644 "$SRC/greetd/config.toml" /etc/greetd/config.toml
install -Dm644 "$SRC/foot/foot.ini" /etc/xdg/foot/foot.ini
install -Dm644 "$SRC/minos.desktop" /usr/share/wayland-sessions/minos.desktop
install -Dm644 "$SRC/wallpaper/min-graphite.png" /usr/share/minos/wallpaper/min-graphite.png

# greetd: 로그인 화면 전환용 VT와 seat 접근
if getent passwd _greetd >/dev/null; then usermod -aG video,input,render _greetd 2>/dev/null || true; fi

# MIN OS 식별 정보 (Debian os-release는 그대로 두고 별도 파일로 제공)
cat > /etc/minos-release <<R
MINOS_NAME="HAGRA"
MINOS_DISPLAY_NAME="하그라"
MINOS_VERSION="${MINOS_VERSION:-0.1.0-dev}"
MINOS_BASE="${MINOS_SUITE:-unknown}"
MINOS_BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
R
cat > /etc/issue <<'I'
HAGRA (하그라) \n (\l)

I
