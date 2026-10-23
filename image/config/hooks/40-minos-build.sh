#!/bin/bash
# MIN 컴포넌트를 대상 안에서 빌드·설치하고 빌드 의존성을 제거한다.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
BUILD_PKGS=$(grep -vE '^\s*(#|$)' /tmp/minos-src/image/config/packages.build | tr '\n' ' ')

echo "== installing build dependencies"
apt-get install -y --no-install-recommends $BUILD_PKGS >/tmp/minos-build-deps.log 2>&1 || { tail -30 /tmp/minos-build-deps.log; exit 1; }

echo "== building MIN components"
cmake -S /tmp/minos-src -B /tmp/minos-build -G Ninja -DCMAKE_BUILD_TYPE=Release -DMINOS_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=/usr >/tmp/minos-cmake.log 2>&1 || { tail -40 /tmp/minos-cmake.log; exit 1; }
cmake --build /tmp/minos-build -j"$(nproc)" >/tmp/minos-build.log 2>&1 || { tail -60 /tmp/minos-build.log; exit 1; }
cmake --install /tmp/minos-build >/tmp/minos-install.log 2>&1
grep -E "^-- Installing" /tmp/minos-install.log | sed 's/^-- Installing: /   /'

echo "== removing build dependencies"
apt-mark auto $BUILD_PKGS >/dev/null
apt-get autoremove -y --purge >/tmp/minos-autoremove.log 2>&1 || { tail -20 /tmp/minos-autoremove.log; exit 1; }
rm -rf /tmp/minos-build
# 런타임 자가 점검
test -x /usr/bin/minos-shell
test -f "$(find /usr/lib -path '*/qt6/qml/MinUI/qmldir' | head -1)"
