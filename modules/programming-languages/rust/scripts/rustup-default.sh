#!/usr/bin/env bash
# Set up rustup's default toolchain + rust-analyzer component if not yet
# configured. Idempotent: skips work that's already done.

set -euo pipefail

if ! command -v rustup >/dev/null; then
    echo "rustup not installed yet — skipping." >&2
    exit 0
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
