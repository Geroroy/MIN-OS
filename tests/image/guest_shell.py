#!/usr/bin/env python3
"""게스트 진단: 이미지를 부팅해 root 시리얼 셸에서 명령을 실행하고 출력을 보여준다 (선택: 화면 캡처).
사용: sudo python3 -I tests/image/guest_shell.py TARGET [--uefi] [--res WxH] [--screendump PNG] [--wait SEC] -- CMD [CMD ...]
"""
import argparse, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from boot_test import Qemu, REPO  # noqa: E402

ap = argparse.ArgumentParser()
ap.add_argument("target"); ap.add_argument("--uefi", action="store_true"); ap.add_argument("--res", default="1280x720")
ap.add_argument("--screendump"); ap.add_argument("--wait", type=int, default=0); ap.add_argument("--timeout", type=int, default=1800)
ap.add_argument("cmds", nargs="*")
a = ap.parse_args()
out = os.path.join(REPO, "out", "guest-shell"); os.makedirs(out, exist_ok=True)
q = Qemu(a.target, out, a.timeout, a.res, a.uefi)
try:
    q.start(); q.select_serial_entry(); q.wait_prompt()
    q.child.sendline("stty cols 200; export TERM=dumb"); q.wait_prompt()
    if a.wait:
        time.sleep(a.wait)
    for c in a.cmds:
        rc, o = q.sh(c, timeout=120)
        print(f"$ {c}  [rc={rc}]\n{o}\n", flush=True)
    if a.screendump:
        png = q.screendump("diag"); os.replace(png, a.screendump); print("screendump:", a.screendump)
finally:
    q.close()
