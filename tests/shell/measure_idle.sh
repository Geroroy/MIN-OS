#!/bin/bash
# 유휴 CPU·메모리 측정: 헤드리스 labwc + hagra-shell 을 띄우고 N초 동안 셸 프로세스의 CPU 시간·RSS 를 기록한다.
#   사용: tests/shell/measure_idle.sh [build-dir] [seconds]   → out/metrics/idle.json
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd); BUILD=${1:-$REPO/build}; SECS=${2:-30}
. "$REPO/tests/design/headless.sh"
OUT=$REPO/out/metrics; mkdir -p "$OUT"
trap hd_stop EXIT
hd_start 1280x720 1
export HOME=$XDG_RUNTIME_DIR/home; mkdir -p "$HOME"; unset XDG_CONFIG_HOME XDG_STATE_HOME
"$SHELL_BIN" > "$OUT/idle-shell.log" 2>&1 &
SP=$!
sleep 4
TICKS=$(getconf CLK_TCK)
read_cpu() { awk '{print $14+$15}' /proc/$1/stat; }
c0=$(read_cpu $SP); t0=$(date +%s.%N)
sleep "$SECS"
c1=$(read_cpu $SP); t1=$(date +%s.%N)
rss=$(awk '/VmRSS/{print $2}' /proc/$SP/status)
cpu_pct=$(python3 -c "print(round(($c1-$c0)/$TICKS/($t1-$t0)*100, 3))")
python3 - "$cpu_pct" "$rss" "$SECS" <<'PY' > "$OUT/idle.json"
import json, sys
print(json.dumps({"shell_idle_cpu_percent": float(sys.argv[1]), "shell_rss_kib": int(sys.argv[2]), "window_seconds": int(sys.argv[3]), "renderer": "software (headless pixman)"}, indent=2))
PY
cat "$OUT/idle.json"
"$SHELL_BIN" --quit; sleep 0.5
