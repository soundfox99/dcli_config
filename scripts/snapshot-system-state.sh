#!/usr/bin/env bash
# Capture mutable state from the running system back into the repo:
#   - VSCodium extensions
#
# Browser extension IDs and bookmarks used to be captured here too. Both were
# removed — they are managed by hand now — which also retired the git-crypt
# entries that protected the bookmark HTML.
#
# Idempotent — re-running with no changes is a no-op.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ─── VSCodium extensions ────────────────────────────────────────────────────
# Replace-style (matches browser snapshot): the running VSCodium is the source
# of truth. Uninstalling in the IDE then `dcli-push` removes the ID from the
# repo on next sync. If you want to declare an ID without installing yet, add
# it to the file AND run `dcli sync` before the next `dcli-push`.
if command -v codium >/dev/null 2>&1; then
    out="${REPO_ROOT}/modules/editors/vscodium/data/extensions.txt"
    installed=$(codium --list-extensions 2>/dev/null | sort -u || true)
    {
        echo "# VSCodium extensions captured from \`codium --list-extensions\`."
        echo "# Last snapshot: $(date -Iseconds)"
        echo "# This file is overwritten on every dcli-push — edit the running"
        echo "# VSCodium (install/uninstall), or add an ID below and run"
        echo "# 'dcli sync' to install it before the next push."
        echo
        echo "${installed}"
    } > "${out}"
    echo "  vscodium: $(echo "${installed}" | grep -c .) extension(s)"
fi

echo "[snapshot] Done."
