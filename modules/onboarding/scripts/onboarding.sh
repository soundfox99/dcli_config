#!/usr/bin/env bash
# Interactive onboarding — runs every `dcli sync` but each step exits silently
# when its work is already done. Prompts only when something's actually missing.
#
# Runs as the invoking user (run_hooks_as_user = true on the module).

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")/../../.." rev-parse --show-toplevel 2>/dev/null || pwd)"

# ─── Configuration ──────────────────────────────────────────────────────────
# data/onboarding.conf is sourced as bash and is tracked in git, so whatever it
# sets reproduces on a fresh clone. It is optional; the defaults below apply
# when it is absent.
CONFIG_FILE="$(cd "$(dirname "$0")/.." && pwd)/data/onboarding.conf"
if [ -f "${CONFIG_FILE}" ]; then
    # shellcheck source=/dev/null
    . "${CONFIG_FILE}"
fi

# Git forges probed in step 1, space separated. Precedence:
#   DCLI_ONBOARDING_GIT_FORGES (env, one-off)  >  data/onboarding.conf  >  default
# Use ${VAR-default}, never ${VAR:-default}: the unset-vs-empty distinction is
# load-bearing here, since an explicitly empty list means "skip step 1
# entirely", not "fall back to the default".
GIT_FORGES="${DCLI_ONBOARDING_GIT_FORGES-${GIT_FORGES-github.com gitlab.com}}"

prompt_yes() {
    local q="$1"
    local ans
    read -rp "${q} [Y/n] " ans </dev/tty
    [[ -z "${ans}" || "${ans}" =~ ^[Yy] ]]
}

# ─── 1. SSH key for git remotes ─────────────────────────────────────────────
# Probe live SSH auth against each forge in GIT_FORGES. Any one of them
# accepting the key is proof that a key exists AND is registered on a forge,
# which is all this step needs — so a forge you don't use buys nothing and
# costs a network round trip per sync. Drop it from GIT_FORGES and onboarding
# stops contacting it at all. An empty GIT_FORGES skips this step outright.

git_ssh_works() {
    local host="$1"
    local out
    out=$(ssh -T \
        -o StrictHostKeyChecking=accept-new \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        "git@${host}" 2>&1) || true
    # Both matchers stay regardless of which forges are configured: they key off
    # the greeting the far end sends, so they also cover self-hosted instances.
    [[ "${out}" == *"successfully authenticated"* ]] \
        || [[ "${out}" == *"Welcome to GitLab"* ]]
}

read -ra git_forges <<< "${GIT_FORGES}"

