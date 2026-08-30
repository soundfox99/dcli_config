#!/usr/bin/env bash
# Install the per-user half of the supernote module:
#   - supernotelib (provides supernote-tool) into a uv-managed venv
#   - the .note -> .md converter into ~/.local/bin
#   - enable the systemd user units deployed by dotfiles_sync
#
# pacman handles languagetool and android-file-transfer; everything here is
# user-scoped, so none of it belongs in a system package. Idempotent — safe
# under hook_behavior = "always".
#
# Must run as the desktop user. If dcli's run_hooks_as_user couldn't
# de-escalate (sudo context), re-exec ourselves as ${SUDO_USER}.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        # -H resets HOME to the target user's home; --preserve-env=PATH keeps the parent PATH
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "install-supernote-tooling.sh refuses to run as root and SUDO_USER is unset." >&2
        echo "Re-run dcli sync from a non-root shell." >&2
        exit 1
    fi
fi

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
export PATH="${BIN_DIR}:${PATH}"

mkdir -p "${BIN_DIR}"

# --- systemd --user needs a session bus ---------------------------------------
# sudo -u does NOT set these, so systemctl --user fails with
#   "Failed to connect to user scope bus ... $DBUS_SESSION_BUS_ADDRESS and
#    $XDG_RUNTIME_DIR not defined"
# Reconstruct them from the target user's uid.
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
: "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR}/bus}"
export XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS

# The bus only exists while the user has a live login session. Under a sync run
# from a tty with no seat, or in a chroot, it legitimately will not — that is
# not a failure worth aborting the whole sync for.
user_bus_available() {
    [ -S "${XDG_RUNTIME_DIR}/bus" ] && systemctl --user show-environment >/dev/null 2>&1
}

# --- supernotelib -------------------------------------------------------------
# Deliberately uv, not pacman: supernotelib is not packaged for Arch, and a uv
# tool venv keeps it off the system python.
if ! command -v uv >/dev/null 2>&1; then
    echo "  uv not found — enable programming-languages/python before this module." >&2
    exit 1
fi

if command -v supernote-tool >/dev/null 2>&1; then
    echo "  supernote-tool already present ($(command -v supernote-tool))"
else
    echo "  installing supernotelib via uv..."
    uv tool install supernotelib
fi

# --- converter ----------------------------------------------------------------
install -Dm755 "${MODULE_ROOT}/data/supernote-note2md" "${BIN_DIR}/supernote-note2md"
echo "  installed ${BIN_DIR}/supernote-note2md"

# --- systemd user units -------------------------------------------------------
# Installed here rather than via dotfiles_sync: dcli symlinks whole directories,
# so shipping these as dotfiles/systemd/ would make ~/.config/systemd a symlink
# into this module — handing one module the entire user-unit namespace and
# committing `systemctl --user enable` state (absolute-path .wants symlinks)
# straight into git. Plain files, copied.
install -Dm644 "${MODULE_ROOT}/data/systemd-user/supernote-note2md.service" \
    "${HOME}/.config/systemd/user/supernote-note2md.service"
install -Dm644 "${MODULE_ROOT}/data/systemd-user/supernote-note2md.timer" \
    "${HOME}/.config/systemd/user/supernote-note2md.timer"
install -Dm644 "${MODULE_ROOT}/data/systemd-user/languagetool.service" \
    "${HOME}/.config/systemd/user/languagetool.service"
echo "  installed 3 systemd user units"

if ! user_bus_available; then
    echo "  no user session bus at ${XDG_RUNTIME_DIR}/bus — skipping unit activation."
    echo "  Run this once from a graphical/login session:"
    echo "    systemctl --user daemon-reload"
    echo "    systemctl --user enable --now supernote-note2md.timer"
    echo "    systemctl --user enable --now languagetool.service"
    exit 0
fi

systemctl --user daemon-reload

if systemctl --user enable --now supernote-note2md.timer 2>/dev/null; then
    echo "  enabled supernote-note2md.timer"
else
    echo "  WARNING: could not enable supernote-note2md.timer" >&2
fi

# LanguageTool is only useful once the package landed. Enabling a unit whose
# ExecStart is missing would just crashloop, so gate on the binary.
# NB: the Arch package ships ONE wrapper, /usr/bin/languagetool, which selects
# the HTTP server via --http. There is no languagetool-server binary.
if [ -x /usr/bin/languagetool ]; then
    if systemctl --user enable --now languagetool.service 2>/dev/null; then
        echo "  enabled languagetool.service (http://localhost:8081)"
    else
        echo "  WARNING: could not enable languagetool.service" >&2
    fi
else
    echo "  languagetool-server not found — skipping languagetool.service."
    echo "  (pacman installs it; re-run this hook after the package lands.)"
fi
