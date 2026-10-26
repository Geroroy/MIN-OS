# Android(Termux)에서 하그라 실행하기

Android 스마트폰(예: Samsung Galaxy S25 Ultra) 위에서 **루트 권한 없이** Termux 의 QEMU 로 ARM64 가상 머신을 만들고,
그 안에서 하그라 전체(커널 → systemd → greetd → labwc → 하그라 셸)를 부팅한다. 화면은 QEMU 의 VNC 서버로 출력되고
Android VNC 클라이언트로 조작한다. PRoot 나 웹 시뮬레이터가 아니라 독립된 가상 머신이다.

> **검증 상태 (정직하게)**
> - PC(x86-64 호스트, QEMU TCG)에서 ARM64 번들의 부팅·세션·하그라 셸·터미널·재부팅·종료를 자동 테스트로 검증했다
>   (`docs/ANDROID_PERFORMANCE.md` 의 측정값 참고).
> - **Galaxy S25 Ultra 실기기에서는 아직 검증하지 않았다.** 아래 절차는 Termux 패키지 정의(qemu-system-aarch64-headless 11.x,
>   `--enable-vnc`)를 근거로 작성했으며, 실기기 결과는 §8 체크리스트로 확인한 뒤 이 문서에 기록해야 한다.

## 0. 가장 쉬운 방법 (PC 필요 없음)

ARM64 이미지는 GitHub Actions 의 ARM64 러너가 자동으로 빌드하고, QEMU 부팅 테스트를 통과하면
Release `android-latest` 에 올린다 (`.github/workflows/android-image.yml`). 휴대폰에서는 이것만 하면 된다.

1. **앱 두 개 설치**: Termux(F-Droid 또는 GitHub 판), AVNC(F-Droid) 같은 VNC 앱.
2. **Termux 에 한 줄 붙여넣기**:
   ```sh
   curl -fsSL https://raw.githubusercontent.com/Geroroy/MIN-OS/ccr-0dc4d66d-j60c3m/android/setup.sh | bash
   ```
   QEMU 설치 → 이미지(≈ 450 MB) 다운로드·체크섬 확인 → `~/hagra-arm64` 에 설치 → 실행 → VNC 앱 자동 열기까지 한 번에 한다.
   Wi-Fi 를 권장한다. 다운로드가 끊기면 같은 명령을 다시 실행하면 이어받는다.
3. VNC 앱이 열리면 `127.0.0.1:5900` 에 연결한다(자동으로 주소가 채워지지 않으면 직접 입력). 1~3분 뒤 하그라 바탕화면이 나타난다.

다음부터는 Termux 에서 `hagra` 만 입력한다. 종료는 하그라 전원 메뉴 또는 `hagra --stop`.
새 이미지로 바꾸려면 같은 한 줄 명령의 `bash` 뒤에 `-s -- --update` 를 붙인다:
```sh
curl -fsSL https://raw.githubusercontent.com/Geroroy/MIN-OS/ccr-0dc4d66d-j60c3m/android/setup.sh | bash -s -- --update
```
(`--update` 는 가상 디스크를 새로 받으므로 하그라 안에서 만든 파일이 사라진다.)

아래 §1~§7 은 이미지를 직접 빌드하거나 각 단계를 수동으로 하려는 경우의 상세 절차다.

## 1. 준비물

| 항목 | 내용 |
|---|---|
| 기기 | ARM64 Android (Galaxy S25 Ultra: Snapdragon 8 Elite, 12 GB RAM) |
| Termux | **F-Droid 또는 GitHub 릴리스 판**(Play 스토어 판은 패키지 저장소가 오래되어 QEMU 가 없다) |
| 저장 공간 | 번들 ≈ 1.3 GB + 게스트 디스크 증가분 (2 GB 이상 여유 권장) |
| VNC 클라이언트 | AVNC(F-Droid, 오픈소스) 또는 bVNC, RealVNC Viewer |
| PC | 번들을 빌드할 Linux PC (`sudo make image-arm64`) |

## 2. Termux 설치

