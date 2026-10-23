# 빌드 환경

## 1. 요구사항

| 항목 | 최소 | 비고 |
|---|---|---|
| 호스트 OS | Debian 12/13 또는 Ubuntu 24.04 (x86_64) | 다른 배포판은 mmdebstrap·squashfs-tools·xorriso·grub-*-bin이 있으면 가능 |
| 권한 | 이미지 빌드는 root(chroot/mount) | 셸 빌드·헤드리스 테스트는 일반 사용자 가능 |
| 디스크 | 10 GB 여유 | rootfs ≈ 2.5 GB, ISO ≈ 900 MB |
| 메모리 | 4 GB | QEMU 게스트 2 GB 포함 |
| 네트워크 | 대상 배포판 미러 접근 | 기본 `deb.debian.org` |
| 가속 | `/dev/kvm` 권장 | 없으면 TCG로 동작(부팅 수 분) |

의존성 설치: `sudo scripts/install-deps.sh`

## 2. 대상 프로필 (`image/config/suites/`)

| 프로필 | 용도 | 미러 | 커널 |
|---|---|---|---|
| `debian-trixie` (기본) | **MIN OS 공식 대상.** Debian 13 Stable | `http://deb.debian.org/debian` | `linux-image-amd64` |
| `ubuntu-noble` | Debian 미러가 차단된 CI/샌드박스에서 파이프라인 검증용 | `http://archive.ubuntu.com/ubuntu` | `linux-image-generic` |

두 프로필은 **같은 스크립트, 같은 패키지 목록, 같은 MIN 컴포넌트 소스**를 사용한다. 프로필 파일은 미러·스위트·
컴포넌트·커널 패키지 이름만 바꾼다. 따라서 ubuntu-noble에서 통과한 파이프라인은 debian-trixie에서도 동일한
형태로 동작하되, 패키지 버전(Qt 6.4 vs 6.8, labwc 0.7 vs 0.8)에 따른 차이는 별도 확인이 필요하다.

## 3. 이 저장소가 처음 만들어진 샌드박스 환경의 제약 (2026-10 기준 기록)

초기 개발 세션은 네트워크 정책이 제한된 클라우드 컨테이너에서 수행되었다.

| 항목 | 상태 | 영향·대응 |
|---|---|---|
| 호스트 | Ubuntu 24.04, 4 vCPU, 15 GB RAM, root | mount/chroot/unshare 가능 → mmdebstrap 사용 가능 |
| `deb.debian.org` 및 모든 Debian 미러 | **차단(403)** | Debian rootfs를 받을 수 없음 → `ubuntu-noble` 프로필로 파이프라인 검증 |
| `archive.ubuntu.com` | 허용 | 호스트 도구·Qt 6.4·labwc 0.7.1 설치 |
| `index.crates.io` / `static.crates.io` | 허용 | Rust 의존성 사용 가능 |
| `github.com` (git) | 허용 | 소스 참고 가능 |
| `/dev/kvm` | 없음 | QEMU TCG 전용. 부팅 테스트는 느리지만 가능 |
| Docker 데몬 | 없음 | 컨테이너 기반 빌드 불가 → chroot 기반 |

**결론:** 샌드박스에서 검증되는 것은 "파이프라인과 MIN 컴포넌트가 Debian 계열 rootfs 위에서 동작한다"는 사실이다.
실제 Debian trixie 이미지 빌드는 Debian 미러에 접근 가능한 개발 PC에서 `sudo make image`로 수행하고,
그 결과를 `docs/MILESTONE_1.md`의 체크리스트로 확인한다.

## 4. 호스트와 대상의 Qt 버전 차이

MIN 컴포넌트는 **대상 chroot 안에서** 빌드된다(`image/build.sh` 3단계). 호스트에서 `make shell`로 빌드한
바이너리는 헤드리스 테스트 전용이며 이미지에 복사되지 않는다. 지원 범위는 Qt 6.4(Ubuntu 24.04) 이상이며,
6.4에서 없는 API는 사용하지 않는다.

## 5. 안전 규칙

- 빌드 스크립트는 `image/work/`와 `out/` 아래에만 쓴다.
- loop 장치, 호스트 파티션, 부트로더(`grub-install` on host)는 절대 사용하지 않는다.
  ISO는 `grub-mkstandalone`/`xorriso`로 파일만 생성하고, 설치기 테스트는 QEMU 가상 디스크 파일에만 수행한다.
- chroot 안에서 실행하는 모든 명령은 `image/config/hooks/`에 스크립트로 남겨 재현 가능하게 한다.
