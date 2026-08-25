#!/usr/bin/env bash
# Deploy browser policy files so extensions auto-install on first launch.
# Reads IDs from modules/browsers/data/<browser>-extensions.txt (one per line,
# blank lines + lines starting with # ignored). Idempotent: rewrites each
# policy file from the current data file, so removing an ID un-deploys it.
#
# Runs as root (writes under /etc).
#
# With no arguments, writes policies for all three browsers — that's what
# browsers/module.lua (firefox + chromium + brave) wants. Pass browser names to
# write only those, which is how a host that installs one browser out of the
# set avoids creating /etc/firefox and /etc/chromium for browsers it doesn't
# have. See browsers/brave/scripts/install-brave-policy.sh.

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "install-browser-policies.sh must run as root" >&2
    exit 1
fi

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="${MODULE_ROOT}/data"

read_ids() {
    local file="$1"
    [ -f "${file}" ] || return 0
    # Strip comments and blank lines.
    grep -vE '^\s*(#|$)' "${file}" || true
}

write_firefox_policy() {
    local ids
    mapfile -t ids < <(read_ids "${DATA_DIR}/firefox-extensions.txt")
    install -d /etc/firefox/policies
    if [ ${#ids[@]} -eq 0 ]; then
        rm -f /etc/firefox/policies/policies.json
        return
    fi
    {
        printf '{\n  "policies": {\n    "ExtensionSettings": {\n'
        local first=1
        for id in "${ids[@]}"; do
            [ "${first}" -eq 1 ] || printf ',\n'
            printf '      "%s": {\n        "installation_mode": "force_installed",\n        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/%s/latest.xpi"\n      }' "${id}" "${id}"
            first=0
        done
        printf '\n    }\n  }\n}\n'
    } > /etc/firefox/policies/policies.json
    echo "Firefox policy: ${#ids[@]} extension(s)."
}

write_chromium_style_policy() {
    local etc_dir="$1"
    local data_file="$2"
    local ids
    mapfile -t ids < <(read_ids "${data_file}")
    install -d "${etc_dir}/policies/managed"
    rm -f "${etc_dir}/policies/managed/"extension-*.json
    for id in "${ids[@]}"; do
        cat > "${etc_dir}/policies/managed/extension-${id}.json" <<EOF
{
  "ExtensionInstallForcelist": [
    "${id};https://clients2.google.com/service/update2/crx"
  ]
}
EOF
    done
    echo "${etc_dir}: ${#ids[@]} extension(s)."
}

browsers=("$@")
[ ${#browsers[@]} -eq 0 ] && browsers=(firefox chromium brave)

for browser in "${browsers[@]}"; do
    case "${browser}" in
        firefox)  write_firefox_policy ;;
        chromium) write_chromium_style_policy /etc/chromium "${DATA_DIR}/chromium-extensions.txt" ;;
        brave)    write_chromium_style_policy /etc/brave    "${DATA_DIR}/brave-extensions.txt" ;;
        *)        echo "unknown browser: ${browser}" >&2; exit 1 ;;
    esac
done
