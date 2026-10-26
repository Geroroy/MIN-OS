#!/bin/bash
# 하그라 컴포넌트를 대상 안에서 빌드·설치하고 빌드 의존성을 제거한다.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
BUILD_PKGS=$(grep -vE '^\s*(#|$)' /tmp/hagra-src/image/config/packages.build | tr '\n' ' ')

echo "== installing build dependencies"
apt-get update >/tmp/hagra-apt-update.log 2>&1 || { tail -20 /tmp/hagra-apt-update.log; exit 1; }
apt-get install -y --no-install-recommends $BUILD_PKGS >/tmp/hagra-build-deps.log 2>&1 || { tail -30 /tmp/hagra-build-deps.log; exit 1; }

echo "== building HAGRA components"
cmake -S /tmp/hagra-src -B /tmp/hagra-build -G Ninja -DCMAKE_BUILD_TYPE=Release -DHAGRA_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr >/tmp/hagra-cmake.log 2>&1 || { tail -40 /tmp/hagra-cmake.log; exit 1; }
cmake --build /tmp/hagra-build -j"$(nproc)" >/tmp/hagra-build.log 2>&1 || { tail -60 /tmp/hagra-build.log; exit 1; }
cmake --install /tmp/hagra-build >/tmp/hagra-install.log 2>&1
grep -E "^-- Installing" /tmp/hagra-install.log | sed 's/^-- Installing: /   /'

echo "== removing build dependencies"
apt-mark auto $BUILD_PKGS >/dev/null
apt-get autoremove -y --purge >/tmp/hagra-autoremove.log 2>&1 || { tail -20 /tmp/hagra-autoremove.log; exit 1; }
rm -rf /tmp/hagra-build
# 런타임 자가 점검
test -x /usr/bin/hagra-shell
test -x /usr/bin/hagra-settings
test -x /usr/bin/hagra-theme
test -f /usr/share/hagra/themes/hagra-dancheong-night/theme.json
test -f /usr/share/hagra/translations/hagra-shell_en.qm
test -f /usr/share/applications/org.hagra.settings.desktop
test -f "$(find /usr/lib -path '*/qt6/qml/HagraUI/qmldir' | head -1)"
