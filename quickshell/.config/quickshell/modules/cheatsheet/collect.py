#!/usr/bin/env python3
"""Collect keybinds from every app that has them and write ~/.cache/cheatsheet/binds.json.

Everything here is queried from the *running* app rather than parsed out of a config
file, so the cheatsheet cannot drift from reality. The one thing each app has to
supply is a human description next to the bind itself:

    hyprland  hl.bind(..., { desc = "Open terminal" })    -> hyprctl binds -j
    nvim      vim.keymap.set(..., { desc = "Find files" }) -> nvim_get_keymap()
    tmux      the bound command is its own description     -> tmux list-keys
    kitty     kitty ships descriptions for its defaults    -> kitty +runpy
    zsh       the widget name is its own description       -> bindkey -L

Run it from hyprland.start; it takes about a second (nvim dominates).
"""

import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone

CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache")), "cheatsheet"
)
OUT = os.path.join(CACHE, "binds.json")


def run(cmd, **kw):
    """Run a command, returning stdout, or None if it is missing or fails."""
    if not shutil.which(cmd[0]):
        return None
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=30, **kw)
    except (subprocess.TimeoutExpired, OSError):
        return None
    return p.stdout if p.returncode == 0 else None


# --------------------------------------------------------------------------
# key prettifying
# --------------------------------------------------------------------------

# Hyprland modmask bits, in the order we want them shown
MODS = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]

PRETTY = {
    "RETURN": "Enter", "ESCAPE": "Esc", "SLASH": "/", "GRAVE": "`",
    "mouse:272": "Left click", "mouse:273": "Right click",
    "mouse_down": "Scroll down", "mouse_up": "Scroll up",
    "XF86AudioRaiseVolume": "Vol +", "XF86AudioLowerVolume": "Vol −",
    "XF86AudioMute": "Mute", "XF86AudioMicMute": "Mic mute",
    "XF86MonBrightnessUp": "Bright +", "XF86MonBrightnessDown": "Bright −",
    "XF86AudioNext": "Next", "XF86AudioPrev": "Prev",
    "XF86AudioPlay": "Play", "XF86AudioPause": "Pause",
    "Print": "PrtSc",
}


def pretty_key(k):
    return PRETTY.get(k, k)


def bind(keys, desc, **extra):
    """One row of the sheet. `keys` is a list of tokens so the UI can draw key caps."""
    row = {"keys": [pretty_key(k) for k in keys], "desc": desc}
    row.update(extra)
    return row


def group(name, binds):
    return {"name": name, "binds": binds}


# --------------------------------------------------------------------------
# hyprland
# --------------------------------------------------------------------------

def hyprland():
    raw = run(["hyprctl", "binds", "-j"])
    if not raw:
        return None
    try:
        entries = json.loads(raw)
    except json.JSONDecodeError:
        return None

    # Group by modifier combination -- it needs no extra config syntax and happens
    # to read well, since a modifier set is usually one coherent family of actions.
    buckets = {}
    for e in entries:
        mask = e.get("modmask", 0)
        mods = [name for bit, name in MODS if mask & bit]
        keys = mods + [e.get("key", "")]
        desc = (e.get("description") or "").strip()
        if not desc:
            # Surfaced rather than hidden, so a bind missing its desc is obvious.
            desc = "(no description — add desc = \"…\" in hyprland.lua)"
        label = " + ".join(mods) if mods else "Media & system keys"
        buckets.setdefault(label, []).append(bind(keys, desc, undocumented=not (e.get("description") or "").strip()))

    # SUPER first, then SUPER+<mod> alphabetically, bare keys last.
    def order(label):
        if label == "SUPER":
            return (0, "")
        if label == "Media & system keys":
            return (2, "")
        return (1, label)

    return {
        "id": "hyprland",
        "name": "Hyprland",
        "icon": "\uf108",
        "match": ["*"],
        "groups": [group(k, buckets[k]) for k in sorted(buckets, key=order)],
    }


