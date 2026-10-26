# 하그라 ARM64 아키텍처

하그라는 x86-64(데스크톱 PC)와 ARM64(Android 스마트폰 위의 QEMU)를 같은 코드베이스로 지원한다.
사용자 공간(하그라 셸, HagraUI, 세션, 설정)은 아키텍처에 독립적이며, 아키텍처에 따라 달라지는 것은
**이미지 빌드(커널 패키지·미러·부트로더·이미지 포맷)**와 **QEMU 실행 옵션**뿐이다.

## 1. 아키텍처별 구성 요약

| 항목 | x86-64 (PC) | ARM64 (Android/Termux QEMU) |
|---|---|---|
| 대상 머신 | 실제 PC, QEMU `q35` | QEMU `virt` (GICv3, PCIe) |
| 이미지 포맷 | live ISO (squashfs + live-boot, BIOS+UEFI) | GPT 디스크 이미지 → `hagra-arm64.qcow2` + `vmlinuz` + `initrd.img` 번들 |
| 부팅 방식 | GRUB(BIOS/UEFI) → live-boot | **직접 커널 부팅**(`-kernel/-initrd`, 기본·검증됨) 또는 UEFI(AAVMF/edk2) → GRUB arm64-efi (검증됨, 약 20 s 느림) |
| 커널 | Ubuntu `linux-image-virtual` / Debian `linux-image-amd64` | Ubuntu `linux-image-virtual`(+`linux-modules-extra`) / Debian `linux-image-arm64` |
| 패키지 미러 | archive.ubuntu.com / deb.debian.org | ports.ubuntu.com / deb.debian.org |
| 루트 식별 | squashfs (live) | `root=LABEL=hagra-root` (ext4, `/dev/vda2`) |
| 콘솔 | `ttyS0` | `ttyAMA0` (PL011) |
| 디스플레이 | virtio-vga / virtio-gpu | `virtio-gpu-pci` (2D, `xres/yres` 로 해상도 지정) |
| 입력 | USB tablet/keyboard, virtio | `virtio-keyboard-pci`, `virtio-tablet-pci` (VNC 의 절대 좌표 포인터) |
| 렌더링 | GPU 있으면 GLES, 없으면 pixman/software | 항상 소프트웨어 (`hagra.render=software`) |
| 프로필 | `default` | `mobile` (서비스·타이머 최소화, 저널 휘발성) |

빌드 명령은 하나다. `image/build.sh --arch amd64|arm64 --format iso|disk --profile default|mobile`.
기본값은 amd64 → iso/default, arm64 → disk/mobile 이다.

## 2. 코드베이스에서 아키텍처 의존 부분

```
image/config/suites/*.conf     MIRROR_arm64, KERNEL_PKGS_amd64 / KERNEL_PKGS_arm64
image/config/packages.iso      live-boot (ISO 전용)
image/config/packages.disk     디스크 이미지 전용
image/config/hooks/35-disk-config.sh   fstab (LABEL 기반)
image/config/hooks/50-kernel.sh        커널 설치, virtio-gpu/virtio-input 모듈 보충, initramfs
image/config/hooks/55-bootloader.sh    대상 chroot 안에서 grub-efi-<arch>-bin 으로 BOOTAA64.EFI/BOOTX64.EFI 생성
image/config/hooks/60-dev-image.sh     ttyS0 + ttyAMA0 시리얼 자동 로그인 (개발 이미지)
image/config/hooks/70-mobile.sh        mobile 프로필
image/build.sh                         3/4단계: squashfs+ISO 또는 파티션+qcow2
image/qemu/run.sh                      PC 에서 두 아키텍처 실행 (장치 모델 공통)
android/start-hagra.sh                 Termux 실행 스크립트 (같은 장치 모델)
```

그 밖의 모든 코드(`shell/`, `libs/`, `session/`)는 아키텍처를 알지 못한다. 하그라 컴포넌트는 **대상 아키텍처의 chroot 안에서**
빌드되므로(hook 40) 교차 컴파일 설정이 필요 없다. x86-64 호스트에서 ARM64 chroot 는 `qemu-user-static` + `binfmt_misc`
로 투명하게 실행된다(빌드 시간은 네이티브 대비 약 10~20배).

