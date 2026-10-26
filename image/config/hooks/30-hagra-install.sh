#!/bin/bash
# 하그라 세션 파일 설치 (소스: /tmp/hagra-src/session)
set -euo pipefail
SRC=/tmp/hagra-src/session

install -Dm755 "$SRC/bin/hagra-session" /usr/bin/hagra-session
install -d /etc/hagra/labwc
install -m644 "$SRC/labwc/rc.xml" "$SRC/labwc/menu.xml" "$SRC/labwc/environment" "$SRC/labwc/themerc-override" /etc/hagra/labwc/
install -m755 "$SRC/labwc/autostart" /etc/hagra/labwc/autostart
install -Dm644 "$SRC/labwc/themerc-override" /usr/share/themes/HAGRA/labwc/themerc
install -Dm644 "$SRC/greetd/config.toml" /etc/greetd/config.toml
install -Dm644 "$SRC/foot/foot.ini" /etc/xdg/foot/foot.ini
install -Dm644 "$SRC/hagra.desktop" /usr/share/wayland-sessions/hagra.desktop
install -Dm644 "$SRC/wallpaper/hagra-dancheong.png" /usr/share/hagra/wallpaper/hagra-dancheong.png
install -Dm644 "$SRC/wallpaper/graphite.png" /usr/share/hagra/wallpaper/graphite.png

# greetd: 로그인 화면 전환용 VT와 seat 접근
if getent passwd _greetd >/dev/null; then usermod -aG video,input,render _greetd 2>/dev/null || true; fi

# 하그라 식별 정보 (Debian os-release는 그대로 두고 별도 파일로 제공)
cat > /etc/hagra-release <<R
HAGRA_NAME="HAGRA"
HAGRA_DISPLAY_NAME="하그라"
HAGRA_VERSION="${HAGRA_VERSION:-0.1.0-dev}"
HAGRA_BASE="${HAGRA_SUITE:-unknown}"
HAGRA_BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
R
cat > /etc/issue <<'I'
HAGRA (하그라) \n (\l)

I
