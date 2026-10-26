# 출처와 편입 기록 (v2)

- 2026-10-26 전달받은 "하그라 선택형 테마 전달 자료 v2 — 깊은 단청" 원본이다 (SHA256SUMS 검증 통과).
- 통합 방식: **추가 선택형 테마** `hagra-dancheong-deep`(표시 이름 "깊은 단청"). 기존 연한 단청(`hagra-dancheong-light`)과 기본 선택값은 보존한다.
- `reference/hagra-dancheong-concept.png` 는 AI 생성 콘셉트(실행 화면 아님). `reference/dancheong-cranes.jpg`, `dancheong-eaves.jpg` 는 사용자 제공 색상·문양 참고 사진이며 제품 배경으로 배포하지 않는다.
- 실행용 사본: 테마 팩 `design/themes/hagra-dancheong-deep/` (assets/, wallpaper.png, tokens.json 은 저장소 토큰 스키마로 변환). 원본은 이 디렉터리에 그대로 보존한다.
- 패키지의 `qml/Theme.qml` 은 정적 스냅샷이며 저장소의 `MinUI.Theme` 를 덮어쓰지 않는다. 값은 테마 팩 tokens.json 을 거쳐 런타임에 적용된다.