# --------------------------------------------------------------------------
# neovim
# --------------------------------------------------------------------------

NVIM_LUA = r"""
local out = {}
for _, mode in ipairs({ "n", "i", "v", "x", "t" }) do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    out[#out + 1] = { mode = mode, lhs = m.lhs, desc = m.desc }
  end
end
local f = io.open(vim.env.CHEATSHEET_OUT, "w")
f:write(vim.json.encode(out))
f:close()
"""

MODE_NAMES = {
    "n": "Normal mode", "i": "Insert mode", "v": "Visual mode",
    "x": "Visual mode", "t": "Terminal mode",
}


def nvim():
    if not shutil.which("nvim"):
        return None
    tmp = os.path.join(CACHE, ".nvim-keymap.json")
    script = os.path.join(CACHE, ".nvim-dump.lua")
    with open(script, "w") as f:
        f.write(NVIM_LUA)

    env = dict(os.environ, CHEATSHEET_OUT=tmp)
    if run(["nvim", "--headless", "-c", "luafile " + script, "-c", "qa!"], env=env) is None:
        return None
    try:
        with open(tmp) as f:
            maps = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None
    finally:
        for p in (tmp, script):
            try:
                os.remove(p)
            except OSError:
                pass

    leader = " "  # vim.g.mapleader, shown as <leader> rather than a bare space
    buckets = {}
    for m in maps:
        desc, lhs = (m.get("desc") or "").strip(), m.get("lhs") or ""
        # A desc starting with ":" is nvim's own default-mapping boilerplate
        # (":help Y-default", ":bprevious"), and <Plug> maps are not pressable.
        if not desc or desc.startswith(":") or lhs.startswith("<Plug>"):
            continue
        if lhs.startswith(leader):
            label, keys = "Leader (space)", ["<leader>" + lhs[1:]]
        else:
            label, keys = MODE_NAMES.get(m["mode"], m["mode"]), [lhs]
        buckets.setdefault(label, []).append(bind(keys, desc))

    def order(label):
        return (0, "") if label == "Leader (space)" else (1, label)

    return {
        "id": "nvim",
        "name": "Neovim",
        "icon": "\ue62b",
        "match": ["nvim", "neovim"],
        "groups": [group(k, sorted(buckets[k], key=lambda b: b["keys"])) for k in sorted(buckets, key=order)],
    }


# --------------------------------------------------------------------------
# tmux
# --------------------------------------------------------------------------

# tmux binds are commands, not prose. The common ones get a human label; anything
# unrecognised falls back to the command itself, which is still readable.
TMUX_DESCS = {
    "split-window": "Split pane horizontally",
    "split-window -h": "Split pane vertically",
    "new-window": "New window",
    "kill-pane": "Close pane",
    "break-pane": "Move pane to its own window",
    "next-layout": "Cycle pane layout",
    "last-window": "Last window",
    "last-pane": "Last pane",
    "copy-mode": "Enter copy mode",
    "paste-buffer -p": "Paste buffer",
    "list-buffers": "List paste buffers",
    "delete-buffer": "Delete paste buffer",
    "choose-buffer -Z": "Choose paste buffer",
    "choose-tree -Zw": "Choose window",
    "choose-tree -Zs": "Choose session",
    "choose-client -Z": "Choose client",
    "detach-client": "Detach from session",
    "suspend-client": "Suspend client",
    "refresh-client": "Refresh client",
    "switch-client -p": "Previous session",
    "switch-client -n": "Next session",
    "switch-client -l": "Last session",
    "next-window": "Next window",
    "previous-window": "Previous window",
    "display-panes": "Show pane numbers",
    "display-message": "Show status message",
    "clock-mode": "Clock mode",
    "select-pane -L": "Focus pane left",
    "select-pane -D": "Focus pane down",
    "select-pane -U": "Focus pane up",
    "select-pane -R": "Focus pane right",
    "resize-pane -L 5": "Resize pane left",
    "resize-pane -D 5": "Resize pane down",
    "resize-pane -U 5": "Resize pane up",
    "resize-pane -R 5": "Resize pane right",
    "resize-pane -Z": "Zoom pane",
    "rotate-window": "Rotate panes",
    "rotate-window -D": "Rotate panes back",
    "source-file ~/.tmux.conf": "Reload tmux config",
    "command-prompt": "Command prompt",
    "next-prompt": "Next shell prompt",
    "previous-prompt": "Previous shell prompt",
}


