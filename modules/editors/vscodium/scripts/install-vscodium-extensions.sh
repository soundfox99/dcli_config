#!/usr/bin/env bash
# Install VSCodium extensions listed in data/extensions.txt (one ID per line,
# blank lines + # comments ignored). Idempotent: --install-extension --force
# is a no-op at the same version.
#
# Must run as the desktop user. If dcli's run_hooks_as_user couldn't
# de-escalate (sudo context), re-exec ourselves as ${SUDO_USER}.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        # -H resets HOME to the target user's home; --preserve-env=PATH keeps the parent PATH
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "install-vscodium-extensions.sh refuses to run as root and SUDO_USER is unset." >&2
        echo "Re-run dcli sync from a non-root shell." >&2
        exit 1
    fi
fi

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXT_FILE="${MODULE_ROOT}/data/extensions.txt"

if ! command -v codium >/dev/null 2>&1; then
    echo "codium not on PATH — skipping." >&2
    exit 0
fi

if [ ! -f "${EXT_FILE}" ]; then
    exit 0
fi

# Declared set (from the data file)
declared=$(grep -vE '^\s*(#|$)' "${EXT_FILE}" | sed 's/#.*//; s/[[:space:]]//g' | grep -v '^$' | sort -u || true)

# Installed set (lowercased — VSCodium IDs are case-insensitive but the CLI
# may report a different case than the marketplace listing)
installed=$(codium --list-extensions 2>/dev/null | sort -u || true)

# Install anything declared but not installed
comm -23 <(printf '%s\n' "${declared}") <(printf '%s\n' "${installed}") \
    | while read -r ext; do
        [ -z "${ext}" ] && continue
        codium --install-extension "${ext}" --force || echo "  ! install failed: ${ext}"
    done

# Uninstall anything installed but no longer declared
comm -13 <(printf '%s\n' "${declared}") <(printf '%s\n' "${installed}") \
    | while read -r ext; do
        [ -z "${ext}" ] && continue
        codium --uninstall-extension "${ext}" || echo "  ! uninstall failed: ${ext}"
    done
