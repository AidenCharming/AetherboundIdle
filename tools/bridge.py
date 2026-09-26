#!/usr/bin/env python3
"""Drive the running game through the test bridge (scripts/autoload/test_bridge.gd). Standard library only.

  python tools/bridge.py launch [--godot PATH]      start the game with the bridge on and wait for it
  python tools/bridge.py new [slot] [--force]       start a fresh game in slot 2 ("Autoplay Slot"); another slot needs --force
  python tools/bridge.py state                      screen, gold, skills, expedition, fps, memory, error count
  python tools/bridge.py buttons                    every clickable button on screen right now
  python tools/bridge.py click "Buy egg" [index]    a real mouse click on the button with that text (scrolls to it)
  python tools/bridge.py screenshot [out.png]       save what the window shows
  python tools/bridge.py errors [since]             engine and script errors logged so far
  python tools/bridge.py monkey [--steps N]         click random buttons, stop on the first new error
  python tools/bridge.py run bugtest_benchmark      play for 10 minutes like a player, then write a PASS/FAIL report
      [--minutes 10] [--seed 1] [--compress 8] [--out DIR] [--keep] [--continue] [--godot PATH] [--movie]

See docs/TEST_BRIDGE.md for every command. Set GODOT to the Godot executable (or pass --godot) for `launch`.
"""
import datetime
import importlib
import json
import os
import random
import socket
import subprocess
import sys
import time
import traceback

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


def launch(godot, extra, quiet=False):
    exe = godot or os.environ.get("GODOT")
    if not exe:
        raise SystemExit("Pass --godot PATH or set GODOT to the Godot executable.\n"
                         "  Windows:    set GODOT=C:\\path\\to\\Godot_v4.7.2-stable_win64.exe\n"
                         "  PowerShell: $env:GODOT=\"C:\\path\\to\\Godot_v4.7.2-stable_win64.exe\"")
    args = [exe, "--path", ROOT] + extra + ["--", "--bridge", "--bridge-port=%d" % PORT]
    proc = subprocess.Popen(args, cwd=ROOT)
    print("started Godot (pid %d), waiting for the bridge..." % proc.pid)
    res = wait_ready(90.0)
    if not quiet:
        print(json.dumps(res, indent=1))
    return proc


def answering():
    try:
        send("ping", timeout=5)
        return True
    except OSError:
        return False


def run_scenario(name, rest, opt, flag):
    """Plays tools/scenarios/<name>.py against the game (launching it if it isn't running) and writes a report."""
    minutes = float(opt("--minutes", "10"))
    seed = int(opt("--seed", "1"))
    compress = float(opt("--compress", "8"))
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    out = os.path.abspath(opt("--out", os.path.join(ROOT, "bridge_runs", "%s-%s" % (name, stamp))))
    godot = opt("--godot")
    min_fps = float(opt("--min-fps", "20"))
    keep, cont, movie = flag("--keep"), flag("--continue"), flag("--movie")
    scen_dir = os.path.join(ROOT, "tools", "scenarios")
    if not os.path.exists(os.path.join(scen_dir, name + ".py")):
        found = sorted(f[:-3] for f in os.listdir(scen_dir) if f.endswith(".py") and not f.startswith("_"))
        raise SystemExit("No scenario %r. There are: %s" % (name, ", ".join(found)))
    sys.path.insert(0, scen_dir)
    player = importlib.import_module("_player")
    scenario = importlib.import_module(name)
    os.makedirs(out, exist_ok=True)
    # Godot must not treat run output as project files: an open editor, and every headless start (the
    # --movie frame stats), would first import each 1080p movie frame, which ran past the stats' timeout
    for d in (os.path.join(ROOT, "bridge_runs"), out):
        if os.path.commonpath([os.path.abspath(ROOT), d]) == os.path.abspath(ROOT):
            open(os.path.join(d, ".gdignore"), "a").close()
    proc = None
    extra_args = []
    if movie:
        # Movie Maker: every rendered frame is written to out/movie/ on a fixed 30 fps game clock
        if answering():
            raise SystemExit("--movie needs to start the game itself: quit the running one first (python tools/bridge.py quit).")
        os.makedirs(os.path.join(out, "movie"), exist_ok=True)
        extra_args = ["--write-movie", os.path.join(out, "movie", "frame.png"), "--fixed-fps", "30"]
    if not answering():
        if not (godot or os.environ.get("GODOT")):
            raise SystemExit("The game isn't running and I don't know where Godot is.\n"
                             "Start it yourself (Godot --path . -- --bridge), or set GODOT / pass --godot PATH so I can.")
        proc = launch(godot, extra_args, quiet=True)
    print("%s: %.1f min, seed %d, compress %.1f h -> %s" % (name, minutes, seed, compress, out))
    ctx = player.Ctx(HOST, PORT, out, minutes, seed, compress,
                     {"continue": cont, "min_fps": min_fps, "movie": movie, "keep": keep})
    extra = {}
    try:
        extra = scenario.run(ctx) or {}
    except player.GameDied as e:
        ctx.log("THE GAME STOPPED ANSWERING: %s" % e)
    except KeyboardInterrupt:
        ctx.note("stopped with Ctrl+C after %.0f s" % ctx.elapsed())
    except Exception:
        tb = traceback.format_exc()
        ctx.log("SCENARIO CRASHED\n" + tb)
        ctx.scenario_error = tb
        extra["scenario_error"] = tb
    if getattr(scenario, "after", None) and not ctx.game_died:
        try:
            extra.update(scenario.after(ctx) or {})
        except Exception:
            extra["scenario_error"] = extra.get("scenario_error", "") + traceback.format_exc()
    if ctx.game_died and proc is not None and proc.poll() is not None:
        ctx.game_exit_note += " (Godot exited with code %s)" % proc.returncode
    data = ctx.finish(name, extra)
    if (not keep or movie) and not ctx.game_died:
        try:
            send("quit", timeout=10)
        except OSError:
            pass
    if proc is not None:
        try:
            proc.wait(timeout=120)
        except subprocess.TimeoutExpired:
            proc.kill()
    if movie:
        data = player.process_movie(ctx, data, godot or os.environ.get("GODOT"))
    if getattr(scenario, "after_exit", None):
        try:
            data = scenario.after_exit(ctx, data) or data
        except Exception:
            print(traceback.format_exc())
    failed = data["result"] != "PASS" or bool(extra.get("scenario_error"))
    print(summary_text(data, out))
    if extra.get("scenario_error"):
        print("\nThe scenario script itself crashed (see actions.log):\n" + extra["scenario_error"])
    return 1 if failed else 0


