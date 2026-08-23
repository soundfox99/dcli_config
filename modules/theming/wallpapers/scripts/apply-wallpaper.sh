#!/usr/bin/env bash
# Point every desktop on this machine at the one wallpaper named in
# data/wallpaper, so all hosts sharing this repo show the same image.
#
# Two desktops to satisfy, and they store the choice in completely different
# places:
#
#   KDE Plasma  — plasma-apply-wallpaperimage, over the session D-Bus. Needs a
#                 live plasmashell; there is no supported offline equivalent
#                 (the config lives under per-containment IDs in
#                 plasma-org.kde.plasma.desktop-appletsrc and hand-editing it
#                 breaks as soon as a containment is added).
#   niri        — noctalia-shell, which keys wallpapers by *output name* in
#                 ~/.cache/noctalia/wallpapers.json. Output names differ per
#                 machine (eDP-1 on the laptop, DP-n on the desktop), so that
#                 file cannot simply be tracked in the repo and copied around.
#                 "defaultWallpaper" is the machine-independent key and is what
#                 an unseen output falls back to — that's the one that makes
#                 this work across hosts.
#
# Nothing here is fatal: a sync run from a TTY, or from the other DE's session,
# should still exit 0. Whichever half can't be reached now gets picked up the
# next time you sync from inside that session.
#
# Called at the end of install-wallpapers.sh rather than being its own module
# hook — dcli allows one post_install_hook per module, and the image has to be
# on disk before anything can point at it.

set -euo pipefail

# Same de-escalation dance as install-wallpapers.sh: this touches $HOME and the
# user's session bus, so it must not run as root.
if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "apply-wallpaper.sh refuses to run as root and SUDO_USER is unset." >&2
        exit 1
    fi
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
choice_file="${script_dir}/../data/wallpaper"
walls_dir="${HOME}/Pictures/Wallpapers"
cache="${HOME}/.cache/noctalia/wallpapers.json"

if [ ! -f "${choice_file}" ]; then
    echo "no data/wallpaper — nothing to apply" >&2
    exit 0
fi

# First non-blank, non-comment line.
rel="$(grep -vE '^\s*(#|$)' "${choice_file}" | head -n1 || true)"
if [ -z "${rel}" ]; then
    echo "data/wallpaper names no image — skipping"
    exit 0
fi

wallpaper="${walls_dir}/${rel}"
if [ ! -f "${wallpaper}" ]; then
    echo "wallpaper not found: ${wallpaper}" >&2
    echo "  (collection incomplete, or the path in data/wallpaper is stale)" >&2
    exit 0
fi

echo "wallpaper: ${rel}"

# ── KDE Plasma ─────────────────────────────────────────────────────────────
if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    if pgrep -x plasmashell >/dev/null 2>&1; then
        if plasma-apply-wallpaperimage "${wallpaper}" >/dev/null 2>&1; then
            echo "  plasma: applied"
        else
            echo "  plasma: plasma-apply-wallpaperimage failed — skipping" >&2
        fi
    else
        echo "  plasma: plasmashell not running — skipping (re-sync from a Plasma session)"
    fi
fi

# ── niri / noctalia-shell ──────────────────────────────────────────────────
# If the shell is live, IPC repaints immediately. This is only half the job:
# IPC sets the entry for the current output and leaves "defaultWallpaper"
# pointing at noctalia's stock asset, and defaultWallpaper is precisely the key
# a host with different output names inherits. So the cache write below runs
# either way, and runs *after* the IPC call so it wins the file.
if command -v qs >/dev/null 2>&1 && pgrep -f 'qs .*noctalia-shell' >/dev/null 2>&1; then
    if qs -c noctalia-shell ipc call wallpaper set "${wallpaper}" "" >/dev/null 2>&1; then
        echo "  noctalia: applied over IPC"
    fi
fi

# Sets defaultWallpaper — what any output this machine hasn't seen before falls
# back to — plus every output already recorded, in both light and dark slots.
mkdir -p "$(dirname "${cache}")"
if WALLPAPER="${wallpaper}" CACHE="${cache}" python3 - <<'PY'
import json, os, tempfile

path = os.environ["WALLPAPER"]
cache = os.environ["CACHE"]

try:
    with open(cache) as fh:
        data = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data["defaultWallpaper"] = path
for name, entry in (data.get("wallpapers") or {}).items():
    if isinstance(entry, dict):
        for mode in ("dark", "light"):
            if mode in entry:
                entry[mode] = path

# Atomic replace: noctalia reads this at startup and a half-written file would
# leave it with no wallpaper at all.
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(cache))
with os.fdopen(fd, "w") as fh:
    json.dump(data, fh, indent=4)
    fh.write("\n")
os.replace(tmp, cache)
PY
then
    echo "  noctalia: cache updated (default + every known output)"
else
    echo "  noctalia: could not update ${cache} — skipping" >&2
fi
