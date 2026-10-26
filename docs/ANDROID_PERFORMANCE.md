# Android/ARM64 성능 노트

측정 환경과 수치를 구분해 기록한다. **실기기(Galaxy S25 Ultra) 측정값은 아직 없다.** §4 표를 실기기에서 채운다.

## 1. 측정 방법

`tests/image/boot_test.py` 가 시리얼 콘솔로 다음을 기록한다 (`out/boot-test-arm64/metrics.json`).

| 지표 | 수집 방법 |
|---|---|
| `boot_to_shell_s` | QEMU 시작 → root 시리얼 셸 프롬프트 |
| `boot_to_shell_process_s` | QEMU 시작 → `hagra-shell` 프로세스 존재 |
| `systemd_startup_s` | 게스트 `systemd-analyze` (커널 + 사용자 공간) |
| `mem_used_mb` | 게스트 `free -m` (세션 기동 후) |
| `top_rss` | 게스트 RSS 상위 프로세스 |
| `idle_top_cpu_line` | 게스트 `top` 유휴 CPU 행 |

Termux 에서는 `start-hagra.sh` 가 남기는 `logs/serial-*.log` 의 타임스탬프와 Android 쪽 `top`/배터리 통계를 쓴다.

## 2. PC 측정값 (x86-64 호스트가 ARM64 를 TCG 로 에뮬레이션 — 참고용 하한)

호스트: 4 vCPU x86-64 샌드박스, KVM 없음, QEMU 8.2, `-cpu cortex-a76 -smp 2 -m 2048`, 1280×720, `mobile` 프로필.

| 지표 | 값 |
|---|---|
| QEMU 시작 → root 셸 | 86 ~ 98 s (두 번 측정) |
| QEMU 시작 → hagra-shell 프로세스 | 93 ~ 105 s |
| systemd-analyze | 19.5 s (kernel) + 64.0 s (userspace) = 83.5 s |
| 게스트 메모리 사용 (세션 포함) | 164 MB / 1960 MB |
| RSS 상위 | hagra-shell 51 MB, labwc 27 MB, NetworkManager 17 MB, systemd 12 MB |
| 유휴 CPU (게스트 top) | ≈ 35 % 사용 (12.5 us + 22.2 sy) — TCG 에서 타이머/인터럽트 비용 |
| 디스크 번들 | qcow2 1.06 GB(가상 6.1 GiB), vmlinuz 17 MB, initrd 17 MB |
| 재부팅 → 2차 세션 | 통과 |
| UEFI(AAVMF+GRUB) 경로 QEMU 시작 → root 셸 | 118.7 s (직접 커널 부팅 대비 +21 s: 펌웨어 초기화 + GRUB 3 s 대기) |

같은 테스트를 GitHub Actions 의 ARM64 러너(`ubuntu-24.04-arm`, ARM 호스트에서 ARM 게스트를 TCG 로 실행 — 휴대폰과 같은 구조)에서도 매 빌드마다 실행한다.

| 지표 (ARM64 러너, 2026-10-24) | 값 |
|---|---|
| QEMU 시작 → root 셸 | 96.7 s |
| systemd-analyze | 19.4 s (kernel) + 67.5 s (userspace) = 86.9 s |
| 게스트 메모리 사용 | 168 MB |
| 유휴 CPU (게스트 top) | ≈ 33 % (8.6 us + 24.1 sy) |
| 전체 시나리오 (부팅·세션·터미널·재부팅·종료) | 4 분 19 초 |

x86-64 호스트는 **다른 ISA 를 변환**하므로 가장 느린 경우다. ARM64 호스트(스마트폰)의 TCG 는 같은 ISA 를 변환하므로
명령 변환 비용이 낮고, Snapdragon 8 Elite 의 코어 성능이 이 샌드박스 vCPU 보다 높다. 실기기에서 더 빠를 것으로 예상하지만
**측정 전까지는 예상일 뿐이다.**

## 3. 이미지 쪽 최적화 (적용됨)