def tmux_desc(cmd):
    if cmd in TMUX_DESCS:
        return TMUX_DESCS[cmd]
    # confirm-before -p "kill-window #W? (y/n)" kill-window  ->  the real verb
    if cmd.startswith("confirm-before"):
        tail = cmd.rsplit(" ", 1)[-1]
        return TMUX_DESCS.get(tail, tail).replace("-", " ").capitalize()
    if cmd.startswith("command-prompt"):
        for verb in ("rename-session", "rename-window", "move-window", "select-window",
                     "new-window", "swap-window", "list-keys"):
            if verb in cmd:
                return verb.replace("-", " ").capitalize() + "\u2026"
    return cmd


def tmux():
    raw = run(["tmux", "list-keys", "-T", "prefix"])
    if raw is None:
        # Not running: fall back to the committed config so the sheet still works.
        conf = os.path.expanduser("~/.tmux.conf")
        if not os.path.exists(conf):
            return None
        raw = run(["tmux", "-f", conf, "list-keys", "-T", "prefix"])
        if raw is None:
            return None

    prefix = "Ctrl+s"
    out = run(["tmux", "show-options", "-gv", "prefix"])
    if out and out.strip():
        prefix = out.strip().replace("C-", "Ctrl+")

    binds = []
    for line in raw.splitlines():
        m = re.match(r"^bind-key\s+(?:-\S+\s+)*-T\s+prefix\s+(\S+)\s+(.*)$", line.strip())
        if not m:
            continue
        key, cmd = m.group(1), m.group(2).strip()
        binds.append(bind([prefix, key.replace("\\", "")], tmux_desc(cmd)))

    if not binds:
        return None
    return {
        "id": "tmux",
        "name": "tmux",
        "icon": "\uf120",
        "match": ["tmux"],
        "groups": [group("Prefix " + prefix, sorted(binds, key=lambda b: b["keys"][-1].lower()))],
    }


# --------------------------------------------------------------------------
# kitty
# --------------------------------------------------------------------------

KITTY_PY = r"""
import json
from kitty.options.definition import definition as D
out = []
for m in D.iter_all_maps():
    if not getattr(m, "add_to_default", True):
        continue
    keys = (m.key_text or "").strip()
    if not keys or keys.startswith("cmd+") or keys.startswith("opt+"):
        continue  # macOS-only defaults
    out.append({
        "keys": keys,
        "desc": (m.short_text or m.name or "").strip(),
        "group": getattr(m.group, "title", "") or getattr(m.group, "name", "") or "Other",
    })
print(json.dumps(out))
"""


def kitty():
    raw = run(["kitty", "+runpy", KITTY_PY])
    if not raw:
        return None
    try:
        entries = json.loads(raw.strip().splitlines()[-1])
    except (json.JSONDecodeError, IndexError):
        return None

    buckets = {}
    for e in entries:
        # kitty_mod defaults to ctrl+shift and is what the docs print
        keys = e["keys"].replace("kitty_mod", "ctrl+shift").split("+")
        keys = [k.upper() if len(k) > 1 else k.upper() for k in keys]
        buckets.setdefault(e["group"], []).append(bind(keys, e["desc"]))

    return {
        "id": "kitty",
        "name": "kitty",
        "icon": "\uf489",
        "match": ["kitty"],
        "groups": [group(k, buckets[k]) for k in sorted(buckets)],
    }


