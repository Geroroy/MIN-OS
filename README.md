# MIN OS

**Minimal. Independent. Native.**

MIN OS는 Debian Stable 위에 자체 사용자 인터페이스, 시스템 애플리케이션, 부팅 경험,
설정 시스템을 갖춘 경량 데스크톱 운영체제입니다. 테마나 데스크톱 커스터마이징이 아니라,
실제 PC에 설치해 일상적으로 사용할 수 있는 독자적인 데스크톱 운영체제를 목표로 합니다.

| 항목 | 선택 |
|---|---|
| Base | Debian Stable (현재 Debian 13 "trixie") |
| Kernel | Linux (Debian 커널 패키지) |
| Display | Wayland |
| Compositor | Labwc (wlroots 기반, 초기 단계) |
| Desktop UI | Qt 6 / QML |
| System code | Rust (데몬·설치기 백엔드), C++ (Qt UI) |
| Packages | APT (.deb) |
| Image build | mmdebstrap + 자체 스크립트 (`image/`) |
| Testing | QEMU / KVM, 헤드리스 labwc |

## 저장소 구조

```
MIN-OS/
├── README.md                 이 문서
├── DEVELOPMENT_PLAN.md       마일스톤 및 일정
├── Makefile                  최상위 진입점 (deps / shell / image / run / test)
├── docs/
│   ├── ARCHITECTURE.md       시스템 아키텍처
│   ├── DESIGN_LANGUAGE.md    MIN 디자인 언어 (색상·치수·타이포·상호작용)
│   ├── MILESTONE_1.md        첫 번째 마일스톤 구현 계획 및 검증 방법
│   └── BUILD_ENVIRONMENT.md  빌드 환경 요구사항과 제약
├── scripts/
│   └── install-deps.sh       호스트 개발 의존성 설치 (Debian/Ubuntu)
├── image/                    부팅 이미지 빌드 파이프라인
│   ├── build.sh              rootfs → MIN 컴포넌트 빌드 → squashfs → hybrid ISO
│   ├── config/
│   │   ├── suites/           대상 배포판 프로필 (debian-trixie, ubuntu-noble)
│   │   ├── packages.*        패키지 목록 (base / desktop / dev)
│   │   └── hooks/            chroot 내부에서 실행되는 커스터마이즈 스크립트
│   ├── grub/                 ISO용 GRUB 설정 (BIOS + UEFI)
│   └── qemu/run.sh           QEMU 실행 스크립트
├── session/                  MIN 세션: greetd 설정, minos-session, labwc rc.xml, foot 설정
├── shell/                    MIN Shell (작업 표시줄, 실행 메뉴, 트레이, 시계, 알림, 창 전환)
├── libs/
│   ├── minlayershell/        Qt 6용 wlr-layer-shell 클라이언트 통합 (패널을 화면 가장자리에 고정)
│   └── minui/                MinUI: QML 디자인 시스템 모듈 (색상 토큰, 컨트롤)
├── files/                    MIN Files (파일 관리자)          — M3
├── settings/                 MIN Settings (설정)              — M4
├── terminal/                 MIN Terminal (터미널)            — M5
├── installer/                MIN Installer (설치기)           — M6
└── tests/
    ├── shell/                헤드리스 labwc에서 MIN Shell 실행·스크린샷 검증
    └── image/                QEMU 부팅·종료·재부팅 자동 검증
```

## 현재 상태 (M1)

![MIN OS M1 desktop](docs/screenshots/m1-launcher.png)

QEMU(UEFI)에서 부팅한 개발 이미지: labwc 세션 위의 MIN Shell 패널과 실행 메뉴. `DEVELOPMENT_PLAN.md` 참고.

## 빠른 시작

```sh
# 1. 호스트 의존성 (Debian 13 / Ubuntu 24.04)
sudo scripts/install-deps.sh

# 2. MIN Shell 호스트 빌드 + 헤드리스 테스트
make shell
make test-shell

# 3. 부팅 이미지 빌드 (기본: Debian trixie. Debian 미러가 막힌 환경에서는 SUITE=ubuntu-noble)
sudo make image              # 결과: out/minos-dev-<suite>-<arch>.iso
sudo make image SUITE=ubuntu-noble

# 4. QEMU에서 부팅 (KVM이 있으면 자동 사용)
make run                     # 그래픽 창
make run-serial              # 시리얼 콘솔만 (헤드리스 서버)

# 5. 자동 부팅 테스트 (부팅 → 로그인 → 세션 확인 → 종료 → 재부팅)
sudo make test-image
```

자세한 내용은 `docs/MILESTONE_1.md`와 `docs/BUILD_ENVIRONMENT.md`를 참고하십시오.

## 개발 원칙

1. 실제로 실행되는 코드를 작성한다. 작동 여부는 추측이 아니라 테스트 결과로 확인한다.
2. 불필요한 의존성을 최소화한다. 초기 단계에서는 안정적인 기존 컴포넌트를 재사용한다.
3. 기존 Linux 드라이버·APT 생태계와의 호환성을 유지한다.
4. 모든 주요 기능에 테스트를 둔다. 단계가 끝날 때마다 실행·검증 방법을 제공한다.
5. 프로젝트를 컴포넌트 단위 모듈로 구성하고, 각 컴포넌트는 독립적으로 빌드·패키징된다.
6. 빌드와 테스트는 호스트의 파티션·부트로더·개발 환경을 건드리지 않는다
   (모든 작업은 chroot, 이미지 파일, QEMU 안에서만 수행된다).

## 라이선스

MIN OS 고유 코드: GPL-3.0-or-later (예정). 포함된 Debian 패키지는 각자의 라이선스를 따릅니다.
