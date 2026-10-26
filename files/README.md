# 하그라 파일 (파일 관리자)

**상태: 미착수 — M3 에서 구현** (DEVELOPMENT_PLAN.md 참고)

이 디렉터리는 하그라 파일 컴포넌트의 자리입니다. 아키텍처와 설계 요구사항은 `docs/ARCHITECTURE.md` §2.5,
디자인 규칙은 `docs/DESIGN_LANGUAGE.md` 를 따릅니다. 구현 시 최상위 `CMakeLists.txt` 에 `add_subdirectory(files)` 로 추가하고,
`libs/hagraui` (HagraUI) 컨트롤만 사용합니다.
