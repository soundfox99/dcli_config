#!/usr/bin/env bash
# Commit working-tree changes and push to origin — but ONLY after verifying
# that every file matched by .gitattributes' git-crypt filter is actually
# encrypted. Refuses to commit plaintext that would otherwise leak.
#
# Safe to run on every sync. Committing and pushing are independent: a clean
# working tree skips the commit but still pushes anything the local branch is
# ahead by, so a commit that was made while the network (or credentials) were
# unavailable gets published on the next run instead of being stranded.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# ─── Commit, if there's anything to commit ─────────────────────────────────

if git diff --quiet HEAD && [ -z "$(git status --porcelain)" ]; then
    echo "[commit-push] Nothing to commit."
else
    # 1. Stage everything.
    git add -A

    # 2. Verify nothing sensitive is leaking. git-crypt prints "NOT ENCRYPTED"
    #    as a warning suffix on any file matched by the encryption filter
    #    that's staged in plaintext. That's our canonical leak signal.
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

    # 3. Belt + suspenders: spot-check the staged blob of one bookmark file by
    #    piping through xxd (bash can't compare strings containing null bytes).
    sample=$(git ls-files 'modules/browsers/data/*-bookmarks.html' 2>/dev/null | head -n1)
    if [ -n "${sample}" ]; then
        magic=$(git show ":${sample}" 2>/dev/null | head -c 9 | xxd -p)
        if [ "${magic}" != "004749544352595054" ]; then
            echo "[commit-push] REFUSING — ${sample} is staged as PLAINTEXT." >&2
            echo "  First 9 bytes (hex): ${magic}" >&2
            echo "  Expected: 004749544352595054 (\\0GITCRYPT magic)" >&2
            exit 1
        fi
    fi

    # 4. Build a commit message from what changed.
    short_summary=$(git diff --cached --shortstat | sed 's/^ //')
    msg="auto: dcli sync snapshot — ${short_summary}"

    git commit -m "${msg}"
    echo "[commit-push] Committed: ${msg}"
fi

# ─── Push whatever the branch is ahead by ──────────────────────────────────
# Deliberately outside the commit branch above: the previous version returned
# early on a clean tree, so a commit whose push failed could never be retried.

if ! git remote get-url origin >/dev/null 2>&1; then
    echo "[commit-push] No 'origin' remote — skipping push."
    exit 0
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [ "${branch}" = "HEAD" ]; then
    echo "[commit-push] Detached HEAD — refusing to guess a branch to push." >&2
    exit 1
fi

# No remote-tracking ref yet (new branch) → push and set upstream.
if ! git rev-parse --verify --quiet "origin/${branch}" >/dev/null; then
    echo "[commit-push] origin/${branch} doesn't exist yet — pushing and setting upstream."
    git push --set-upstream origin "${branch}"
    echo "[commit-push] Pushed to origin/${branch}."
    exit 0
fi

ahead="$(git rev-list --count "origin/${branch}..HEAD")"
if [ "${ahead}" -eq 0 ]; then
    echo "[commit-push] origin/${branch} already up to date — nothing to push."
    exit 0
fi

echo "[commit-push] ${ahead} commit(s) ahead of origin/${branch} — pushing."
if ! git push origin "${branch}"; then
    echo >&2
    echo "[commit-push] PUSH FAILED — ${ahead} commit(s) are committed locally but" >&2
    echo "  not published. Nothing was lost; re-run this script once the problem" >&2
    echo "  is fixed and it will retry the push." >&2
    echo >&2
    echo "  If the error mentions credentials, origin is over HTTPS:" >&2
    echo "    $(git remote get-url origin)" >&2
    echo "  The README provisions this repo over SSH. To switch:" >&2
    echo "    git remote set-url origin git@github.com:soundfox99/dcli_config.git" >&2
    exit 1
fi
echo "[commit-push] Pushed to origin/${branch}."