if [ ${#git_forges[@]} -eq 0 ]; then
    : # GIT_FORGES is empty — SSH key setup opted out entirely
else
    # "github.com" / "github.com / gitlab.com" — for the prompts below.
    forge_label="$(printf '%s / ' "${git_forges[@]}")"
    forge_label="${forge_label% / }"

    ssh_authenticated=false
    for forge in "${git_forges[@]}"; do
        if git_ssh_works "${forge}"; then
            ssh_authenticated=true
            break
        fi
    done

    if [ "${ssh_authenticated}" = true ]; then
        : # SSH already wired up to at least one forge — nothing to do
    else
        echo
        echo "[onboarding] No working git SSH key (${forge_label} rejected auth)."

        if [ -f "${HOME}/.ssh/id_ed25519.pub" ] || [ -f "${HOME}/.ssh/id_rsa.pub" ]; then
            echo "  An SSH key exists locally but isn't registered with any forge."
            pubkey="${HOME}/.ssh/id_ed25519.pub"
            [ -f "${pubkey}" ] || pubkey="${HOME}/.ssh/id_rsa.pub"
            echo "  Public key — add it on ${forge_label} → Settings → SSH keys:"
            echo "  ─────────────────────────────────────────────────────────────"
            cat "${pubkey}"
            echo "  ─────────────────────────────────────────────────────────────"
            read -rp "  Press Enter once the key is added on the remote host... " _ </dev/tty
        elif prompt_yes "Generate an ed25519 keypair now?"; then
            mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
            read -rp "  Email for key comment (e.g. github noreply addr): " email </dev/tty
            ssh-keygen -t ed25519 -C "${email}" -f "${HOME}/.ssh/id_ed25519" -N ""
            echo
            echo "  Public key — add this on ${forge_label} → Settings → SSH keys:"
            echo "  ─────────────────────────────────────────────────────────────"
            cat "${HOME}/.ssh/id_ed25519.pub"
            echo "  ─────────────────────────────────────────────────────────────"
            read -rp "  Press Enter once the key is added on the remote host... " _ </dev/tty
        fi
    fi
fi

# ─── 2. git-crypt unlock (only if repo has encrypted files but isn't unlocked) ─
if [ -d "${REPO_ROOT}/.git" ] \
    && grep -q 'filter=git-crypt' "${REPO_ROOT}/.gitattributes" 2>/dev/null \
    && [ ! -f "${REPO_ROOT}/.git/git-crypt/keys/default" ]; then
    echo
    echo "[onboarding] This repo has git-crypt-encrypted files but isn't unlocked."
    read -rp "  Path to your git-crypt key file (e.g. ~/arch-dcli-config.key, or 'skip'): " keypath </dev/tty
    keypath="${keypath/#\~/${HOME}}"
    if [ "${keypath}" = "skip" ] || [ -z "${keypath}" ]; then
        echo "  Skipping — encrypted files will stay as ciphertext until you run:"
        echo "    git-crypt unlock /path/to/key"
    elif [ -f "${keypath}" ]; then
        ( cd "${REPO_ROOT}" && git-crypt unlock "${keypath}" )
        echo "  Repo unlocked."
    else
        echo "  No file at ${keypath} — skipping. Re-run sync after providing it."
    fi
fi

# ─── 3. Group memberships (docker, libvirt) ─────────────────────────────────
for group in docker libvirt; do
    if getent group "${group}" >/dev/null 2>&1 \
        && ! id -nG "${USER}" | tr ' ' '\n' | grep -qx "${group}"; then
        echo
        echo "[onboarding] Your user is not in the '${group}' group."
        if prompt_yes "Add ${USER} to the ${group} group (needs sudo)?"; then
            sudo usermod -aG "${group}" "${USER}"
            echo "  Added. Log out and back in (or 'newgrp ${group}') for the change to take effect."
        fi
    fi
done

# ─── 4. Default login shell ─────────────────────────────────────────────────
if [ "$(getent passwd "${USER}" | cut -d: -f7)" != "/bin/bash" ] && [ -x /bin/bash ]; then
    echo
    echo "[onboarding] Your login shell is $(getent passwd "${USER}" | cut -d: -f7), but the repo's"
    echo "  .bashrc (cargo env, fnm shim, starship) only runs in bash."
    if prompt_yes "Change login shell to /bin/bash?"; then
        chsh -s /bin/bash
        echo "  Login shell changed. Log out + back in to pick it up."
    fi
fi

# ─── 5. Theme switcher — apply the active palette (kitty + starship + GTK) ──
# scripts/switch-theme.sh handles the per-app routing; the active theme is
# recorded in modules/theming/active-theme.txt. Cursor + icon themes are still
# set here since they're not part of the switchable palette.
if [ -x "${REPO_ROOT}/scripts/switch-theme.sh" ]; then
    "${REPO_ROOT}/scripts/switch-theme.sh" || true
fi
if command -v gsettings >/dev/null 2>&1; then
    declare -A theme_targets=(
        ["cursor-theme"]="Bibata-Modern-Ice"
        ["icon-theme"]="Adwaita"
    )
    for key in "${!theme_targets[@]}"; do
        current=$(gsettings get org.gnome.desktop.interface "${key}" 2>/dev/null | tr -d "'")
        target="${theme_targets[${key}]}"
        if [ "${current}" != "${target}" ]; then
            gsettings set org.gnome.desktop.interface "${key}" "${target}" 2>/dev/null \
                && echo "[onboarding] gsettings: ${key} → ${target}"
        fi
    done
fi

# ─── 6. Bookmark location nudge ─────────────────────────────────────────────
# Reliable cross-browser auto-import is nontrivial (each browser uses its own
# proprietary store). We just point users at the html files; they import via
# the browser's own UI on first launch.
bookmark_dir="${REPO_ROOT}/modules/browsers/data"
import_script="${REPO_ROOT}/modules/browsers/scripts/import-browser-bookmarks.sh"

# 6a. Chromium / Brave: auto-import (safe mode — only when profile is empty)
if [ -x "${import_script}" ]; then
    echo
    echo "[onboarding] Importing Chromium/Brave bookmarks (auto mode)..."
    "${import_script}" || true
fi

# 6b. Firefox: still a manual step (no clean auto-import from HTML)
firefox_marker="${HOME}/.local/state/arch-config/onboarding-firefox-bookmarks-shown"
if [ ! -f "${firefox_marker}" ] \
    && [ -s "${bookmark_dir}/firefox-bookmarks.html" ] \
    && ! head -c 9 "${bookmark_dir}/firefox-bookmarks.html" | grep -q GITCRYPT; then
    echo
    echo "[onboarding] Firefox bookmarks: import manually via"
    echo "  Bookmarks → Manage Bookmarks → Import HTML from"
    echo "  ${bookmark_dir}/firefox-bookmarks.html"
    mkdir -p "$(dirname "${firefox_marker}")"
    touch "${firefox_marker}"
fi

# ─── 7. Timeshift first-run check ───────────────────────────────────────────
if command -v timeshift >/dev/null 2>&1 && [ ! -f /etc/timeshift/timeshift.json ]; then
    echo
    echo "[onboarding] Timeshift is installed but never configured."
    echo "  dcli's system_backups won't work until you run:"
    echo "    sudo timeshift-launcher    # GUI wizard"
    echo "    # or, headless:"
    echo "    sudo timeshift --create --comments 'initial' --tags D"
fi

exit 0
