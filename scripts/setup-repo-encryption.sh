#!/usr/bin/env bash
# One-time setup: initialize git-crypt for this repo and export the symmetric
# key. The same key encrypts everything matched by .gitattributes
# (bookmarks today; other secrets later).
#
# CRITICAL: run this BEFORE any `git add` of files that should be encrypted,
# and BEFORE `dcli repo init` (which auto-commits + pushes without consulting
# git-crypt). If you commit plaintext once and push, that data is on the
# remote forever — even repo deletion + force-push can't fully purge it.

set -euo pipefail

KEY_OUT="${1:-${HOME}/arch-dcli-config.key}"

if ! command -v git-crypt >/dev/null; then
    echo "git-crypt is not installed. Run 'dcli sync' first." >&2
    exit 1
fi

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "Not a git repository. Run 'git init -b main' first, then re-run this script." >&2
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

# Refuse to run if plaintext-sensitive files are already tracked — encrypting
# them now leaves the plaintext blob in history forever.
TRACKED_PLAINTEXT="$(git ls-files browser-bookmarks/ 2>/dev/null || true)"
if [ -n "${TRACKED_PLAINTEXT}" ]; then
    cat >&2 <<EOF
ERROR: browser-bookmarks/ files are already tracked in git:
${TRACKED_PLAINTEXT}

If you've already committed (and pushed) plaintext, the data is leaked.
Recover by:
  1. Delete the remote on GitHub and recreate it empty.
  2. rm -rf .git
  3. Re-run: git init -b main && $0
  4. git add .gitattributes && git add -A
  5. git-crypt status | grep encrypted   # verify before committing
EOF
    exit 2
fi

if [ ! -f .gitattributes ]; then
    echo "ERROR: .gitattributes is missing. git-crypt has nothing to encrypt." >&2
    exit 3
fi

if [ -f .git/git-crypt/keys/default ]; then
    echo "git-crypt already initialized in this repo."
else
    git-crypt init
    echo "git-crypt initialized."
fi

if [ -e "${KEY_OUT}" ]; then
    echo "Key file already exists at ${KEY_OUT} — leaving it untouched."
else
    git-crypt export-key "${KEY_OUT}"
    chmod 600 "${KEY_OUT}"
    echo "Exported symmetric key to ${KEY_OUT}"
    echo "Back this file up out-of-band (password manager + USB). It is the"
    echo "ONLY way to decrypt this repo on a new clone."
fi

echo
echo "Next steps (in this exact order — git-crypt MUST be set up before staging):"
cat <<'EOF'
  git add .gitattributes              # stage the filter rule first
  git add -A                          # then everything; bookmarks encrypt on add
  git-crypt status | grep browser     # verify each line says "encrypted: ..."
  git commit -m "Initial arch-config"
  git remote add origin git@github.com:USER/REPO.git
  git push -u origin main

  # Sanity check after commit (should print "GITCRYPT" magic, not HTML):
  git show HEAD:browser-bookmarks/firefox.html | head -c 9 | xxd
EOF

echo
echo "DO NOT run 'dcli repo init' — it auto-stages + commits + pushes without"
echo "checking git-crypt status. Use the manual git commands above instead."
