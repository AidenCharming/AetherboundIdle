"""The helper layer for bridge scenarios: `Ctx` is what a scenario's run(ctx) gets.

It wraps the test bridge (tools/bridge.py) with a time budget, a log of every step, checks after every
action (new errors, invariants, dialogs piling up, the screen shown, fps, memory) and the report
(report.md, report.json, actions.log and screenshots in the run's out dir). Standard library only.

Scenarios click by visible text. `ctx.gap(...)` records a place where a click path didn't exist and the
scenario had to fall back to a bridge shortcut; every gap shows up in the report.
"""
import collections
import contextlib
import glob
import shutil
import subprocess
import json
import math
import os
import random
import re
import socket
import statistics
import time

# the rail's text for each screen (scripts/ui/main.gd _fill_rail)
NAV = {"sanctum": "Sanctum", "nexus": "Nexus", "pods": "Genesis Pods", "expeditions": "Expeditions",
       "aetherlog": "Aether-Log", "inventory": "Inventory", "market": "Market", "eggmarket": "Egg Market",
       "works": "Sanctum Works"}

# buttons a scenario never presses on its own: they leave, wipe or overwrite (the save/load round trip
# presses "Save and return to title" deliberately, through ctx.click(..., allow_danger=True))
DANGER = ("quit", "delete", "reset", "wipe", "overwrite", "main menu", "return to title", "import", "export",
          "restore", "release", "fullscreen")


class GameDied(Exception):
    pass


class OutOfTime(Exception):
    pass


def _parse(text):
    """Bridge replies are JSON; a NaN or inf in the save would come back as a bare nan/inf token."""
    try:
        return json.loads(text)
    except ValueError:
        fixed = re.sub(r'(?<=[:\[,\s])(-?)inf\b', lambda m: m.group(1) + "Infinity", text)
        fixed = re.sub(r'(?<=[:\[,\s])-?nan\b', "NaN", fixed)
        return json.loads(fixed)


