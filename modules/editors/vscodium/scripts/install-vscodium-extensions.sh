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
        exec sudo -u "${SUDO_USER}" --preserve-env=HOME,PATH -- "$0" "$@"
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

while IFS= read -r line; do
    line="${line%%#*}"           # strip inline comment
    line="${line//[[:space:]]/}" # strip whitespace
    [ -z "${line}" ] && continue
    codium --install-extension "${line}" --force || echo "  ! failed: ${line}"
done < "${EXT_FILE}"
