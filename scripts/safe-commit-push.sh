#!/usr/bin/env bash
# Commit working-tree changes and push to origin — but ONLY after verifying
# that every file matched by .gitattributes' git-crypt filter is actually
# encrypted. Refuses to commit plaintext that would otherwise leak.
#
# Safe to run on every sync — no-op when working tree is clean.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# 1. Bail if working tree is clean.
if git diff --quiet HEAD && [ -z "$(git status --porcelain)" ]; then
    echo "[commit-push] Nothing to commit."
    exit 0
fi

# 2. Stage everything.
git add -A

# 3. Verify nothing sensitive is leaking. git-crypt prints "NOT ENCRYPTED" as
#    a warning suffix on any file matched by the encryption filter that's
#    staged in plaintext. That's our canonical leak signal.
unsafe=$(git-crypt status 2>/dev/null | grep "NOT ENCRYPTED" || true)
if [ -n "${unsafe}" ]; then
    echo "[commit-push] REFUSING to commit — git-crypt reports leaking files:" >&2
    echo "${unsafe}" >&2
    echo >&2
    echo "  Run 'git-crypt status' for the full picture. Either:" >&2
    echo "    - Run scripts/setup-repo-encryption.sh to initialize git-crypt, or" >&2
    echo "    - 'git rm --cached <file>' then re-add to pick up the filter" >&2
    exit 1
fi

# 4. Belt + suspenders: spot-check the staged blob of one bookmark file by
#    piping through xxd (bash can't compare strings containing null bytes).
sample=$(git ls-files browser-bookmarks/ 2>/dev/null | head -n1)
if [ -n "${sample}" ]; then
    magic=$(git show ":${sample}" 2>/dev/null | head -c 9 | xxd -p)
    if [ "${magic}" != "004749544352595054" ]; then
        echo "[commit-push] REFUSING — ${sample} is staged as PLAINTEXT." >&2
        echo "  First 9 bytes (hex): ${magic}" >&2
        echo "  Expected: 004749544352595054 (\\0GITCRYPT magic)" >&2
        exit 1
    fi
fi

# 5. Build a commit message from what changed.
short_summary=$(git diff --cached --shortstat | sed 's/^ //')
msg="auto: dcli sync snapshot — ${short_summary}"

git commit -m "${msg}"
echo "[commit-push] Committed: ${msg}"

# 6. Push if a remote is set.
if git remote get-url origin >/dev/null 2>&1; then
    git push origin HEAD
    echo "[commit-push] Pushed to origin."
else
    echo "[commit-push] No 'origin' remote — skipping push."
fi