# --------------------------------------------------------------------------
# zsh
# --------------------------------------------------------------------------

# Terminals send arrows and friends as escape sequences; bindkey prints the raw
# bytes, which are meaningless on a cheatsheet.
ZSH_SEQS = {
    "^[OA": "Up", "^[[A": "Up", "^[OB": "Down", "^[[B": "Down",
    "^[OC": "Right", "^[[C": "Right", "^[OD": "Left", "^[[D": "Left",
    "^[OH": "Home", "^[[H": "Home", "^[[1~": "Home", "^[[7~": "Home",
    "^[OF": "End", "^[[F": "End", "^[[4~": "End", "^[[8~": "End",
    "^[[2~": "Insert", "^[[3~": "Delete", "^[[5~": "Page Up", "^[[6~": "Page Down",
    "^[[Z": "Shift+Tab", "^I": "Tab", "^M": "Enter", "^?": "Backspace",
}


def zsh():
    raw = run(["zsh", "-i", "-c", "bindkey -L"])
    if not raw:
        return None

    def pretty(seq):
        if seq in ZSH_SEQS:
            return ZSH_SEQS[seq]
        seq = seq.replace("\\M-", "Alt+").replace("^[", "Alt+")
        return re.sub(r"\^(.)", lambda m: "Ctrl+" + m.group(1).upper(), seq)

    # One row per widget: a widget bound to both Ctrl+B and three arrow escapes is
    # one shortcut, and the plainest spelling is the one worth showing.
    def rank(key):
        if key in ZSH_SEQS.values():
            return 0
        if key.startswith("Ctrl+"):
            return 1
        return 2

    best = {}
    for line in raw.splitlines():
        m = re.match(r'^bindkey\s+"((?:[^"\\]|\\.)*)"\s+(\S+)$', line.strip())
        if not m:
            continue
        key, widget = m.group(1), m.group(2)
        # self-insert is every printable character, and the _-prefixed widgets are
        # the completion system's internals -- neither is a shortcut worth showing.
        if widget in ("self-insert", "undefined-key") or widget.startswith("_"):
            continue
        if len(key) < 2:
            continue
        nice = pretty(key)
        # Anything still carrying a bare escape prefix is an unmapped terminal
        # sequence, not something a person types.
        if re.match(r"^Alt\+[\[O]", nice):
            continue
        if widget not in best or rank(nice) < rank(best[widget]):
            best[widget] = nice

    binds = [bind([k], w.replace("-", " ")) for w, k in best.items()]
    if not binds:
        return None
    return {
        "id": "zsh",
        "name": "zsh",
        "icon": "\ue795",
        "match": ["zsh"],
        "groups": [group("Line editing", sorted(binds, key=lambda b: b["desc"]))],
    }


# --------------------------------------------------------------------------

COLLECTORS = (hyprland, nvim, tmux, kitty, zsh)


def main():
    os.makedirs(CACHE, exist_ok=True)
    apps, failed = [], []
    for fn in COLLECTORS:
        try:
            app = fn()
        except Exception as e:  # one broken source must not lose the other four
            print(f"cheatsheet: {fn.__name__} failed: {e}", file=sys.stderr)
            app = None
        if app and app["groups"]:
            apps.append(app)
        else:
            failed.append(fn.__name__)

    data = {
        "generated": datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds"),
        "apps": apps,
    }
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f, indent=1)
    os.replace(tmp, OUT)  # atomic, so the overlay never reads a half-written file

    total = sum(len(g["binds"]) for a in apps for g in a["groups"])
    print(f"cheatsheet: {total} binds from {len(apps)} apps -> {OUT}")
    if failed:
        print(f"cheatsheet: no binds from {', '.join(failed)}", file=sys.stderr)


if __name__ == "__main__":
    main()
