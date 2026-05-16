#!/usr/bin/env bash
# Set up rustup's default toolchain + rust-analyzer component if not yet
# configured. Idempotent: skips work that's already done.

set -euo pipefail

# De-escalate if running as root in a sudo context — rustup writes to ~/.rustup
# and ~/.cargo, so it must be the desktop user's home, not root's.
if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "rustup-default.sh refuses to run as root and SUDO_USER is unset." >&2
        exit 1
    fi
fi

if ! command -v rustup >/dev/null; then
    echo "rustup not installed yet — skipping." >&2
    exit 0
fi

# Arch's pacman rustup doesn't ship ~/.cargo/env (only rustup-init.sh does).
# Write the standard template so .bashrc / .zshrc and other tools that
# `source $HOME/.cargo/env` work uniformly.
if [ ! -f "${HOME}/.cargo/env" ]; then
    mkdir -p "${HOME}/.cargo"
    cat > "${HOME}/.cargo/env" <<'EOF'
#!/bin/sh
# rustup shell setup; modify path for the cargo binaries
case ":${PATH}:" in
    *:"$HOME/.cargo/bin":*) ;;
    *) export PATH="$HOME/.cargo/bin:$PATH" ;;
esac
EOF
    chmod 644 "${HOME}/.cargo/env"
fi

if rustup default 2>/dev/null | grep -q '^stable'; then
    echo "rustup default toolchain already set."
else
    rustup default stable
fi

if rustup component list --installed 2>/dev/null | grep -q '^rust-analyzer'; then
    echo "rust-analyzer component already installed."
else
    rustup component add rust-analyzer
fi

if rustup component list --installed 2>/dev/null | grep -q '^rust-src'; then
    echo "rust-src component already installed."
else
    rustup component add rust-src
fi

# Cargo binaries installed via cargo-binstall (prebuilt; falls back to source).
# Add more crates to this list as you adopt them.
CARGO_BINS=(
    cargo-audit
)

if command -v cargo-binstall >/dev/null 2>&1; then
    for crate in "${CARGO_BINS[@]}"; do
        if cargo install --list 2>/dev/null | grep -q "^${crate} "; then
            echo "${crate} already installed."
        else
            cargo binstall --no-confirm "${crate}"
        fi
    done
else
    echo "cargo-binstall not available — skipping cargo crate installs."
fi
