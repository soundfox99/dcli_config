#!/usr/bin/env bash
# Interactive onboarding — runs every `dcli sync` but each step exits silently
# when its work is already done. Prompts only when something's actually missing.
#
# Runs as the invoking user (run_hooks_as_user = true on the module).

set -euo pipefail

REPO_ROOT="$(git -C "$(dirname "$0")/../../.." rev-parse --show-toplevel 2>/dev/null || pwd)"

prompt_yes() {
    local q="$1"
    local ans
    read -rp "${q} [Y/n] " ans </dev/tty
    [[ -z "${ans}" || "${ans}" =~ ^[Yy] ]]
}

# ─── 1. SSH key for git remotes ─────────────────────────────────────────────
# Probe live SSH auth against github.com and gitlab.com. Either succeeding is
# proof that a key exists AND is registered on a forge. Only generate/prompt
# when neither host accepts our key.

git_ssh_works() {
    local host="$1"
    local out
    out=$(ssh -T \
        -o StrictHostKeyChecking=accept-new \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        "git@${host}" 2>&1) || true
    [[ "${out}" == *"successfully authenticated"* ]] \
        || [[ "${out}" == *"Welcome to GitLab"* ]]
}

if git_ssh_works github.com || git_ssh_works gitlab.com; then
    : # SSH already wired up to at least one forge — nothing to do
else
    echo
    echo "[onboarding] No working git SSH key (github.com + gitlab.com both rejected auth)."

    if [ -f "${HOME}/.ssh/id_ed25519.pub" ] || [ -f "${HOME}/.ssh/id_rsa.pub" ]; then
        echo "  An SSH key exists locally but isn't registered with any forge."
        pubkey="${HOME}/.ssh/id_ed25519.pub"
        [ -f "${pubkey}" ] || pubkey="${HOME}/.ssh/id_rsa.pub"
        echo "  Public key — add it on GitHub / GitLab → Settings → SSH keys:"
        echo "  ─────────────────────────────────────────────────────────────"
        cat "${pubkey}"
        echo "  ─────────────────────────────────────────────────────────────"
        read -rp "  Press Enter once the key is added on the remote host... " _ </dev/tty
    elif prompt_yes "Generate an ed25519 keypair now?"; then
        mkdir -p "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh"
        read -rp "  Email for key comment (e.g. github noreply addr): " email </dev/tty
        ssh-keygen -t ed25519 -C "${email}" -f "${HOME}/.ssh/id_ed25519" -N ""
        echo
        echo "  Public key — add this on GitHub / GitLab → Settings → SSH keys:"
        echo "  ─────────────────────────────────────────────────────────────"
        cat "${HOME}/.ssh/id_ed25519.pub"
        echo "  ─────────────────────────────────────────────────────────────"
        read -rp "  Press Enter once the key is added on the remote host... " _ </dev/tty
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

# ─── 3. Docker group membership ─────────────────────────────────────────────
if getent group docker >/dev/null 2>&1 && ! id -nG "${USER}" | tr ' ' '\n' | grep -qx docker; then
    echo
    echo "[onboarding] Your user is not in the 'docker' group; sudo is required for docker."
    if prompt_yes "Add ${USER} to the docker group (needs sudo)?"; then
        sudo usermod -aG docker "${USER}"
        echo "  Added. Log out and back in (or 'newgrp docker') for the change to take effect."
    fi
fi

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

# ─── 5. GTK theme + cursor ──────────────────────────────────────────────────
# Apply Catppuccin Mocha + Bibata if the packages are installed (theming module).
# Idempotent: gsettings is a no-op when the value already matches.
if command -v gsettings >/dev/null 2>&1; then
    declare -A theme_targets=(
        ["gtk-theme"]="Catppuccin-Mocha-Standard-Mauve-Dark"
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
bookmark_marker="${HOME}/.local/state/arch-config/onboarding-bookmarks-shown"
if [ ! -f "${bookmark_marker}" ] && [ -d "${REPO_ROOT}/browser-bookmarks" ] \
    && [ -s "${REPO_ROOT}/browser-bookmarks/firefox.html" ]; then
    # Skip if files are still ciphertext (git-crypt locked)
    if ! head -c 9 "${REPO_ROOT}/browser-bookmarks/firefox.html" | grep -q GITCRYPT; then
        echo
        echo "[onboarding] Your bookmarks are decrypted at:"
        echo "  ${REPO_ROOT}/browser-bookmarks/{firefox,chromium,brave}.html"
        echo "  Import via each browser: Bookmarks → Manage → Import HTML."
        mkdir -p "$(dirname "${bookmark_marker}")"
        touch "${bookmark_marker}"
    fi
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
