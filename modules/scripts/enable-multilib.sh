#!/usr/bin/env bash
# Enable the [multilib] repository in /etc/pacman.conf and refresh the
# package database. Idempotent: exits cleanly if multilib is already enabled.
# Run as root by dcli (run_hooks_as_user = false on the hardware module).

set -euo pipefail

PACMAN_CONF="/etc/pacman.conf"

if [ "${EUID}" -ne 0 ]; then
    echo "enable-multilib.sh must run as root" >&2
    exit 1
fi

# Already enabled? Active section header is an uncommented "[multilib]" line.
if grep -Eq '^\[multilib\]' "${PACMAN_CONF}"; then
    echo "multilib already enabled — nothing to do."
    exit 0
fi

# Belt + suspenders: only proceed if we can find a commented section to uncomment.
if ! grep -Eq '^#\[multilib\]' "${PACMAN_CONF}"; then
    echo "Could not find a commented [multilib] section in ${PACMAN_CONF} — aborting." >&2
    echo "Add multilib manually and re-run dcli sync." >&2
    exit 2
fi

BACKUP="${PACMAN_CONF}.bak.$(date +%Y%m%d-%H%M%S)"
cp -a "${PACMAN_CONF}" "${BACKUP}"
echo "Backed up ${PACMAN_CONF} to ${BACKUP}"

# Uncomment the section header and the two lines immediately following it
# (Include = /etc/pacman.d/mirrorlist). Standard Arch layout puts them
# consecutively after the [multilib] heading.
awk '
    BEGIN { in_block = 0; remaining = 0 }
    /^#\[multilib\]$/ {
        sub(/^#/, "", $0); print
        in_block = 1
        remaining = 2
        next
    }
    in_block && remaining > 0 {
        sub(/^#/, "", $0); print
        remaining--
        if (remaining == 0) in_block = 0
        next
    }
    { print }
' "${BACKUP}" > "${PACMAN_CONF}"

echo "Enabled [multilib] in ${PACMAN_CONF}. Refreshing package database..."
pacman -Sy --noconfirm
echo "Done."
