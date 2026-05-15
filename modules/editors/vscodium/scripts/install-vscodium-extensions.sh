#!/usr/bin/env bash
# Install VSCodium extensions listed in data/extensions.txt (one ID per line,
# blank lines + # comments ignored). Idempotent: --install-extension --force
# is a no-op at the same version.

set -euo pipefail

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
