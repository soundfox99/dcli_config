#!/usr/bin/env bash
# Install latest stable Node via fnm and set it as the user default.
# Idempotent: skips installs already present, leaves existing default alone if
# it's the current LTS or 'latest'.

set -euo pipefail

if ! command -v fnm >/dev/null 2>&1; then
    echo "fnm not on PATH — skipping. Re-run after fnm is installed." >&2
    exit 0
fi

# fnm needs its env loaded to know about the user's install dir; .bashrc sets
# this up for interactive shells but this hook runs non-interactively.
eval "$(fnm env --shell bash)"

# Resolve the latest stable Node version (fnm has no built-in 'latest' alias).
latest_stable() {
    fnm list-remote --lts=false 2>/dev/null \
        | awk '/^v[0-9]+/{print $1}' \
        | tail -n1
}

ensure_lts() {
    if fnm list 2>/dev/null | grep -q 'lts'; then
        echo "An LTS Node is already installed."
    else
        fnm install --lts
    fi
}

ensure_version() {
    local version="$1"
    if [ -z "${version}" ]; then
        echo "Could not resolve a Node version to install — skipping."
        return 0
    fi
    if fnm list 2>/dev/null | grep -q "${version}"; then
        echo "Node ${version} already installed."
    else
        fnm install "${version}"
    fi
}

ensure_lts
LATEST="$(latest_stable)"
ensure_version "${LATEST}"

# Pin default to the latest stable if no default is configured yet.
if [ -n "${LATEST}" ] && ! fnm default 2>/dev/null | grep -q '^v'; then
    fnm default "${LATEST}"
    echo "Set fnm default to ${LATEST}."
fi
