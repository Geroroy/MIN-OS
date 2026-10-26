#!/bin/bash
# 하그라 QA 실행기: 자동화 가능한 검사를 모두 돌리고 PASS/FAIL/BLOCKED/NOT TESTED 표를 만든다. → out/qa/report.md, out/qa/*.log
#   사용: tests/qa/run-all.sh [--with-image]   (--with-image: sudo make image + test-image 까지; 시간이 오래 걸린다)
set -uo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd); cd "$REPO"
OUT=$REPO/out/qa; mkdir -p "$OUT"
REPORT=$OUT/report.md
WITH_IMAGE=0; [ "${1:-}" = --with-image ] && WITH_IMAGE=1
declare -a ROWS
run() { # id, title, command...
  local id=$1 title=$2; shift 2
  local log=$OUT/$id.log; local t0=$(date +%s)
  if "$@" > "$log" 2>&1; then st=PASS; else st=FAIL; fi
  ROWS+=("| $id | $title | **$st** | $(( $(date +%s) - t0 )) s | \`out/qa/$id.log\` |")
  echo "[$st] $id $title"
}
skip() { ROWS+=("| $1 | $2 | $3 | — | $4 |"); echo "[$3] $1 $2"; }
need() { command -v "$1" >/dev/null 2>&1; }

run build      "빌드 (cmake + ninja, 테마 팩, 번역)"           make -s shell
run tokens     "토큰 드리프트·테마 팩·대비 검사"                  make -s tokens-check
run unit       "단위 테스트 (ctest: hagraui.qml, theme.manager, shell.appindex, shell.launcherstate, settings.backends)" bash -c 'cd build && ctest --output-on-failure'
if need labwc && need grim && need foot; then
  run shell    "헤드리스 셸 통합 (패널·실행 메뉴·전원·exclusive zone·테마 왕복 3종·영어 UI·FHD·알림 서버·2출력)" tests/shell/run.sh build
  run settings "설정 앱 11 페이지 렌더링 (QML 경고 0)"             tests/design/capture-settings.sh
  run settings_en "설정 앱 영어 UI"                              env HAGRA_CAPTURE_LANG=en_US.UTF-8 HAGRA_CAPTURE_LANGUAGE=en PAGES="appearance input" tests/design/capture-settings.sh out/design/settings-en
  run popups   "셸 팝업 (달력·알림·알림 센터·위쪽 패널)"           tests/design/capture-shell.sh
  run idle     "유휴 CPU·메모리 측정 (30 s)"                      tests/shell/measure_idle.sh build 30
  run gallery  "HagraUI 갤러리 캡처 (3배율)"                      tests/design/capture-gallery.sh
else
  skip shell "헤드리스 셸 통합" BLOCKED "labwc/grim/foot 없음"
fi
if need dpkg-buildpackage && need dh; then
  run deb      "Debian 패키지 빌드 (dpkg-buildpackage -b)"       bash -c 'rm -rf out/deb && mkdir -p out/deb && cp -a . out/deb/src 2>/dev/null; cd out/deb/src && rm -rf build out && dpkg-buildpackage -us -uc -b 2>&1 | tail -5 && ls ../*.deb'
else
  skip deb "Debian 패키지 빌드" BLOCKED "debhelper(dh) 미설치"
fi
if [ $WITH_IMAGE = 1 ]; then
  run image    "x86-64 ISO 빌드"                                 sudo make image
  run boot     "QEMU 부팅 테스트 (부팅→세션→실행 메뉴→터미널→테마→재부팅→종료)" sudo make test-image
else
  skip image "x86-64 ISO 빌드" "NOT TESTED" "--with-image 로 실행 (mmdebstrap·미러·sudo 필요)"
  skip boot  "QEMU 부팅 테스트" "NOT TESTED" "--with-image 로 실행"
fi
skip device "실기기 (PC UEFI/BIOS · Galaxy S25 Ultra Termux)" "NOT TESTED" "수동 체크리스트: docs/RELEASE_CHECKLIST.md"
skip ime    "한글 입력(fcitx5) 실제 조합" "NOT TESTED" "이미지 재빌드 후 수동 (호스트에 fcitx5 없음)"
skip audio  "소리 백엔드 (wpctl/pactl)" "NOT TESTED" "호스트에 PipeWire 없음 — 파서는 단위 테스트로 검증"
skip net    "NetworkManager Wi-Fi 연결" "NOT TESTED" "호스트에 nmcli 없음 — 파서는 단위 테스트로 검증"

{
  echo "# 하그라 QA 보고 — $(date -Is)"
  echo
  echo "호스트: $(. /etc/os-release; echo "$PRETTY_NAME") · $(uname -m) · labwc $(labwc --version 2>/dev/null | awk '{print $2}') · Qt $(qmake6 -query QT_VERSION 2>/dev/null)"
  echo
  echo "| ID | 검사 | 결과 | 시간 | 로그/비고 |"; echo "|---|---|---|---|---|"
  printf '%s\n' "${ROWS[@]}"
  echo
  [ -f out/metrics/idle.json ] && { echo "유휴 측정: \`out/metrics/idle.json\`"; echo; cat out/metrics/idle.json; echo; }
} > "$REPORT"
echo; echo "report: $REPORT"; grep -c '| \*\*FAIL\*\* |' "$REPORT" | grep -q '^0$'
