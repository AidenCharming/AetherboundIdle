#!/usr/bin/env python3
"""Drive the running game through the test bridge (scripts/autoload/test_bridge.gd). Standard library only.

  python tools/bridge.py launch [--godot PATH]      start the game with the bridge on and wait for it
  python tools/bridge.py new [slot]                 start a fresh game (slot 2, "Autoplay Slot", by default)
  python tools/bridge.py state                      screen, gold, skills, expedition, fps, memory, error count
  python tools/bridge.py buttons                    every clickable button on screen right now
  python tools/bridge.py click "Buy egg" [index]    a real mouse click on the button with that text (scrolls to it)
  python tools/bridge.py screenshot [out.png]       save what the window shows
  python tools/bridge.py errors [since]             engine and script errors logged so far
  python tools/bridge.py monkey [--steps N]         click random buttons, stop on the first new error

See docs/TEST_BRIDGE.md for every command. Set GODOT to the Godot executable (or pass --godot) for `launch`.
"""
import json
import os
import random
import socket
import subprocess
import sys
import time

HOST = "127.0.0.1"
PORT = int(os.environ.get("BRIDGE_PORT", "47625"))
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# buttons the monkey never presses: they leave the game, wipe saves or close the window
MONKEY_SKIP = ("quit", "delete", "reset", "wipe", "overwrite", "leave", "main menu", "title", "import", "export", "fullscreen")


def send(cmd, timeout=120.0, **args):
    """One request, one reply. Raises ConnectionError when the game isn't listening."""
    req = dict(args, cmd=cmd)
    with socket.create_connection((HOST, PORT), timeout=5) as s:
        s.settimeout(timeout)
        s.sendall((json.dumps(req) + "\n").encode())
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
    return json.loads(buf.decode() or "{}")


def wait_ready(seconds=60.0):
    end = time.time() + seconds
    while time.time() < end:
        try:
            return send("ping", timeout=5)
        except OSError:
            time.sleep(0.5)
    raise SystemExit("The game didn't answer on port %d. Is it running with -- --bridge?" % PORT)


def launch(godot, extra):
    exe = godot or os.environ.get("GODOT")
    if not exe:
        raise SystemExit("Pass --godot PATH or set GODOT to the Godot executable.")
    args = [exe, "--path", ROOT] + extra + ["--", "--bridge", "--bridge-port=%d" % PORT]
    proc = subprocess.Popen(args, cwd=ROOT)
    print("started Godot (pid %d), waiting for the bridge..." % proc.pid)
    print(json.dumps(wait_ready(), indent=1))


def monkey(steps, seed, shots, delay):
    """Random clicks on enabled buttons. Logs every step; on a new error, saves a screenshot and stops."""
    rng = random.Random(seed)
    os.makedirs(shots, exist_ok=True)
    seen = send("errors").get("total", 0)
    log = []
    for i in range(steps):
        buttons = [b for b in send("buttons").get("buttons", [])
                   if not b["disabled"] and not any(w in b["text"].lower() for w in MONKEY_SKIP)]
        if not buttons:
            send("key", key="Escape")
            log.append("%d: no buttons, pressed Escape" % i)
            continue
        b = rng.choice(buttons)
        res = send("click_at", x=b["x"], y=b["y"], canvas=True)
        log.append("%d: clicked %r at %d,%d (%s)" % (i, b["text"], b["x"], b["y"], "ok" if res.get("ok") else res.get("error")))
        if delay:
            time.sleep(delay)
        err = send("errors", since=seen)
        if err.get("errors"):
            shot = send("screenshot", path=os.path.abspath(os.path.join(shots, "monkey_error_%d.png" % i)))
            print("\n".join(log[-15:]))
            print("\nNEW ERRORS after step %d:" % i)
            for e in err["errors"]:
                print(" ", e["text"])
            print("screenshot:", shot.get("path"))
            return 1
    print("\n".join(log[-10:]))
    print("\n%d steps, no new errors. State: %s" % (steps, json.dumps(send("state"))[:400]))
    return 0


def main(argv):
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        return 0
    cmd, rest = argv[0], argv[1:]

    def opt(name, default=None):
        if name in rest:
            i = rest.index(name)
            val = rest[i + 1]
            del rest[i:i + 2]
            return val
        return default

    if cmd == "launch":
        launch(opt("--godot"), rest)
        return 0
    if cmd == "monkey":
        return monkey(int(opt("--steps", "200")), int(opt("--seed", "1")), opt("--shots", "bridge_shots"), float(opt("--delay", "0.2")))
    # everything else maps straight onto a bridge command
    args = {}
    if cmd == "click":
        args = {"text": rest[0], "index": int(rest[1]) if len(rest) > 1 else 0}
    elif cmd == "click_at":
        args = {"x": float(rest[0]), "y": float(rest[1]), "canvas": True}
    elif cmd == "scroll":
        args = {"x": float(rest[0]), "y": float(rest[1]), "steps": int(rest[2]) if len(rest) > 2 else 3}
    elif cmd == "key":
        args = {"key": rest[0]}
    elif cmd == "screenshot":
        args = {"path": os.path.abspath(rest[0])} if rest else {}
    elif cmd == "go":
        args = {"screen": rest[0], "arg": rest[1] if len(rest) > 1 else ""}
    elif cmd in ("new", "load"):
        args = {"slot": int(rest[0]) if rest else 2}
    elif cmd == "skip":
        args = {"hours": float(rest[0]) if rest else 1.0}
    elif cmd == "wait":
        args = {"seconds": float(rest[0]) if rest else 1.0}
    elif cmd == "errors":
        args = {"since": int(rest[0]) if rest else 0}
    elif cmd == "get":
        args = {"path": rest[0] if rest else ""}
    elif cmd == "eval":
        args = {"expr": " ".join(rest)}
    elif cmd == "game":
        args = {"method": rest[0], "args": [json.loads(a) if a[:1] in "[{\"0123456789-" or a in ("true", "false", "null") else a for a in rest[1:]]}
    elif cmd == "raw":
        req = json.loads(rest[0])
        cmd, args = req.pop("cmd"), req
    try:
        res = send(cmd, **args)
    except OSError:
        raise SystemExit("The game isn't listening on port %d. Start it with: python tools/bridge.py launch" % PORT)
    print(json.dumps(res, indent=1))
    return 0 if res.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
