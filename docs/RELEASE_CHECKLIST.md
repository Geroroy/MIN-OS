# 릴리스 점검표 (하그라 0.1.0 RC)

결과는 **PASS / FAIL / BLOCKED / NOT TESTED** 로만 적는다. 실행하지 않은 검사를 PASS 로 적지 않는다. 자동 검사는 `tests/qa/run-all.sh` 가 `out/qa/report.md` 에 쓴다.

## 1. 자동 (호스트, 헤드리스)

- [ ] `make tokens-check` — 토큰 드리프트 · 테마 팩 최신 · 대비 203 검사
- [ ] `ctest` — hagraui.qml, theme.manager, shell.appindex, shell.launcherstate, settings.backends
- [ ] `tests/shell/run.sh` — 패널·실행 메뉴·전원 메뉴·exclusive zone·테마 왕복(연한→깊은→밤→깊은→연한)·저장 복원·잘못된 ID·영어 UI·1920×1080·알림 서버·2출력 패널
- [ ] `tests/design/capture-settings.sh` — 11 페이지 QML 경고 0 (한국어·영어·밤 단청)
- [ ] `tests/design/capture-shell.sh` — 달력·알림·알림 센터·위쪽 패널
- [ ] `tests/shell/measure_idle.sh` — 셸 유휴 CPU < 1 %, RSS 기록
- [ ] `dpkg-buildpackage -b` — hagra-desktop .deb

## 2. 이미지 (QEMU)

- [ ] `sudo make image` (debian-trixie 또는 ubuntu-noble) → ISO 크기 기록
- [ ] `sudo make test-image` — 부팅 → 로그인 → 세션 → 실행 메뉴 → 터미널 → 테마 적용·저장 → 재부팅 → (라이브: 기본 복귀) → 종료
- [ ] `sudo make image-arm64` + `test-image-arm64` — 동일 시나리오, 재부팅 후 테마 복원
- [ ] 첫 부팅 시간(셸까지) 기록, 메모리 사용량 기록 (`metrics.json`)

## 3. 실기기 (수동)

- [ ] UEFI 와 BIOS 부팅 (x86-64 PC)
- [ ] 로그인 → 바탕 화면 → 작업 표시줄 → 실행 메뉴 → 앱 실행 → 창 전환·스냅·최대화·전체 화면 → 작업 공간 1~4
- [ ] 테마 3종 전환 + 포인트 색 + 밝게/어둡게, 재부팅 후 유지 (설치 또는 qcow2)
- [ ] 배경 변경(격자·직접 경로), 재부팅 후 유지
- [ ] 디스플레이: 해상도·배율(1.5/2)·회전 적용, 재로그인 후 복원; 외부 모니터 연결 시 두 번째 패널
- [ ] 소리(PipeWire 설치 시): 표시기·팝업·설정 볼륨/음소거
- [ ] 네트워크(NM 설치 시): Wi-Fi 검색·연결; 미설치 시 인터페이스 상태 표시
- [ ] 전원: 절전·다시 시작·종료·로그아웃; 배터리 표시기(노트북)
- [ ] 알림: `notify-send` 팝업·센터·방해 금지
- [ ] 키보드·마우스: 반복 속도, 탭 클릭, 자연 스크롤, 배치 kr/us 전환 키
- [ ] 언어: en_US 로 로그인 → 영어 UI; ko_KR → 한국어 UI

## 4. 한글 입력·글꼴

- [ ] fcitx5 자동 시작, Shift+Space 로 한/영 전환, 터미널·설정 검색창·foot 에서 한글 조합
- [ ] 긴 한글 파일명·메뉴 라벨 말줄임, 글자 크기 160% 에서 잘림 없음

## 5. 안정성

- [ ] 셸 강제 종료(`kill -9 hagra-shell`) → 자동 재시작, `shell-crashes.log` 기록
- [ ] 로그아웃·재부팅·종료 10회 반복 무오류
- [ ] 1시간 유휴 후 CPU·메모리 증가 없음

## 6. 문서·산출물

- [ ] README·USER_GUIDE·INSTALL·KNOWN_ISSUES·DESIGN_TOKENS·ICONS·RELEASE_READINESS 갱신
- [ ] 스크린샷 `docs/screenshots/p1..p3/` 최신
- [ ] CHANGELOG(debian/changelog) 버전·날짜
