#!/usr/bin/env bash
# Fetch the wallpaper collection into ~/Pictures/Wallpapers from GitHub's
# tarball endpoint, then hand off to apply-wallpaper.sh to point the desktops
# at the image named at the top of that script.
#
# The fetch lives in a function so that every outcome — up to date, adopted,
# freshly downloaded, network down — still falls through to the apply step.
# Returning early would mean the wallpaper only ever got set on the one run
# that happened to download something.
#
# Not a git clone: the repo's pack is >1.6 GB and a --depth 1 fetch died on a
# mid-transfer disconnect, which git cannot resume. A tarball is a single
# resumable stream (curl -C -) with no .git objects to keep around.
#
# Must run as the desktop user. If dcli's run_hooks_as_user couldn't
# de-escalate (sudo context), re-exec ourselves as ${SUDO_USER}, before $HOME
# is read.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "install-wallpapers.sh refuses to run as root and SUDO_USER is unset." >&2
        echo "Re-run dcli sync from a non-root shell." >&2
        exit 1
    fi
fi

REPO="dharmx/walls"
BRANCH="main"
TARGET="${HOME}/Pictures/Wallpapers"
STAMP="${TARGET}/.walls-version"
WORK="${HOME}/Pictures/.walls-download"

fetch_collection() {
    # Upstream HEAD, resolved without fetching any objects.
    local remote_sha have_sha count tarball
    remote_sha="$(git ls-remote "https://github.com/${REPO}" "refs/heads/${BRANCH}" | cut -f1)"
    if [ -z "${remote_sha}" ]; then
        echo "could not resolve ${REPO}@${BRANCH} — network down? skipping" >&2
        return 0
    fi

    have_sha=""
    [ -f "${STAMP}" ] && have_sha="$(cat "${STAMP}")"

    if [ "${have_sha}" = "${remote_sha}" ] && [ "${WALLS_FORCE:-0}" != "1" ]; then
        echo "wallpapers already at ${remote_sha:0:8} — nothing to do"
        return 0
    fi

    # Images present but unstamped: assume they are this collection and adopt
    # them rather than pulling 3.3 GB to land the same bytes. WALLS_FORCE=1
    # overrides.
    if [ -z "${have_sha}" ] && [ -d "${TARGET}" ] && \
       [ -n "$(ls -A "${TARGET}" 2>/dev/null)" ] && [ "${WALLS_FORCE:-0}" != "1" ]; then
        count="$(find "${TARGET}" -type f -not -name '.walls-version' | wc -l)"
        echo "${TARGET} already holds ${count} files — adopting as ${remote_sha:0:8}"
        echo "  (WALLS_FORCE=1 to download and overwrite from upstream)"
        printf '%s\n' "${remote_sha}" > "${STAMP}"
        return 0
    fi

    echo "fetching ${REPO}@${remote_sha:0:8} (~3.3 GB)"
    mkdir -p "${WORK}" "${TARGET}"
    tarball="${WORK}/${remote_sha}.tar.gz"

    # --retry covers transient drops; -C - resumes a partial file across runs,
    # which is the whole reason this isn't a git fetch.
    curl -fL --retry 5 --retry-delay 3 --retry-all-errors -C - \
        -o "${tarball}" \
        "https://codeload.github.com/${REPO}/tar.gz/${remote_sha}"

    # --strip-components=1 drops the walls-<sha>/ wrapper directory. Existing
    # files are overwritten, local-only files are left alone.
    tar -xzf "${tarball}" --strip-components=1 -C "${TARGET}"

    printf '%s\n' "${remote_sha}" > "${STAMP}"
    rm -rf "${WORK}"

    count="$(find "${TARGET}" -type f -not -name '.walls-version' | wc -l)"
    echo "${count} files in ${TARGET} at ${remote_sha:0:8}"
}

fetch_collection

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/apply-wallpaper.sh"