## 3. ARM64 디스크 이미지 레이아웃

```
GPT
 ├─ p1  HAGRA-ESP   128 MiB  FAT  /EFI/BOOT/BOOTAA64.EFI (GRUB standalone, UEFI 부팅용)
 └─ p2  hagra-root  ≥ 6 GiB  ext4 (label hagra-root)  전체 rootfs, /boot/vmlinuz, /boot/initrd.img, /boot/grub/grub.cfg
```

- loop 장치 없이 만들어진다: `mformat/mcopy`(ESP), `mke2fs -d`(루트), `sfdisk`(GPT), `dd conv=sparse`, `qemu-img convert`.
- qcow2 는 희소 파일이어서 실제 크기는 사용량(≈ 1.2 GB)만큼이다. 게스트에서는 6 GiB 로 보이며 쓰기 가능하다.
- 번들 디렉터리에 `vmlinuz`, `initrd.img` 를 함께 두어 펌웨어 없이 `-kernel/-initrd` 로 부팅한다. 이것이 **기본·검증된 경로**다.
  UEFI 경로(`--uefi`)는 같은 이미지의 ESP 를 사용하며, Termux 에서는 `ovmf` 패키지의 edk2 aarch64 펌웨어가 필요하다.

## 4. 부팅 흐름 (ARM64, 직접 커널 부팅)

```
qemu-system-aarch64 -M virt -kernel vmlinuz -initrd initrd.img -append "root=LABEL=hagra-root rw … console=ttyAMA0"
  → 커널 (Ubuntu generic 6.8, EFI zboot 형식: QEMU 가 직접 풀어 로드)
  → initramfs (initramfs-tools, virtio_blk/virtio_pci 모듈) → LABEL 로 루트 탐색 → ext4 마운트
  → systemd → greetd(자동 로그인 hagra) → hagra-session → labwc(pixman) → hagra-shell(QT_QUICK_BACKEND=software)
  → virtio-gpu 스캔아웃 → QEMU VNC 서버 (127.0.0.1:5900) → Android VNC 클라이언트
```

### 4.1 UEFI 경로에서 배운 점
- Ubuntu arm64 `vmlinuz` 는 gzip 으로 압축된 Image(EFI stub 포함)다. standalone GRUB 에 `gzio` 모듈이 없으면
  "plain image kernel not supported" 로 실패한다 → hook 55 의 모듈 목록에 `gzio` 포함.
- virtio-gpu 는 렌더 노드(`renderD128`)를 제공하지만 3D 가속이 없다. "렌더 노드가 있으면 GL" 로 판단하면 EGL 이 llvmpipe 로
  떨어져 TCG 에서 패널이 수십 초 동안 그려지지 않는다 → `hagra-session` 이 가상 GPU 드라이버(virtio-pci, bochs, simpledrm 등)를
  감지해 pixman/Qt software 로 전환하고, mobile 프로필의 GRUB 기본 항목은 `hagra.render=software` 를 명시한다.

## 5. 결정 사항과 근거

| 결정 | 근거 |
|---|---|
| 직접 커널 부팅을 기본으로 | 펌웨어 의존성 없음, 부팅이 수 초 빠름, 커널 명령행(해상도·렌더링·콘솔)을 실행 스크립트에서 제어 가능. UEFI 는 설치형 시스템과 실기기 대비용으로 병행 유지 |
| virtio-gpu 2D + 소프트웨어 렌더링 | TCG 에서는 GPU 가속이 없다. virgl 은 Termux QEMU 에서 보장되지 않으며 호스트 GL 컨텍스트가 필요하다 |
| virtio-input(키보드·태블릿) | USB 에뮬레이션보다 가볍고, VNC 의 절대 좌표가 그대로 태블릿 입력으로 전달된다 |
| 디스크 이미지(qcow2) | live ISO 는 overlay 가 RAM 에 상주해 메모리를 낭비한다. 디스크 이미지는 변경 사항이 영속되고 설치형과 같은 레이아웃이다 |
| `mobile` 프로필을 이미지 빌드 시점에 적용 | 런타임 감지보다 단순하고 결정적이다. 같은 rootfs 로 `--profile default` 빌드도 가능 |
