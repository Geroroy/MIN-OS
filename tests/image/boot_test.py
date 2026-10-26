#!/usr/bin/env python3
"""하그라(HAGRA) 부팅 이미지 자동 테스트 (QEMU + 시리얼 콘솔 + pexpect)

대상: x86-64 live ISO 또는 디스크 이미지 번들 디렉터리(ARM64 기본: qcow2 + vmlinuz + initrd, 직접 커널 부팅)

시나리오
  1. ISO 로 부팅 (UEFI/OVMF, GRUB 메뉴를 시리얼로 조작: 'serial console debug' 항목) / 번들은 직접 커널 부팅
  2. systemd 부팅 완료 → root 시리얼 셸 → greetd / labwc / minos-shell 동작 확인, Wayland 소켓 확인
  3. QEMU 모니터 screendump 로 화면 캡처 → 패널 픽셀 검사
  4. IPC 로 실행 메뉴·터미널 실행 → 프로세스/화면 확인
  5. reboot → 두 번째 부팅 확인
  6. poweroff → QEMU 종료 확인
사용: sudo python3 -I tests/image/boot_test.py out/minos-dev-ubuntu-noble-amd64.iso [--out DIR] [--timeout SEC]
      sudo python3 -I tests/image/boot_test.py out/minos-arm64 [--res 1280x720]
결과: 스크린샷, serial.log, metrics.json (부팅 시간·메모리·CPU)
"""
import argparse
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import time

import pexpect

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "shell"))

PROMPT = "minos# "
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\r")


class Qemu:
    def __init__(self, iso, out, boot_timeout, res="1280x720", uefi=False):
        self.iso = iso
        self.out = out
        self.boot_timeout = boot_timeout
        self.res = res
        self.uefi = uefi
        self.disk_mode = os.path.isdir(iso) or iso.endswith(".qcow2")
        self.monitor = os.path.join(tempfile.mkdtemp(prefix="minos-qemu-"), "monitor.sock")
        self.vars = os.path.join(os.path.dirname(self.monitor), "ovmf-vars.fd")
        self.log = open(os.path.join(out, "serial.log"), "wb")
        self.child = None

    def start(self):
        env = dict(os.environ, MINOS_OVMF_VARS=self.vars)
        cmd = [os.path.join(REPO, "image/qemu/run.sh"), "--serial", "--monitor", self.monitor, "--res", self.res]
        if self.uefi:
            cmd.append("--uefi")
        cmd.append(self.iso)
        self.child = pexpect.spawn(cmd[0], cmd[1:], env=env, timeout=self.boot_timeout, logfile=self.log,
                                   encoding=None, dimensions=(50, 200))

    def expect(self, pattern, timeout=None):
        return self.child.expect(pattern, timeout=timeout or self.boot_timeout)

    def select_serial_entry(self):
        """GRUB 메뉴 → 's' 핫키 (serial console debug). 디스크 번들은 직접 커널 부팅이라 GRUB 이 없다."""
        if self.disk_mode:
            return
        self.expect(b"serial console debug")
        time.sleep(0.5)
        self.child.send("s")

    def wait_prompt(self):
        self.expect(PROMPT.encode())

    def sh(self, cmd, timeout=60):
        """시리얼 셸에서 명령 실행 후 출력 반환"""
        marker = "__MINOS_%d__" % int(time.time() * 1000)
        self.child.sendline(f"{cmd}; echo {marker}$?")
        self.child.expect(marker.encode() + rb"(\d+)", timeout=timeout)
        rc = int(self.child.match.group(1))
        out = ANSI.sub("", self.child.before.decode("utf-8", "replace"))
        # 에코된 명령 줄 제거
        lines = out.split("\n")
        if lines and cmd.split(";")[0].strip() in lines[0]:
            lines = lines[1:]
        self.child.expect(PROMPT.encode(), timeout=timeout)
        return rc, "\n".join(lines).strip()

    def monitor_cmd(self, cmd):
        s = socket.socket(socket.AF_UNIX)
        s.settimeout(30)
        s.connect(self.monitor)
        time.sleep(0.3)
        s.recv(4096)
        s.sendall((cmd + "\n").encode())
        time.sleep(1.5)
        try:
            data = s.recv(65536)
        except socket.timeout:
            data = b""
        s.close()
        return data.decode("utf-8", "replace")

    def screendump(self, name):
        ppm = os.path.join(self.out, name + ".ppm")
        self.monitor_cmd(f"screendump {ppm}")
        for _ in range(50):
            if os.path.exists(ppm) and os.path.getsize(ppm) > 1000:
                break
            time.sleep(0.2)
        png = os.path.join(self.out, name + ".png")
        from PIL import Image
        Image.open(ppm).convert("RGB").save(png)
        os.unlink(ppm)
        return png

    def close(self):
        if self.child and self.child.isalive():
            self.child.terminate(force=True)
        self.log.close()


def step(msg):
    print(f"\n==> {msg}", flush=True)


