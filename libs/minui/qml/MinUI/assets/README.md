# MinUI 모듈 자산

`Theme.asset(name)` / `MIcon { name }` 가 읽는 SVG. 모듈 디렉터리와 함께 설치된다 (`install(DIRECTORY qml/MinUI …)`).

| 출처 | 파일 | 용도 |
|---|---|---|
| `design/hagra-dancheong-v1/assets/` 사본 (원본 보존) | lotus, lotus-band, corner-rosette, cloud-tile, lattice-tile, bojagi-tile, folder-writing, folder-translation, folder-reference, folder-project, document, settings | 장식·폴더·문서 아이콘 (완성 색) |
| 저장소에서 작성 (단색 24×24, 획 #203F42; `<name>-light.svg` 는 분백 #F2EADB 변형 — 어두운 패널·사이드바용, `MIcon { light: true }`) | home, search, download, image, trash, file, folder, drive, usb, back, forward, up, view-grid, view-list, terminal, window, power, close, apps, error, check | 조작 기호. 장식과 조작 기호를 구분한다 (DESIGN_SPEC) |

Qt 6.4 는 SVG 재착색이 없으므로 아이콘은 완성 색으로 제공된다. 비활성 상태는 MIcon 의 opacity 로 낮춘다.
