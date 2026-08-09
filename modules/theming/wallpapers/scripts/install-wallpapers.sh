#!/usr/bin/env bash
# Shallow-clone (or update) the wallpaper collection into ~/Pictures/Wallpapers.
#
# Idempotent, and safe to run over a directory that already holds the images
# but is not yet a git repo: in that case the remote is adopted in place rather
# than the directory being wiped and re-cloned.
#
# Kept shallow on purpose. The upstream history is large and worthless here --
# we only ever want the current snapshot of the images.
#
# Runs as the user (writes under $HOME).

set -euo pipefail

REPO_URL="https://github.com/dharmx/walls"
BRANCH="main"
TARGET="${HOME}/Pictures/Wallpapers"

if [ "${EUID}" -eq 0 ]; then
    echo "install-wallpapers.sh must run as the user, not root" >&2
    exit 1
fi

if [ -d "${TARGET}/.git" ]; then
    # Already a repo: fast-forward to the current upstream snapshot. Staying
    # shallow means the fetch stays cheap on every sync.
    echo "updating ${TARGET}"
    git -C "${TARGET}" fetch --depth 1 origin "${BRANCH}"
    git -C "${TARGET}" checkout -f -B "${BRANCH}" "origin/${BRANCH}"

elif [ -d "${TARGET}" ] && [ -n "$(ls -A "${TARGET}" 2>/dev/null)" ]; then
    # Images are present but unmanaged. git clone refuses a non-empty target,
    # so init and adopt the remote instead of deleting anything. checkout -f
    # aligns files that differ; anything local-only is left in place.
    echo "adopting existing ${TARGET} (non-empty, no .git)"
    git -C "${TARGET}" init -b "${BRANCH}" -q
    git -C "${TARGET}" remote add origin "${REPO_URL}"
    git -C "${TARGET}" fetch --depth 1 origin "${BRANCH}"
    git -C "${TARGET}" checkout -f -B "${BRANCH}" "origin/${BRANCH}"

else
    echo "cloning ${REPO_URL} to ${TARGET}"
    mkdir -p "$(dirname "${TARGET}")"
    git clone --depth 1 --single-branch --branch "${BRANCH}" \
        "${REPO_URL}" "${TARGET}"
fi

count="$(find "${TARGET}" -type f -not -path "${TARGET}/.git/*" | wc -l)"
echo "${count} files in ${TARGET}"
