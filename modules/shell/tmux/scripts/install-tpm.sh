#!/usr/bin/env bash
# Clone tmux plugin manager (tpm) into ~/.tmux/plugins/tpm if not already present.
#
# De-escalate before reading $HOME, or tpm lands in /root.

set -euo pipefail

if [ "${EUID}" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        exec sudo -H -u "${SUDO_USER}" --preserve-env=PATH -- "$0" "$@"
    else
        echo "install-tpm.sh refuses to run as root and SUDO_USER is unset." >&2
        echo "Re-run dcli sync from a non-root shell." >&2
        exit 1
    fi
fi

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [ -d "${TPM_DIR}/.git" ]; then
    echo "tpm already installed at ${TPM_DIR}"
    exit 0
fi

mkdir -p "$(dirname "${TPM_DIR}")"
git clone https://github.com/tmux-plugins/tpm.git "${TPM_DIR}"
echo "Installed tpm. Press prefix + I inside tmux to fetch plugins."
