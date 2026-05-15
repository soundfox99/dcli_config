#!/usr/bin/env bash
# Enable fstrim.timer for periodic SSD trim. dcli's service handling only
# scans .service units so we manage the timer here. Idempotent.

set -euo pipefail

if ! systemctl list-unit-files fstrim.timer >/dev/null 2>&1; then
    echo "fstrim.timer unit not present on this system — skipping."
    exit 0
fi

if systemctl is-enabled fstrim.timer >/dev/null 2>&1; then
    echo "fstrim.timer already enabled."
    exit 0
fi

if [ "${EUID}" -ne 0 ]; then
    echo "enable-fstrim-timer.sh must run as root" >&2
    exit 1
fi

systemctl enable --now fstrim.timer
echo "Enabled fstrim.timer."
