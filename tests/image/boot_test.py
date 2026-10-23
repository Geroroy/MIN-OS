#!/usr/bin/env python3
"""MIN OS 부팅 이미지 자동 테스트 (QEMU + 시리얼 콘솔 + pexpect)

시나리오
  1. ISO 로 부팅 (UEFI/OVMF, GRUB 메뉴를 시리얼로 조작: 'serial console debug' 항목)
  2. systemd 부팅 완료 → root 시리얼 셸 → greetd / labwc / minos-shell 동작 확인, Wayland 소켓 확인
  3. QEMU 모니터 screendump 로 화면 캡처 → 패널 픽셀 검사
  4. IPC 로 실행 메뉴·터미널 실행 → 프로세스/화면 확인
  5. reboot → 두 번째 부팅 확인
  6. poweroff → QEMU 종료 확인
사용: sudo python3 -I tests/image/boot_test.py out/minos-dev-ubuntu-noble-amd64.iso [--out DIR] [--timeout SEC]
"""
import argparse
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
    def __init__(self, iso, out, boot_timeout):
        self.iso = iso
        self.out = out
        self.boot_timeout = boot_timeout
        self.monitor = os.path.join(tempfile.mkdtemp(prefix="minos-qemu-"), "monitor.sock")
        self.vars = os.path.join(os.path.dirname(self.monitor), "ovmf-vars.fd")
        self.log = open(os.path.join(out, "serial.log"), "wb")
        self.child = None

    def start(self):
        env = dict(os.environ, MINOS_OVMF_VARS=self.vars)
        cmd = [os.path.join(REPO, "image/qemu/run.sh"), "--serial", "--monitor", self.monitor, self.iso]
        self.child = pexpect.spawn(cmd[0], cmd[1:], env=env, timeout=self.boot_timeout, logfile=self.log,
                                   encoding=None, dimensions=(50, 200))

    def expect(self, pattern, timeout=None):
        return self.child.expect(pattern, timeout=timeout or self.boot_timeout)

    def select_serial_entry(self):
        """GRUB 메뉴 → 's' 핫키 (serial console debug)"""
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
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    import check_screenshot  # tests/shell

    q = Qemu(args.iso, args.out, args.timeout)
    try:
        step("QEMU 시작, GRUB 메뉴에서 serial 항목 선택")
        q.start()
        q.select_serial_entry()

        step("커널/systemd 부팅 대기")
        q.expect(rb"systemd\[1\]|Welcome to|Ubuntu|Debian", timeout=args.timeout)
        q.wait_prompt()
        print("ok: root serial shell")
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
            rc, out = q.sh("pgrep -a minos-shell")
            check(rc == 0, f"second boot session: {out}")

        step("전원: PowerOff")
        q.child.sendline("busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff b false")
        q.expect([pexpect.EOF, rb"reboot: Power down"], timeout=300)
        time.sleep(2)
        check(not q.child.isalive() or q.child.expect([pexpect.EOF, pexpect.TIMEOUT], timeout=30) == 0,
              "QEMU exited after poweroff")
        print("\nPASS: MIN OS boot test (artifacts in %s)" % args.out)
    finally:
        q.close()


if __name__ == "__main__":
    main()
