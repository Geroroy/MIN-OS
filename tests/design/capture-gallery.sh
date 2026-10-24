#!/bin/bash
# MinUI 갤러리 캡처: 섹션 × 배율(100/150/200%) → out/design/gallery/<section>-<pct>.png
# 배율은 QT_SCALE_FACTOR(앱 논리 배율)로 적용한다. 컴포지터 출력 배율은 capture-scene.sh 참고.
set -euo pipefail
. "$(dirname "$0")/headless.sh"
OUT=${1:-$REPO/out/design/gallery}; mkdir -p "$OUT"
SECTIONS=${SECTIONS:-"buttons inputs selection lists feedback text frame"}
SCALES=${SCALES:-"1 1.5 2"}
trap hd_stop EXIT
hd_start 1280x720 1
for sc in $SCALES; do
  pct=$(python3 -c "print(int(round($sc*100)))")
  for sec in $SECTIONS; do
    "$PREVIEW" "$REPO/libs/minui/gallery/Gallery.qml" --state "$sec" --scale "$sc" >/dev/null 2>&1 &
    sleep "${SETTLE:-3}"
    grim -t png "$OUT/$sec-$pct.png"
    hd_kill_clients
    echo "captured $sec @ $pct%"
  done
done
echo "PASS: gallery captures in $OUT"
