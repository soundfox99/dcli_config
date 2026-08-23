#!/usr/bin/env bash
#
#   ┌──────────────────────────────────────────────────────────────────────┐
#   │  TO CHANGE THE WALLPAPER: edit the one line below, then push.        │
#   │  Every host picks it up on its next `dcli sync`. Nothing else in     │
#   │  the repo records a wallpaper choice.                                │
#   └──────────────────────────────────────────────────────────────────────┘

# Path relative to ~/Pictures/Wallpapers (the dharmx/walls tree).
WALLPAPER="digital/a_car_on_a_road_with_purple_clouds_in_the_sky.png"

# ───────────────────────────────────────────────────────────────────────────
# Below here is just the plumbing.
#
# Runs standalone (`./apply-wallpaper.sh`) and from the tail of
# install-wallpapers.sh, so a sync applies it too.
#
# Plasma and niri store the choice in completely different places, so both get
# handled. Neither is fatal — running this from a TTY, or from the other DE's
# session, skips whatever it can't reach and exits 0.

set -euo pipefail

# Touches $HOME and the user's session bus, so it must not run as root. dcli's
# run_hooks_as_user usually handles this; re-exec if it didn't.
if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "apply-wallpaper.sh refuses to run as root and SUDO_USER is unset." >&2
        exit 1
    fi
fi

cache="${HOME}/.cache/noctalia/wallpapers.json"
image="${HOME}/Pictures/Wallpapers/${WALLPAPER}"

if [ ! -f "${image}" ]; then
    echo "wallpaper not found: ${image}" >&2
    echo "  (collection not downloaded yet, or WALLPAPER above is stale)" >&2
    exit 0
fi

echo "wallpaper: ${WALLPAPER}"

# ── KDE Plasma ─────────────────────────────────────────────────────────────
# Goes over the session D-Bus, so it needs a live plasmashell. There's no
# supported offline equivalent — the setting lives under per-containment IDs in
# plasma-org.kde.plasma.desktop-appletsrc, and hand-editing that breaks as soon
# as a containment is added.
if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        echo "  plasma: plasmashell not running — skipping (re-run from a Plasma session)"
    elif plasma-apply-wallpaperimage "${image}" >/dev/null 2>&1; then
        echo "  plasma: applied"
    else
        echo "  plasma: plasma-apply-wallpaperimage failed — skipping" >&2
    fi
fi

# ── niri / noctalia-shell ──────────────────────────────────────────────────
# IPC repaints immediately when the shell is live, but only for the current
# output — it leaves "defaultWallpaper" on noctalia's stock asset. Since
# noctalia keys wallpapers by output name (eDP-1 here, DP-n on the desktop),
# defaultWallpaper is the only machine-independent key, and a fresh host with
# unfamiliar output names inherits it. So the cache write always runs, and runs
# after the IPC call so it wins the file.
if command -v qs >/dev/null 2>&1 && pgrep -f 'qs .*noctalia-shell' >/dev/null 2>&1; then
    if qs -c noctalia-shell ipc call wallpaper set "${image}" "" >/dev/null 2>&1; then
        echo "  noctalia: applied over IPC"
    fi
fi

mkdir -p "$(dirname "${cache}")"
if IMAGE="${image}" CACHE="${cache}" python3 - <<'PY'
import json, os, tempfile

image = os.environ["IMAGE"]
cache = os.environ["CACHE"]

try:
    with open(cache) as fh:
        data = json.load(fh)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data["defaultWallpaper"] = image
for entry in (data.get("wallpapers") or {}).values():
    if isinstance(entry, dict):
        for mode in ("dark", "light"):
            if mode in entry:
                entry[mode] = image

# Atomic replace: noctalia reads this at startup, and a half-written file would
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