def check(cond, msg):
    if not cond:
        print(f"FAIL: {msg}")
        sys.exit(1)
    print(f"ok: {msg}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("iso")
    ap.add_argument("--out", default=os.path.join(REPO, "out", "boot-test"))
    ap.add_argument("--timeout", type=int, default=900, help="부팅 대기 한도 (초). TCG 에서는 수 분 걸린다")
    ap.add_argument("--skip-reboot", action="store_true")
    ap.add_argument("--res", default="1280x720")
    ap.add_argument("--uefi", action="store_true", help="디스크 번들을 UEFI 펌웨어(AAVMF/OVMF)+GRUB 으로 부팅")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    import check_screenshot  # tests/shell
    metrics = {"target": args.iso, "res": args.res, "uefi": args.uefi}

    q = Qemu(args.iso, args.out, args.timeout, args.res, args.uefi)
    try:
        step("QEMU 시작" + ("" if q.disk_mode else ", GRUB 메뉴에서 serial 항목 선택"))
        t0 = time.time()
        q.start()
        q.select_serial_entry()

        step("커널/systemd 부팅 대기")
        q.expect(rb"systemd\[1\]|Welcome to|Ubuntu|Debian", timeout=args.timeout)
        q.wait_prompt()
        metrics["boot_to_shell_s"] = round(time.time() - t0, 1)
        print(f"ok: root serial shell ({metrics['boot_to_shell_s']}s after QEMU start)")
        q.child.sendline("stty cols 200; export TERM=dumb")
        q.wait_prompt()

        step("시스템 상태")
        rc, out = q.sh("cat /etc/minos-release")
        check("MINOS_NAME" in out, f"minos-release: {out.splitlines()[0] if out else out}")
        rc, out = q.sh("systemctl is-system-running --wait", timeout=300)
        print(f"   systemd state: {out}")
        check(out.strip() in ("running", "degraded"), "systemd reached running/degraded")
        if out.strip() == "degraded":
            print(q.sh("systemctl --failed --no-pager")[1])

        step("세션: greetd → minos-session → labwc → minos-shell")
        deadline = time.time() + 180
        while time.time() < deadline:
            rc, out = q.sh("pgrep -c minos-shell")
            if rc == 0:
                break
            time.sleep(5)
        metrics["boot_to_shell_process_s"] = round(time.time() - t0, 1)
        rc, out = q.sh("systemctl is-active greetd")
        check(out.strip() == "active", "greetd active")
        rc, out = q.sh("pgrep -a labwc")
        check(rc == 0, f"labwc running: {out}")
        rc, out = q.sh("pgrep -a minos-shell")
        check(rc == 0, f"minos-shell running: {out}")
        rc, out = q.sh("ls /run/user/1000/ | grep -E '^wayland-[0-9]+$'")
        check(rc == 0, f"wayland socket: {out}")
        rc, out = q.sh("loginctl list-sessions --no-legend")
        print(f"   sessions: {out}")
        deadline = time.time() + 180
        while time.time() < deadline:
            rc, out = q.sh("cat /run/user/1000/minos-shell.log")
            if "minos-panel\" configured" in out or "ready" in out:
                break
            time.sleep(5)
        print("   shell log:\n      " + out.replace("\n", "\n      "))
        check("configured" in out, "panel layer surface configured")
        rc, out = q.sh("tail -5 /home/min/.local/state/minos/session.log")
        print("   session log:\n      " + out.replace("\n", "\n      "))

        rc, out = q.sh("uname -m; cat /etc/minos/profile 2>/dev/null; free -m | head -2; systemd-analyze 2>/dev/null | head -1")
        print("   system:\n      " + out.replace("\n", "\n      "))
        m = re.search(r"Mem:\s+(\d+)\s+(\d+)", out)
        if m:
            metrics["mem_total_mb"], metrics["mem_used_mb"] = int(m.group(1)), int(m.group(2))
        m = re.search(r"Startup finished in .*?= ([0-9.]+)s", out)
        if m:
            metrics["systemd_startup_s"] = float(m.group(1))
        rc, out = q.sh("ps -eo rss,comm --sort=-rss | head -6")
        print("   top rss:\n      " + out.replace("\n", "\n      "))
        metrics["top_rss"] = out.splitlines()[1:]
        rc, out = q.sh("sleep 5; top -b -n1 | head -3 | tail -1")
        print(f"   idle cpu: {out}")
        metrics["idle_top_cpu_line"] = out

        step("화면 캡처: 패널")
        time.sleep(3)
        png = q.screendump("01-desktop")
        from PIL import Image
        check_screenshot.check_panel(Image.open(png).convert("RGB"))

        step("실행 메뉴 (IPC)")
        asmin = "sudo -u min env XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 "
        rc, out = q.sh(asmin + "minos-shell --toggle-launcher")
        check(rc == 0, "toggle-launcher rc=0")
        time.sleep(4)
        png = q.screendump("02-launcher")
        check_screenshot.check_launcher(Image.open(png).convert("RGB"))
        q.sh(asmin + "minos-shell --toggle-launcher")

        step("터미널 실행 (IPC)")
        rc, out = q.sh(asmin + "minos-shell --terminal")
        time.sleep(6)
        rc, out = q.sh("pgrep -a foot")
        check(rc == 0, f"foot running: {out}")
        png = q.screendump("03-terminal")
        check_screenshot.check_foot(Image.open(png).convert("RGB"))
        q.sh("pkill foot")

        step("테마 전환: 깊은 단청 선택 (사용자 설정 저장, 셸·labwc·배경 즉시 반영)")
        asmin_home = "sudo -u min env HOME=/home/min XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 "
        deep_tokens = os.path.join(REPO, "build", "themes", "hagra-dancheong-deep", "tokens.json")
        light_tokens = os.path.join(REPO, "design", "tokens", "hagra.tokens.json")
        rc, out = q.sh(asmin_home + "hagra-theme list")
        print("   themes:\n      " + out.replace("\n", "\n      "))
        check("hagra-dancheong-deep" in out and "hagra-dancheong-light" in out, "both theme packs installed in the image")
        rc, out = q.sh(asmin_home + "hagra-theme apply hagra-dancheong-deep")
        check(rc == 0 and out.strip().endswith("hagra-dancheong-deep"), f"apply deep theme: {out.strip()}")
        time.sleep(10)
        rc, out = q.sh("cat /home/min/.config/minos/theme.conf")
        check("theme=hagra-dancheong-deep" in out, "selection saved in ~/.config/minos/theme.conf")
        png = q.screendump("04-theme-deep")
        if os.path.exists(deep_tokens):
            check_screenshot.load_tokens(deep_tokens)
            check_screenshot.check_panel(Image.open(png).convert("RGB"))
            check_screenshot.load_tokens(light_tokens)
        else:
            print("   (build/themes 없음: 깊은 단청 픽셀 검사 건너뜀)")

        step("전원: logind Reboot 경로 (minos-shell 와 동일한 D-Bus 호출)")
        if not args.skip_reboot:
            q.child.sendline("busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Reboot b false")
            q.select_serial_entry()
            print("ok: reboot reached GRUB again")
            q.expect(rb"systemd\[1\]|Welcome to|Ubuntu|Debian", timeout=args.timeout)
            q.wait_prompt()
            q.child.sendline("stty cols 200; export TERM=dumb")
            q.wait_prompt()
            rc, out = q.sh("systemctl is-system-running --wait", timeout=300)
            check(out.strip() in ("running", "degraded"), f"second boot: {out.strip()}")
            deadline = time.time() + 180
            while time.time() < deadline:
                rc, out = q.sh("pgrep -a minos-shell")
                if rc == 0:
                    break
                time.sleep(5)
            check(rc == 0, f"second boot session: {out}")

            step("테마 복원 확인: 재부팅 후 깊은 단청 유지 → 기본 테마로 복귀")
            deadline = time.time() + 120
            while time.time() < deadline:
                rc, out = q.sh("cat /run/user/1000/minos-shell.log")
                if "configured" in out:
                    break
                time.sleep(5)
            rc, live = q.sh("findmnt -no FSTYPE / ; test -d /run/live && echo live")
            is_live = "overlay" in live or "live" in live   # live ISO: 홈 디렉터리가 휘발성 overlay 라 재부팅 후 설정이 남지 않는다 (설치 전 매체의 성질)
            rc, out = q.sh(asmin_home + "hagra-theme current")
            rc, out2 = q.sh("tail -3 /home/min/.local/state/minos/session.log")
            print("   session log:\n      " + out2.replace("\n", "\n      "))
            time.sleep(3)
            if is_live:
                check(out.strip().endswith("hagra-dancheong-light"), f"live ISO (no persistence): default theme after reboot: {out.strip()}")
                metrics["theme_persist"] = "n/a (live overlay)"
                png = q.screendump("05-theme-light-live")
                check_screenshot.check_panel(Image.open(png).convert("RGB"))
            else:
                check(out.strip().endswith("hagra-dancheong-deep"), f"theme restored after reboot: {out.strip()}")
                metrics["theme_persist"] = "restored"
                png = q.screendump("05-theme-deep-restored")
                if os.path.exists(deep_tokens):
                    check_screenshot.load_tokens(deep_tokens)
                    check_screenshot.check_panel(Image.open(png).convert("RGB"))
                    check_screenshot.load_tokens(light_tokens)
                rc, out = q.sh(asmin_home + "hagra-theme reset")
                check(out.strip().endswith("hagra-dancheong-light"), f"reset to default: {out.strip()}")
                time.sleep(10)
                png = q.screendump("06-theme-light-again")
                check_screenshot.check_panel(Image.open(png).convert("RGB"))

        step("전원: PowerOff")
        q.child.sendline("busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff b false")
        q.expect([pexpect.EOF, rb"reboot: Power down"], timeout=300)
        time.sleep(2)
        check(not q.child.isalive() or q.child.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=30) == 0,
              "QEMU exited after poweroff")
        metrics["result"] = "PASS"
        print("\nPASS: HAGRA boot test (artifacts in %s)" % args.out)
    finally:
        with open(os.path.join(args.out, "metrics.json"), "w") as f:
            json.dump(metrics, f, indent=2, ensure_ascii=False)
        q.close()


if __name__ == "__main__":
    main()