class Ctx:
    def __init__(self, host, port, out_dir, minutes, seed, compress, options=None):
        self.host, self.port = host, port
        self.out = out_dir
        self.shots_dir = os.path.join(out_dir, "shots")
        os.makedirs(self.shots_dir, exist_ok=True)
        self.minutes = minutes
        self.seed = seed
        self.rng = random.Random(seed)
        self.compress = compress
        self.options = options or {}
        self.started = time.time()
        self.deadline = self.started + minutes * 60.0
        self.min_fps = float(self.options.get("min_fps", 20))
        self._log_f = open(os.path.join(out_dir, "actions.log"), "w", encoding="utf-8")
        self.recent = collections.deque(maxlen=30)
        self.step = 0
        self.errors_seen = 0
        self.errors = []          # [{text, after, shot, recent}]
        self.breaks = []          # invariant breaks
        self.stuck_events = []
        self.gaps = []
        self.notes = []           # things worth reading that aren't failures
        self.screens = {}         # screen label -> screenshot path
        self.goals = []           # [{index, id, text, real_s, game_h}]
        self.fps = []
        self.memory = []
        self.skipped_hours = 0.0
        self.game_died = False
        self.game_exit_note = ""
        self.renderer = ""
        self._seen_breaks = set()
        self._last_buttons = []
        self._modal_open_since = {}
        self._shot_n = 0
        self.clips = []
        self.finished_normally = False

    # ------------------------------------------------------------ the wire

    def send(self, cmd, timeout=60.0, **args):
        req = dict(args, cmd=cmd)
        try:
            with socket.create_connection((self.host, self.port), timeout=5) as s:
                s.settimeout(timeout)
                s.sendall((json.dumps(req) + "\n").encode())
                buf = b""
                while not buf.endswith(b"\n"):
                    chunk = s.recv(1 << 20)
                    if not chunk:
                        break
                    buf += chunk
        except OSError as e:
            self.game_died = True
            self.game_exit_note = "%s during %r (%s)" % (type(e).__name__, cmd, e)
            raise GameDied(self.game_exit_note)
        if not buf:
            self.game_died = True
            self.game_exit_note = "the game closed the connection during %r" % cmd
            raise GameDied(self.game_exit_note)
        return _parse(buf.decode("utf-8", "replace"))

    # ------------------------------------------------------------ time

    def elapsed(self):
        return time.time() - self.started

    def time_left(self):
        return self.deadline - time.time()

    def out_of_time(self):
        return self.time_left() <= 0

    def wait(self, seconds):
        """Lets the game run (real seconds)."""
        seconds = max(0.0, min(seconds, self.time_left()))
        if seconds > 0:
            self.send("wait", seconds=seconds, timeout=seconds + 30)

    def wait_for(self, pred, seconds=10.0, step=0.4):
        """Polls state() until pred(state) is true or `seconds` pass. Returns the last state."""
        end = time.time() + seconds
        st = self.state()
        while not pred(st) and time.time() < end:
            self.send("wait", seconds=step)
            st = self.state()
        return st

    # ------------------------------------------------------------ Movie Maker clips

    def clip_once(self, name, settle=True):
        """A clip the first time only (and only when recording); otherwise a no-op block."""
        if not self.options.get("movie") or any(c["name"] == name for c in self.clips):
            return contextlib.nullcontext()
        return self.clip(name, settle)

    @contextlib.contextmanager
    def clip(self, name, settle=True):
        """Marks the frames recorded inside the block as a clip (only with --movie). `settle`: the animation
        should be over by the clip's end, so frames still changing there get flagged."""
        start = int(self.state().get("frame", 0))
        try:
            yield
        finally:
            end = int(self.state().get("frame", 0))
            self.clips.append({"name": name, "start": start, "end": end, "settle": settle})
            self.log("clip %s: frames %d-%d" % (name, start, end))

    def prune_frames(self):
        """Deletes recorded frames that no clip needs, so a long --movie run doesn't fill the disk."""
        movie = os.path.join(self.out, "movie")
        if not self.options.get("movie") or not os.path.isdir(movie):
            return
        now = int(self.state().get("frame", 0))
        keep = [(c["start"] - 5, c["end"] + 5) for c in self.clips]
        for f in glob.glob(os.path.join(movie, "frame*.png")):
            n = _frame_no(f)
            if n is not None and n < now - 300 and not any(a <= n <= b for a, b in keep):
                os.remove(f)

    # ------------------------------------------------------------ logging

    def log(self, msg):
        self.step += 1
        line = "%6.1fs #%d %s" % (self.elapsed(), self.step, msg)
        self.recent.append(line)
        self._log_f.write(line + "\n")
        self._log_f.flush()

    def note(self, msg):
        self.log("NOTE " + msg)
        if msg not in self.notes:
            self.notes.append(msg)

    def shot(self, label):
        self._shot_n += 1
        name = "%03d_%s.png" % (self._shot_n, re.sub(r"[^a-zA-Z0-9_-]+", "-", label).strip("-")[:48])
        path = os.path.abspath(os.path.join(self.shots_dir, name))
        try:
            res = self.send("screenshot", path=path)
        except GameDied:
            raise
        if not res.get("ok"):
            self.log("screenshot failed: %s" % res.get("error"))
            return ""
        return os.path.relpath(path, self.out)

    def stuck(self, reason):
        """Something the player wanted to do wasn't possible: log it, take a picture, move on."""
        self.log("STUCK " + reason)
        if any(s["reason"] == reason for s in self.stuck_events):
            return
        self.stuck_events.append({"reason": reason, "at": round(self.elapsed(), 1), "shot": self.shot("stuck"),
                                  "recent": list(self.recent)})

    def gap(self, what):
        """A click path that doesn't exist, worked around with a bridge shortcut."""
        self.log("UI GAP " + what)
        if what not in [g["what"] for g in self.gaps]:
            self.gaps.append({"what": what, "at": round(self.elapsed(), 1)})

    def breach(self, text, shot=True):
        """An invariant broke. Each distinct break is reported once (with how often it recurred)."""
        key = re.sub(r"\d+(\.\d+)?", "#", text)
        self.log("BREAK " + text)
        if key in self._seen_breaks:
            for b in self.breaks:
                if b["key"] == key:
                    b["count"] += 1
            return
        self._seen_breaks.add(key)
        self.breaks.append({"key": key, "text": text, "count": 1, "at": round(self.elapsed(), 1),
                            "shot": self.shot("break") if shot else "", "recent": list(self.recent)})

    # ------------------------------------------------------------ reading

    def state(self):
        return self.send("state")

    def get(self, path):
        res = self.send("get", path=path)
        return res.get("value") if res.get("ok") else None

    def player(self):
        return self.send("player").get("player", {})

    def goal(self):
        return self.send("goal").get("goal", {})

    def buttons(self):
        self._last_buttons = self.send("buttons").get("buttons", [])
        return self._last_buttons

    def button(self, text, exact=True):
        for b in self.buttons():
            if (b["text"] == text) if exact else (text.lower() in b["text"].lower() or text.lower() in b.get("tip", "").lower()):
                return b
        return None

    def has_button(self, text, exact=False, enabled=True):
        b = self.button(text, exact)
        return b is not None and (not enabled or not b["disabled"])

    def modals(self):
        return self.send("modals")

    # ------------------------------------------------------------ acting

    def click(self, text="", index=0, cid="", allow_danger=False, quiet=False, exact=False):
        """A real click on the button with that text (or the creature card `cid`). Returns True if it clicked."""
        if not allow_danger and text and any(w in text.lower() for w in DANGER):
            self.log("refused to click %r (it leaves, wipes or releases)" % text)
            return False
        args = {"text": text, "index": index}
        if exact:
            args["exact"] = True
        if cid:
            args["cid"] = cid
        res = self.send("click", **args)
        what = ("card " + cid) if cid else repr(text)
        if res.get("ok"):
            b = res.get("clicked", {})
            self.log("click %s at %s,%s" % (what, b.get("x"), b.get("y")))
            return True
        err = res.get("error", "")
        if not quiet:
            self.log("click %s failed: %s" % (what, err))
        if "no visible" in err and not cid:
            # a button `buttons` just listed must be clickable: list again and try once more before calling it
            listed = [b for b in self._last_buttons if b["text"] == text]
            if listed and self.button(text) is not None:
                again = self.send("click", **args)
                if not again.get("ok") and "no visible" in again.get("error", ""):
                    self.breach("buttons lists %r but clicking it says: %s" % (text, again.get("error")))
                elif again.get("ok"):
                    self.log("click %s worked on the second try" % what)
                    return True
        return False

    def click_at(self, x, y, why=""):
        self.send("click_at", x=x, y=y, canvas=True)
        self.log("click at %d,%d %s" % (x, y, why))

    def key(self, name):
        self.send("key", key=name)
        self.log("key " + name)

    def go(self, screen, arg=""):
        """Opens a page by clicking its entry in the rail, then checks the page shown is the one asked for."""
        self.clear_overlays()
        want = NAV.get(screen)
        if screen == "skill":
            p = self._player_cache or self.player()
            want = p.get("skills", {}).get(arg, {}).get("name", arg)
        st = self.state()
        if st.get("screen") == screen and st.get("screen_arg", "") == arg:
            return True
        if not self.click(want):
            self.gap("no rail button for %s %s: used the bridge's go" % (screen, arg))
            self.send("go", screen=screen, arg=arg)
        st = self.state()
        if st.get("screen") != screen or st.get("screen_arg", "") != arg:
            self.breach("asked for %s %s, the game shows %s %s" % (screen, arg, st.get("screen"), st.get("screen_arg")))
            return False
        return True

    _player_cache = None

    def clear_overlays(self, keep=()):
        """Dismisses reveals and dialogs a player would click away. Returns how many it closed."""
        closed = 0
        for _ in range(12):
            m = self.modals()
            rv = m.get("reveal", {})
            modals = m.get("modals", [])
            if modals:
                top = modals[-1]
                if top["title"] in keep:
                    return closed
                for pick in ("Continue", "Close", "Cancel", "Resume"):
                    if pick in top["buttons"]:
                        self.click(pick, quiet=True)
                        break
                else:
                    self.key("Escape")
                closed += 1
                self.send("wait", seconds=0.25)
                continue
            if rv.get("active"):
                if rv.get("can_continue"):
                    self.click("Click to continue", quiet=True)
                    closed += 1
                self.send("wait", seconds=0.4)
                continue
            return closed
        self.stuck("dialogs or reveals kept coming back after 12 dismissals")
        return closed

    def skip(self, hours, why="compress"):
        res = self.send("skip", hours=hours, timeout=180)
        self.skipped_hours += hours
        self.log("skip %.2fh (%s): %s" % (hours, why, json.dumps(res.get("summary", {}))))
        return res.get("summary", {})

    # ------------------------------------------------------------ checking

    def check(self, where=""):
        """New errors, invariants, dialogs piling up, fps and memory. Call it after every action."""
        self._checks = getattr(self, "_checks", 0) + 1
        if self._checks % 20 == 0:
            self.prune_frames()
        res = self.send("errors", since=self.errors_seen)
        new = res.get("errors", [])
        if new:
            self.errors_seen = max(self.errors_seen, max(int(e["n"]) for e in new))
            shot = self.shot("error")
            for e in new:
                self.log("ERROR " + e["text"].splitlines()[0])
                self.errors.append({"text": e["text"], "after": where or (self.recent[-1] if self.recent else ""),
                                    "shot": shot, "recent": list(self.recent)})
        for b in self.send("invariants").get("breaks", []):
            self.breach(b)
        st = self.state()
        self._sample(st)
        self._check_numbers(st)
        m = self.modals()
        modals = m.get("modals", [])
        if len(modals) > 2:
            self.breach("%d dialogs open at once: %s" % (len(modals), ", ".join(x["title"] or "?" for x in modals)))
        for x in modals:
            if x["age"] > 60:
                self.breach("the %r dialog has been open %.0f s" % (x["title"], x["age"]))
        return st

    def _check_numbers(self, st):
        for k in ("gold", "aether"):
            v = st.get(k)
            if isinstance(v, (int, float)) and (math.isnan(v) or math.isinf(v) or v < 0):
                self.breach("%s is %s" % (k, v))

    def _sample(self, st):
        if "fps" in st:
            self.fps.append(float(st["fps"]))
        if "memory_mb" in st:
            self.memory.append(float(st["memory_mb"]))
        self.renderer = st.get("renderer", self.renderer)

    def software_renderer(self):
        r = (self.renderer or "").lower()
        return any(w in r for w in ("llvmpipe", "softpipe", "swiftshader", "software"))

    # ------------------------------------------------------------ the report

    def finish(self, scenario, extra=None):
        extra = extra or {}
        fps_judged = not self.software_renderer()
        fps_sorted = sorted(self.fps[3:] or self.fps)
        fps_min = fps_sorted[0] if fps_sorted else 0
        fps_med = statistics.median(fps_sorted) if fps_sorted else 0
        # the lowest tenth percentile is what a player notices; a single slow sample (a screenshot, a skip) isn't
        fps_low = fps_sorted[len(fps_sorted) // 10] if fps_sorted else 0
        mem = self.memory
        mem_start, mem_peak, mem_end = (mem[0], max(mem), mem[-1]) if mem else (0, 0, 0)
        mem_growth = (mem_end - mem_start) / mem_start if mem_start else 0
        if mem and mem_growth > 0.5:
            self.breach("memory grew %.0f%% (%.0f MB to %.0f MB)" % (mem_growth * 100, mem_start, mem_end), shot=False)
        if fps_judged and fps_sorted and fps_low < self.min_fps:
            self.breach("fps fell below %d (10th percentile %.0f, minimum %.0f)" % (self.min_fps, fps_low, fps_min), shot=False)
        failed = bool(self.errors or self.breaks or self.game_died or extra.get("scenario_error"))
        data = {
            "scenario": scenario, "result": "FAIL" if failed else "PASS", "seed": self.seed,
            "minutes_asked": self.minutes, "real_seconds": round(self.elapsed(), 1),
            "compress_hours_asked": self.compress, "skipped_hours": round(self.skipped_hours, 2),
            "game_died": self.game_died, "game_exit_note": self.game_exit_note,
            "goals": self.goals, "errors": self.errors, "invariant_breaks": self.breaks,
            "stuck": self.stuck_events, "ui_gaps": self.gaps, "notes": self.notes,
            "screens": self.screens,
            "fps": {"min": fps_min, "p10": fps_low, "median": fps_med, "samples": len(self.fps),
                    "judged": fps_judged, "renderer": self.renderer, "threshold": self.min_fps},
            "memory_mb": {"start": mem_start, "peak": mem_peak, "end": mem_end, "growth": round(mem_growth, 3)},
            "clips": self.clips, "steps": self.step,
        }
        data.update(extra)
        with open(os.path.join(self.out, "report.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, indent=1, default=str)
        with open(os.path.join(self.out, "report.md"), "w", encoding="utf-8") as f:
            f.write(render_md(data))
        self._log_f.close()
        return data


def _frame_no(path):
    m = re.search(r"(\d+)\.png$", path)
    return int(m.group(1)) if m else None


def process_movie(ctx, data, godot):
    """After a --movie run: keeps every 5th frame of each clip (up to 16), measures frame-to-frame change
    with tools/frame_stats.gd, flags jumps, flicker and effects that never settle, deletes the rest."""
    movie = os.path.join(ctx.out, "movie")
    frames = sorted((_frame_no(f), f) for f in glob.glob(os.path.join(movie, "frame*.png")) if _frame_no(f) is not None)
    if not frames:
        ctx.notes.append("--movie: no frames were written")
    for c in data["clips"]:
        mine = [f for n, f in frames if c["start"] <= n <= c["end"]]
        if not mine:
            c["verdict"] = "no frames recorded for this clip"
            continue
        stats = []
        lst = os.path.join(ctx.out, "frames_%s.txt" % c["name"])
        res = lst + ".json"
        with open(lst, "w") as f:
            f.write("\n".join(os.path.abspath(p) for p in mine[:600]))
        try:
            root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            subprocess.run([godot, "--headless", "--path", root, "--script", "res://tools/frame_stats.gd", "--", lst, res],
                           timeout=600, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            with open(res) as f:
                stats = json.load(f)
        except Exception as e:  # the stats are a bonus: the sampled frames still go in the report
            c["verdict"] = "frame stats unavailable (%s)" % e
        for p in (lst, res):
            if os.path.exists(p):
                os.remove(p)
        diffs = [s["diff"] for s in stats if s.get("diff", -1) >= 0]
        flags = []
        if diffs:
            med = statistics.median(diffs)
            for i, s in enumerate(stats):
                d = s.get("diff", -1)
                if d > max(0.04, med * 6):
                    flags.append("jump at frame %d (change %.3f, clip median %.3f)" % (_frame_no(s["path"]), d, med))
            for i in range(1, len(stats) - 1):
                a, b, cc = stats[i - 1].get("lum"), stats[i].get("lum"), stats[i + 1].get("lum")
                if None not in (a, b, cc) and abs(b - a) > 0.05 and abs(cc - b) > 0.05 and (b - a) * (cc - b) < 0:
                    flags.append("flicker at frame %d (brightness %.2f, %.2f, %.2f)" % (_frame_no(stats[i]["path"]), a, b, cc))
            tail = diffs[-max(3, len(diffs) // 6):]
            if c.get("settle") and tail and min(tail) > 0.01:
                flags.append("still changing at the end of the clip (last diffs %s)" % ", ".join("%.3f" % d for d in tail[-4:]))
        c["flags"] = flags[:12]
        c["verdict"] = c.get("verdict") or ("%d frames; " % len(mine) + ("; ".join(flags[:6]) if flags else "no jumps, flicker or unsettled motion found"))
        dest = os.path.join(ctx.out, "clips", c["name"])
        os.makedirs(dest, exist_ok=True)
        c["frames"] = []
        for p in mine[::5][:16]:
            q = os.path.join(dest, os.path.basename(p))
            shutil.copy(p, q)
            c["frames"].append(os.path.relpath(q, ctx.out))
    shutil.rmtree(movie, ignore_errors=True)
    with open(os.path.join(ctx.out, "report.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1, default=str)
    with open(os.path.join(ctx.out, "report.md"), "w", encoding="utf-8") as f:
        f.write(render_md(data))
    return data


def _fmt_s(s):
    s = int(s)
    return "%d:%02d" % (s // 60, s % 60)


def _recent_block(lines):
    return "\n<details><summary>the last %d steps before it</summary>\n\n```\n%s\n```\n</details>\n" % (len(lines), "\n".join(lines))


def render_md(d):
    out = []
    w = out.append
    head = "# %s: %s" % (d["scenario"], d["result"])
    w(head + "\n")
    reasons = []
    if d["errors"]:
        reasons.append("%d engine/script error%s" % (len(d["errors"]), "" if len(d["errors"]) == 1 else "s"))
    if d["invariant_breaks"]:
        reasons.append("%d invariant break%s" % (len(d["invariant_breaks"]), "" if len(d["invariant_breaks"]) == 1 else "s"))
    if d["game_died"]:
        reasons.append("the game exited: %s" % d["game_exit_note"])
    if d.get("scenario_error"):
        reasons.append("the scenario script crashed (a bug in the benchmark, not the game): %s" % d["scenario_error"].strip().splitlines()[-1])
    w(("**Why it failed:** " + "; ".join(reasons) + "\n") if reasons else "No errors, no invariant breaks.\n")
    last = d["goals"][-1] if d["goals"] else None
    w("- Played %s real (asked for %s min), seed %s, %d steps." % (_fmt_s(d["real_seconds"]), d["minutes_asked"], d["seed"], d["steps"]))
    w("- Time compression: %.2f in-game hours skipped with the bridge `skip` (asked for %s)." % (d["skipped_hours"], d["compress_hours_asked"]))
    g = d.get("goal_reached")
    if g:
        w("- Overseer Vance: reached goal %d of %d (`%s`: %s)." % (g["index"] + 1, g["total"], g["id"], g.get("text", "")))
    w("- Screens covered: %d. Stuck: %d. UI gaps: %d." % (len(d["screens"]), len(d["stuck"]), len(d["ui_gaps"])))
    f = d["fps"]
    judged = "" if f["judged"] else " (software renderer %s: not judged)" % f["renderer"]
    w("- fps: min %.0f, 10th percentile %.0f, median %.0f over %d samples%s." % (f["min"], f["p10"], f["median"], f["samples"], judged))
    m = d["memory_mb"]
    w("- Memory: %.0f MB at the start, %.0f peak, %.0f at the end (%+.0f%%).\n" % (m["start"], m["peak"], m["end"], m["growth"] * 100))

    w("## Goals claimed\n")
    if not d["goals"]:
        w("None.\n")
    else:
        w("| # | Goal | Real time | In-game time |\n|---|---|---|---|")
        for g in d["goals"]:
            w("| %d | `%s` %s | %s | %.1f h |" % (g["index"] + 1, g["id"], g["text"], _fmt_s(g["real_s"]), g["game_h"]))
        w("")
    if d.get("goal_reached"):
        g = d["goal_reached"]
        w("Active at the end: goal %d `%s` (%s/%s)%s.\n" % (g["index"] + 1, g["id"], g.get("have", "?"), g.get("need", "?"),
                                                           ", done but not yet claimed" if g.get("done") else ""))

    w("## Errors\n")
    if not d["errors"]:
        w("None.\n")
    for e in d["errors"]:
        w("- **%s**" % e["text"].splitlines()[0])
        if len(e["text"].splitlines()) > 1:
            w("  ```\n  " + "\n  ".join(e["text"].splitlines()[1:]) + "\n  ```")
        w("  After: `%s`. Screenshot: [%s](%s)" % (e["after"], e["shot"], e["shot"]))
        w(_recent_block(e["recent"]))

    w("## Invariant breaks\n")
    if not d["invariant_breaks"]:
        w("None.\n")
    for b in d["invariant_breaks"]:
        w("- **%s** (at %s%s)%s" % (b["text"], _fmt_s(b["at"]), ", %d times" % b["count"] if b["count"] > 1 else "",
                                    ". Screenshot: [%s](%s)" % (b["shot"], b["shot"]) if b["shot"] else ""))
        w(_recent_block(b["recent"]))

    w("## Stuck\n")
    if not d["stuck"]:
        w("None.\n")
    for s in d["stuck"]:
        w("- %s (at %s). Screenshot: [%s](%s)" % (s["reason"], _fmt_s(s["at"]), s["shot"], s["shot"]))
        w(_recent_block(s["recent"]))

    w("## UI gaps (bridge shortcuts used)\n")
    w("None.\n" if not d["ui_gaps"] else "\n".join("- %s" % g["what"] for g in d["ui_gaps"]) + "\n")

    if d["notes"]:
        w("## Notes\n")
        w("\n".join("- %s" % n for n in d["notes"]) + "\n")

    w("## Screens covered\n")
    for k in sorted(d["screens"]):
        w("- %s: [%s](%s)" % (k, d["screens"][k], d["screens"][k]))
    w("")
    if d.get("round_trip"):
        w("## Save and load\n")
        rt = d["round_trip"]
        w("%s\n" % rt.get("verdict", ""))
        if rt.get("rows"):
            w("| | Before | After |\n|---|---|---|")
            for row in rt["rows"]:
                w("| %s | %s | %s |" % tuple(row))
            w("")
    if d.get("offline"):
        w("## Time away\n")
        w("```\n%s\n```\n" % json.dumps(d["offline"], indent=1))
    if d["clips"]:
        w("## Clips (Movie Maker)\n")
        for c in d["clips"]:
            w("### %s\n" % c["name"])
            w("Frames %s-%s. %s\n" % (c.get("start"), c.get("end"), c.get("verdict", "")))
            w(" ".join("![](%s)" % fr for fr in c.get("frames", [])) + "\n")
    return "\n".join(out) + "\n"
