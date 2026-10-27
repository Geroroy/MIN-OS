# 보그라 (Bogra, `hagra-browser`)

하그라의 기본 웹 브라우저 **보그라**. 명령·앱 ID 는 다른 하그라 구성 요소와 같은 규칙(`hagra-browser`, `org.hagra.browser`)을 쓴다. Qt WebEngine(Chromium 엔진)을 HagraUI 부품과 테마로 감쌌다. 사용법은 `docs/USER_GUIDE.md` §5.1.

| 파일 | 역할 |
|---|---|
| `src/main.cpp` | 진입점. Chromium 플래그(소프트웨어 렌더링 → `--disable-gpu`, 모바일 프로필 → 렌더러 2개), 단일 인스턴스 소켓(`$XDG_RUNTIME_DIR/hagra-browser-<wayland>.sock`, `open:<주소>`), 번역 |
| `src/browserhelper.*` | QML 싱글턴 `HagraBrowser.Browser`: 주소 입력 해석(`fixup`), 검색 엔진, 자주 가는 곳, 저장 경로, Accept-Language, 데스크톱 알림 |
| `qml/Main.qml` | 창: 탭 막대 · 도구 막대 · 권한/찾기/내려받기 막대 · 문맥 메뉴 · 단축키 |
| `qml/BrowserTab.qml` | 탭 하나 = `WebEngineView` 하나 |
| `qml/StartPage.qml` | 새 탭 시작 페이지 (QML, 오프라인에서도 바로 뜸) |
| `org.hagra.browser.desktop`, `hagra-mimeapps.list` | 실행 메뉴 항목과 HAGRA 세션의 기본 http/https·HTML 처리기 |
| `tests/tst_browser.cpp` | 단위 테스트 (`ctest -R browser`) |

저장 위치: 프로필(쿠키·로컬 저장소) `~/.local/share/hagra/browser/`, 캐시 `~/.cache/hagra/browser/`, 설정 `~/.config/hagra/browser.conf`.

빌드에는 `qt6-webengine-dev` 가 필요하다. 없으면 CMake 가 경고를 내고 브라우저만 건너뛴다.
헤드리스 검사: `tests/design/capture-browser.sh` (시작 페이지 · file:// 시험 페이지의 자바스크립트 · 단일 인스턴스 · QML 경고 0).