1. F-Droid(https://f-droid.org) 에서 Termux 를 설치하거나 https://github.com/termux/termux-app/releases 의 APK 를 설치한다.
2. Termux 를 열고 저장소를 갱신한다.
   ```sh
   pkg update
   termux-setup-storage      # 공유 저장소(~/storage/shared) 접근 허용 — 파일 전송에 필요
   ```
3. 배터리 최적화에서 Termux 를 제외한다(설정 → 앱 → Termux → 배터리 → 제한 없음). 화면이 꺼져도 VM 이 멈추지 않도록
   Termux 알림의 **Acquire wakelock** 을 켜거나 `termux-wake-lock` 을 사용한다(실행 스크립트가 자동 호출).

## 3. QEMU 설치

```sh
pkg install qemu-system-aarch64-headless qemu-utils socat
pkg install ovmf          # 선택: UEFI 부팅(--uefi)에만 필요
```
또는 번들에 포함된 스크립트: `bash install-termux.sh` (확인 후 같은 명령을 실행한다).

패키지 근거: termux-packages 의 `qemu-system-x86-64-headless` 는 `aarch64-softmmu` 타깃을 포함해 빌드되며
`qemu-system-aarch64-headless` 서브패키지로 `bin/qemu-system-aarch64` 를 제공한다. configure 옵션에 `--enable-vnc --enable-vnc-jpeg --enable-png` 이 있다 (GTK/SDL 없음, KVM 은 Android 에서 사용 불가).

## 4. 하그라 이미지 만들기 (PC)

```sh
sudo scripts/install-deps.sh           # qemu-user-static, binfmt, qemu-system-arm 포함
sudo make image-arm64                   # 기본 SUITE=debian-trixie; 미러가 막힌 환경: SUITE=ubuntu-noble
make bundle-android                     # out/hagra-android-arm64.tar.zst
```
결과 `out/hagra-arm64/`:

| 파일 | 설명 |
|---|---|
| `hagra-arm64.qcow2` | GPT 디스크 (ESP + ext4 루트). 게스트가 쓰는 변경 사항이 여기에 저장된다 |
| `vmlinuz`, `initrd.img` | 직접 커널 부팅용 (디스크 안의 /boot 와 동일) |
| `hagra-image.conf` | 버전·커널 명령행 등 메타데이터 (스크립트가 읽음) |
| `start-hagra.sh` | Termux 실행 스크립트 |
| `kernel-version.txt` | 커널 버전 |

## 5. 휴대폰으로 전송

- **USB/MTP**: PC 에서 휴대폰의 `Download/` 에 `hagra-android-arm64.tar.zst` 복사 →
  Termux 에서 `tar --zstd -xf ~/storage/downloads/hagra-android-arm64.tar.zst -C ~/`
  (`~/storage` 는 `termux-setup-storage` 로 생성됨. zstd 가 없으면 `pkg install zstd`.)
- **같은 Wi-Fi**: PC 에서 `python3 -m http.server 8000` → Termux 에서 `curl -O http://PC-IP:8000/hagra-android-arm64.tar.zst`
- **adb**: `adb push out/hagra-android-arm64.tar.zst /sdcard/Download/`

Termux 의 홈(`~/`, 내부 저장소)에 두는 것이 가장 빠르다. 공유 저장소(`~/storage/shared`)는 FUSE 를 거쳐 느리다.

## 6. 실행

```sh
cd ~/hagra-arm64
bash start-hagra.sh                      # 기본: 2 GB RAM, 2 vCPU, 1280x720, VNC 127.0.0.1:5900
bash start-hagra.sh --res 960x540        # 느리면 해상도 낮춤 (또는 800x600)
bash start-hagra.sh --mem 1536 --smp 3   # 메모리/코어 조정
bash start-hagra.sh --status             # 상태
bash start-hagra.sh --stop               # 게스트에 전원 끄기 신호 → 종료
```
스크립트는 QEMU 설치·이미지·메모리·공간을 확인한 뒤 QEMU 를 실행하고, VNC 주소와 로그 경로를 출력한다.
시리얼 콘솔 로그는 `logs/serial-<시각>.log` 에 저장된다(개발 이미지는 root 자동 로그인 셸이 열려 있어 디버깅에 쓸 수 있다: `--serial`).

### 6.1 "Failed to find an available port: Address already in use"

VNC 포트 5900 을 다른 프로그램이 쓰고 있을 때 QEMU 가 바로 종료된다. 흔한 원인은 이전 설치(`~/minos-arm64`, 이름 정리 전)에서 띄운 QEMU 가 아직 떠 있는 것이다.
`start-hagra.sh` 는 이제 이전 버전 QEMU 를 알아서 종료하고, 그래도 포트가 막혀 있으면 다음 빈 디스플레이(:1 → 127.0.0.1:5901 …)를 골라 출력에 알려 준다. 직접 정리하려면 `hagra --stop` (떠돌이 qemu-system-aarch64 포함) 또는 `pkill qemu-system-aarch64`.

## 7. VNC 연결과 조작

1. VNC 클라이언트에서 새 연결: 주소 `127.0.0.1`, 포트 `5900` (비밀번호 없음 — 127.0.0.1 에만 바인딩되어 외부에서 접근 불가).
2. 처음에는 검은 화면 또는 커널 메시지만 보이다가 1~3분 뒤 하그라 바탕화면과 하단 패널이 나타난다.
3. 조작:
   - **터치 = 마우스 왼쪽 클릭/드래그** (virtio-tablet 절대 좌표). 길게 누르기 = 오른쪽 클릭(클라이언트 설정에 따라 다름).
   - **소프트웨어 키보드**: 클라이언트의 키보드 버튼으로 호출. `Super`(Win) 키는 AVNC/bVNC 의 추가 키 바에서 보낼 수 있다.
     Super 키가 없으면 패널 왼쪽 **하그라** 버튼으로 실행 메뉴를, 바탕화면 **가운데 클릭**/**우클릭 메뉴**로 터미널을 연다.
   - 종료/재부팅: 패널 오른쪽 전원 버튼 → Shut down / Reboot. (또는 Termux 에서 `bash start-hagra.sh --stop`)
4. 화면 크기: `--res` 로 바꾼다. 클라이언트의 "화면에 맞춤" 확대를 켜면 1280×720 도 읽기 쉽다.

## 8. 실기기 검증 체크리스트 (Galaxy S25 Ultra)

실기기에서 아래를 수행하고 결과를 `docs/ANDROID_PERFORMANCE.md` 의 "실기기 측정" 표에 기록한다.

| # | 확인 | 방법 | 결과 |
|---|---|---|---|
| 1 | QEMU 설치 | `qemu-system-aarch64 --version` | ☐ |
| 2 | 커널 부팅 | `logs/serial-*.log` 에 `Linux version` 과 `systemd[1]` | ☐ |
| 3 | systemd running | 시리얼 셸에서 `systemctl is-system-running` | ☐ |
| 4 | 세션 시작 | `loginctl list-sessions`, `pgrep labwc hagra-shell` | ☐ |
| 5 | 하그라 셸 표시 | VNC 화면 하단 패널 | ☐ |
| 6 | 터미널 실행 | 하그라 메뉴 → Terminal | ☐ |
| 7 | 터치 조작 | 실행 메뉴 열기, 창 이동 | ☐ |
| 8 | 재부팅 | 전원 메뉴 → Reboot → 다시 바탕화면 | ☐ |
| 9 | 종료 | 전원 메뉴 → Shut down → QEMU 종료, 스크립트 "종료됨" 출력 | ☐ |
| 10 | 부팅 시간/CPU | 로그 타임스탬프, Termux `top` | ☐ |

## 9. 예상되는 제약

- **속도**: KVM 이 없으므로 TCG 소프트웨어 에뮬레이션이다. 2 vCPU 로 부팅 1~3분, UI 는 "사용 가능하지만 느림"을 예상한다.
  MTTCG 로 vCPU 마다 호스트 스레드를 쓰므로 `--smp 3~4` 가 도움이 될 수 있지만 발열·배터리가 늘어난다.
- **GPU 없음**: 모든 렌더링은 CPU. 동영상·3D 는 대상이 아니다.
- **메모리**: 게스트 2 GB + QEMU 자체 ≈ 300 MB. Android 가 메모리 압박 시 Termux 를 종료할 수 있다(wakelock·배터리 예외 설정 권장).
- **네트워크**: 사용자 모드 네트워크(slirp). 게스트 → 바깥 연결만 가능, 바깥 → 게스트는 포트 포워딩 필요.
- **오디오 없음**, **USB 패스스루 없음**.
- **화면 회전/DPI**: VNC 클라이언트가 처리한다. 게스트 해상도는 고정(`--res`).

## 10. 문제 해결

| 증상 | 원인/대응 |
|---|---|
| `qemu-system-aarch64: command not found` | `pkg install qemu-system-aarch64-headless`. Play 스토어 Termux 는 저장소가 막혀 있다 → F-Droid 판 |
| `Could not access KVM kernel module` | 스크립트는 KVM 을 쓰지 않는다. 직접 실행했다면 `-accel tcg` 를 지정 |
| 메모리 부족 경고 후 종료 | `--mem 1536`, 다른 앱 종료, 또는 `--force` |
| VNC 연결 거부 | QEMU 가 아직 시작 중이거나 종료됨 → `--status`, `logs/qemu-*.log` 확인. 포트 충돌 시 `--vnc 1` (5901) |
| 화면이 계속 검정 | 부팅 중(최대 3분). `logs/serial-*.log` 마지막 줄 확인. `hagra-shell.log` 는 게스트 `/run/user/1000/` |
| 패널은 보이는데 입력이 안 됨 | VNC 클라이언트 입력 모드를 "터치패드"가 아닌 "직접 터치(absolute)"로 |
| 재부팅 후 다시 부팅되지 않음 | 직접 커널 부팅은 QEMU 가 재시작하므로 정상 동작해야 함. 로그 확인 후 `--stop` 후 재실행 |
| 부팅 중 `Gave up waiting for root device` | 디스크 파일 손상/경로 오류 → `qemu-img check hagra-arm64.qcow2`, 번들 재전송 |
| Termux 가 백그라운드에서 죽음 | 배터리 최적화 제외, `termux-wake-lock`, 화면 분할로 VNC 와 Termux 동시 표시 |
