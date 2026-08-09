#!/usr/bin/env bash
# Merge the keyboard-shortcut overrides in modules/browsers/zen/data into every
# Zen profile. Reads data/keyboard-shortcuts.json; ids under "bind" get the
# given chord, ids under "retire" are unbound and disabled. Idempotent:
# re-running reapplies the same result, and dropping an id from the data file
# leaves whatever Zen ships as the default for it.
#
# Must run as the desktop user (Zen profiles live under ~/.config/zen and are
# user-owned). If dcli's run_hooks_as_user couldn't de-escalate (sudo context),
# re-exec ourselves as ${SUDO_USER}. This has to happen before ZEN_ROOT is
# expanded, or $HOME would still be root's.
#
# Zen rewrites zen-keyboard-shortcuts.json from memory on change and on exit,
# so editing it while the browser is running loses the change. This script
# refuses to touch a profile while Zen is up.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        # -H resets HOME to the target user's home; --preserve-env=PATH keeps the parent PATH
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "install-zen-shortcuts.sh refuses to run as root and SUDO_USER is unset." >&2
        echo "Re-run dcli sync from a non-root shell." >&2
        exit 1
    fi
fi

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_FILE="${MODULE_ROOT}/data/keyboard-shortcuts.json"
ZEN_ROOT="${HOME}/.config/zen"

[ -f "${DATA_FILE}" ] || { echo "missing ${DATA_FILE}" >&2; exit 1; }

if pgrep -x zen-bin >/dev/null 2>&1 || pgrep -x zen >/dev/null 2>&1; then
    echo "Zen is running — close it and re-run, or the change will be overwritten." >&2
    exit 1
fi

if [ ! -d "${ZEN_ROOT}" ]; then
    # Zen has never been launched, so there is no profile to write into yet.
    echo "no Zen profile yet (${ZEN_ROOT} absent) — skipping"
    exit 0
fi

shopt -s nullglob
targets=("${ZEN_ROOT}"/*/zen-keyboard-shortcuts.json)
shopt -u nullglob

if [ ${#targets[@]} -eq 0 ]; then
    echo "no zen-keyboard-shortcuts.json under ${ZEN_ROOT} — skipping"
    exit 0
fi

for target in "${targets[@]}"; do
    DATA_FILE="${DATA_FILE}" TARGET="${target}" python3 - <<'PY'
import json
import os
import shutil
import sys

data_file = os.environ["DATA_FILE"]
target = os.environ["TARGET"]

with open(data_file) as f:
    spec = json.load(f)
bind = spec.get("bind", {})
retire = spec.get("retire", {})

with open(target) as f:
    doc = json.load(f)
shortcuts = doc.get("shortcuts")
if not isinstance(shortcuts, list):
    sys.exit(f"{target}: no shortcuts array")
by_id = {s.get("id"): s for s in shortcuts}

NO_MODS = {"control": False, "alt": False, "shift": False,
           "meta": False, "accel": False}


def parse(chord):
    """'Ctrl+Alt+1' -> (key, keycode, modifiers). Ctrl maps to accel."""
    parts = chord.split("+")
    key_token, mod_tokens = parts[-1], parts[:-1]
    mods = dict(NO_MODS)
    for t in mod_tokens:
        t = t.strip().lower()
        if t in ("ctrl", "control"):
            mods["accel"] = True
        elif t in ("alt", "opt", "option"):
            mods["alt"] = True
        elif t == "shift":
            mods["shift"] = True
        elif t in ("super", "meta", "cmd"):
            mods["meta"] = True
        else:
            sys.exit(f"{chord}: unknown modifier {t!r}")
    key_token = key_token.strip()
    if key_token.startswith("VK_"):
        return "", key_token, mods
    return key_token.lower(), "", mods


def chord_of(s):
    m = s.get("modifiers", {})
    active = tuple(n for n in ("accel", "control", "alt", "shift", "meta")
                   if m.get(n))
    k = s.get("key") or s.get("keycode") or ""
    return (active, str(k).lower()) if k else None


missing = [i for i in list(bind) + list(retire) if i not in by_id]
if missing:
    sys.exit(f"{target}: ids absent from this Zen version: {missing}")

for sid, chord in bind.items():
    key, keycode, mods = parse(chord)
    s = by_id[sid]
    s["key"] = key
    s["keycode"] = keycode
    s["modifiers"] = mods
    s["disabled"] = False

for sid in retire:
    s = by_id[sid]
    s["key"] = ""
    s["keycode"] = ""
    s["modifiers"] = dict(NO_MODS)
    s["disabled"] = True

# Refuse to write a table where an override collides with something else.
# Conflicts Zen ships between its own defaults are reported, not fatal.
seen, conflicts = {}, []
for s in shortcuts:
    if s.get("disabled"):
        continue
    c = chord_of(s)
    if c is None:
        continue
    if c in seen:
        conflicts.append((c, seen[c], s.get("id")))
    else:
        seen[c] = s.get("id")

ours = [c for c in conflicts if c[1] in bind or c[2] in bind]
if ours:
    for c, a, b in ours:
        print(f"  CONFLICT {'+'.join(c[0])}+{c[1]}: {a} vs {b}", file=sys.stderr)
    sys.exit(f"{target}: overrides collide — nothing written")
for c, a, b in conflicts:
    print(f"  note: Zen default conflict left alone: "
          f"{'+'.join(c[0])}+{c[1]}: {a} vs {b}")

shutil.copy2(target, target + ".bak")
with open(target, "w") as f:
    json.dump(doc, f, indent=2)

profile = os.path.basename(os.path.dirname(target))
print(f"  {profile}: {len(bind)} bound, {len(retire)} retired")
PY
done

echo "Zen shortcuts deployed to ${#targets[@]} profile(s)."