| 항목 | 내용 | 효과 |
|---|---|---|
| `mobile` 프로필 | apt/man-db/e2scrub/fstrim/motd 타이머, NetworkManager-wait-online, ModemManager 마스크 | 부팅 대기·주기 작업 제거 |
| 저널 휘발성 | `Storage=volatile`, 16 MB 상한 | 디스크 I/O·공간 절약 |
| `DefaultTimeoutStopSec=10s` | 종료 지연 단축 | 종료 빠름 |
| 소프트웨어 렌더링 고정 | `hagra.render=software` → labwc pixman, Qt Quick software | GPU 없는 TCG 에서 GL 경로(llvmpipe) 회피 |
| 블러·그림자·애니메이션 없음 | 하그라 디자인 언어 자체 | CPU 렌더링 비용 최소 |
| `quiet loglevel=3 systemd.show_status=0` | 콘솔 출력 억제 | 시리얼/fbcon 출력 비용 제거 |
| virtio-blk + `cache=writeback,discard=unmap` | 호스트 페이지 캐시 활용, TRIM 으로 qcow2 축소 | 디스크 I/O |
| virtio-input | USB 에뮬레이션보다 가벼움 | 입력 지연 |
| 커널 `linux-image-virtual` + modules-extra | 펌웨어 없음(≈ 600 MB 절약), 가상 장치 모듈만 | 번들 크기 |
| 패키지 `--no-install-recommends`, 문서·man·로케일 제외 | rootfs 1.1 GB | 번들 크기 |

## 4. 실기기 측정 (Galaxy S25 Ultra) — 미측정

| 설정 | 부팅 → 데스크톱 | 유휴 CPU (Android top) | 배터리/발열 | 비고 |
|---|---|---|---|---|
| 2 GB / 2 vCPU / 1280×720 (기본) | ☐ | ☐ | ☐ | |
| 2 GB / 3 vCPU / 1280×720 | ☐ | ☐ | ☐ | |
| 2 GB / 2 vCPU / 960×540 | ☐ | ☐ | ☐ | |
| 1.5 GB / 2 vCPU / 800×600 | ☐ | ☐ | ☐ | |

측정 절차: `bash start-hagra.sh --res …` 실행 시각과 VNC 에 패널이 나타난 시각, 그리고 1분 유휴 후 Termux 에서
`top -n 1 | grep qemu` 를 기록한다.

## 5. 튜닝 가이드

- **vCPU**: MTTCG 는 vCPU 마다 호스트 스레드를 쓴다. S25 Ultra 는 8코어이므로 `--smp 3` 또는 `4` 가 UI 반응을 개선할 수 있다.
  단, big 코어 점유로 발열·배터리 소모가 커지고 Android 가 스로틀링할 수 있다. 2 → 3 → 4 순으로 시험한다.
- **해상도**: 소프트웨어 렌더링 비용은 픽셀 수에 비례한다. 1280×720(0.92 MP) → 960×540(0.52 MP) 는 약 44 % 감소.
  800×600 은 하그라 패널의 정보 밀도가 유지되는 최소 해상도다.
- **메모리**: 게스트는 세션 기동 후 ≈ 170 MB 를 쓴다. `--mem 1536` 으로도 충분하며, 1024 MB 까지도 동작할 것으로 보이나
  브라우저 등 추가 앱 실행 시 부족하다. 값을 줄이면 Android 쪽 메모리 압박이 줄어 Termux 가 종료될 위험이 낮아진다.
- **CPU 모델**: `cortex-a76` 기본. `max` 는 SVE 등 추가 기능을 켜 변환 비용이 커질 수 있다.
- **디스크**: 번들은 Termux 홈(내부 저장소)에 둔다. `~/storage/shared` 는 FUSE 경유로 I/O 가 수 배 느리다.
- **백그라운드**: 화면이 꺼지면 Android 가 CPU 를 제한한다. wakelock 과 배터리 최적화 제외가 필요하다.

## 6. 앞으로의 최적화 후보 (미적용)

- virtio-gpu 의 `blob`/`virgl` 은 Termux QEMU 에서 보장되지 않아 사용하지 않는다. 향후 Android GPU 를 쓰려면 Termux-x11 + virgl 조합을 별도 평가.
- 게스트 커널을 가상 장치 전용 설정으로 직접 빌드하면 커널 부팅 시간(19 s)을 줄일 수 있다.
- initramfs 없이 부팅: virtio-blk/ext4 가 built-in 이므로 `root=/dev/vda2` 로 initrd 를 생략할 수 있다(측정 후 결정).
- labwc 대신 더 작은 컴포지터(자체 구현) 평가는 M8.