def summary_text(d, out):
    lines = ["", "=" * 60, "%s: %s" % (d["scenario"], d["result"]), "=" * 60]
    g = d.get("goal_reached") or {}
    lines.append("goals claimed: %d (now on goal %s of %s: %s)" % (len(d["goals"]), g.get("index", -1) + 1, g.get("total", "?"), g.get("id", "?")))
    lines.append("errors: %d   invariant breaks: %d   stuck: %d   UI gaps: %d   screens: %d" % (
        len(d["errors"]), len(d["invariant_breaks"]), len(d["stuck"]), len(d["ui_gaps"]), len(d["screens"])))
    for e in d["errors"][:5]:
        lines.append("  error: " + e["text"].splitlines()[0][:150])
    for b in d["invariant_breaks"][:8]:
        lines.append("  break: " + b["text"][:150])
    for s in d["stuck"][:5]:
        lines.append("  stuck: " + s["reason"][:150])
    f, m = d["fps"], d["memory_mb"]
    lines.append("fps min/median %.0f/%.0f%s   memory %.0f -> %.0f MB (peak %.0f)" % (
        f["min"], f["median"], "" if f["judged"] else " (%s, not judged)" % f.get("not_judged_why", "software renderer"), m["start"], m["end"], m["peak"]))
    lines.append("skipped %.1f in-game hours; real time %.0f s" % (d["skipped_hours"], d["real_seconds"]))
    lines.append("report: " + os.path.join(out, "report.md"))
    return "\n".join(lines)


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

    def flag(name):
        if name in rest:
            rest.remove(name)
            return True
        return False

    if cmd == "launch":
        launch(opt("--godot"), rest)
        return 0
    if cmd == "run":
        if not rest:
            raise SystemExit("Which scenario? e.g. python tools/bridge.py run bugtest_benchmark")
        name = rest.pop(0)
        return run_scenario(name, rest, opt, flag)
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
        force = "--force" in rest
        rest = [a for a in rest if a != "--force"]
        args = {"slot": int(rest[0]) if rest else 2}
        if force:
            args["force"] = True
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
    elif cmd == "perf":
        args = {"reset": "--reset" in rest, "prefix": next((a for a in rest if not a.startswith("--")), "")}
    elif cmd == "raw":
        req = json.loads(rest[0])
        cmd, args = req.pop("cmd"), req
    try:
        res = send(cmd, **args)
    except OSError:
        raise SystemExit("The game isn't listening on port %d. Start it with: python tools/bridge.py launch" % PORT)
    if cmd == "perf" and res.get("ok"):
        print(res["text"])
        return 0
    print(json.dumps(res, indent=1))
    return 0 if res.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
