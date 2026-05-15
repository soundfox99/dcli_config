#!/usr/bin/env bash
# Clone tmux plugin manager (tpm) into ~/.tmux/plugins/tpm if not already present.

set -euo pipefail

TPM_DIR="${HOME}/.tmux/plugins/tpm"

if [ -d "${TPM_DIR}/.git" ]; then
    echo "tpm already installed at ${TPM_DIR}"
    exit 0
fi

mkdir -p "$(dirname "${TPM_DIR}")"
git clone https://github.com/tmux-plugins/tpm.git "${TPM_DIR}"
echo "Installed tpm. Press prefix + I inside tmux to fetch plugins."
