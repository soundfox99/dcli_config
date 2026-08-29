#!/usr/bin/env bash
# Two jobs, both idempotent, both run as root:
#
#   1. Deploy browser policy files so extensions auto-install on first launch.
#      Reads IDs from modules/browsers/data/<browser>-extensions.txt (one per
#      line, blank lines + lines starting with # ignored). Rewrites each policy
#      file from the current data file, so removing an ID un-deploys it.
#
#   2. On NVIDIA hosts, drop a chromium.desktop override that turns VA-API back
#      on. See write_chromium_nvidia_vaapi_override() for why.
#
# Runs as root (writes under /etc and /usr/local/share).
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

# True when a PCI display-class device (class 0x03xxxx) reports NVIDIA's vendor
# ID. Read straight from sysfs rather than shelling out to lspci, which is
# pciutils and not guaranteed on a freshly bootstrapped host.
host_has_nvidia_gpu() {
    local dev
    for dev in /sys/bus/pci/devices/*; do
        [ -r "${dev}/class" ] && [ -r "${dev}/vendor" ] || continue
        case "$(< "${dev}/class")" in
            0x03*) ;;
            *) continue ;;
        esac
        [ "$(< "${dev}/vendor")" = "0x10de" ] && return 0
    done
    return 1
}

# Chromium hard-skips any DRM render node named "nvidia-drm" during VA-API
# probing (media/gpu/vaapi/vaapi_wrapper.cc), so on this box it falls back to
# CPU decode for everything and refuses HEVC outright — Chromium has no
# software H.265 decoder, so H.265 sites play audio over a black video frame.
# The system VA-API stack is fine (nvidia_drv_video.so reports "VA-API NVDEC
# driver [direct backend]" and ffmpeg decodes through it), it is only Chromium's
# blocklist. --enable-features=VaapiOnNvidiaGPUs lifts exactly that skip; it is
# sufficient on its own, no --ignore-gpu-blocklist needed.
#
# Arch's /usr/bin/chromium is the real binary, not a wrapper, so there is no
# chromium-flags.conf to write and Chromium policy cannot set feature flags.
# The supported lever is the .desktop entry. /usr/local/share sorts ahead of
# /usr/share in XDG_DATA_DIRS, and the file keeps the ID "chromium.desktop", so
# this replaces the packaged entry rather than adding a second launcher item.
# Derived from the stock file by rewriting Exec= only, so Chromium upgrades
# (new translations, new actions) carry over on the next sync.
#
# Caveat: this only covers launches that go through the desktop entry. Typing
# `chromium` in a terminal still gets the stock flags and stock behaviour.
CHROMIUM_NVIDIA_FLAGS="--enable-features=VaapiOnNvidiaGPUs"

write_chromium_nvidia_vaapi_override() {
    local stock=/usr/share/applications/chromium.desktop
    local override=/usr/local/share/applications/chromium.desktop

    if ! host_has_nvidia_gpu; then
        # Not an NVIDIA host — make sure a stale override from one doesn't linger.
        rm -f "${override}"
        return
    fi
    if [ ! -f "${stock}" ]; then
        rm -f "${override}"
        return
    fi

    install -d /usr/local/share/applications
    sed -E "s|^Exec=/usr/bin/chromium|Exec=/usr/bin/chromium ${CHROMIUM_NVIDIA_FLAGS}|" \
        "${stock}" > "${override}"
    echo "chromium.desktop override: VA-API enabled on NVIDIA (${CHROMIUM_NVIDIA_FLAGS})."

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database /usr/local/share/applications || true
    fi
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
        # The VA-API override is chromium's, so it rides along with chromium's
        # policy rather than running unconditionally — a host that only asks for
        # brave has no chromium.desktop to override.
        chromium) write_chromium_style_policy /etc/chromium "${DATA_DIR}/chromium-extensions.txt"
                  write_chromium_nvidia_vaapi_override ;;
        brave)    write_chromium_style_policy /etc/brave    "${DATA_DIR}/brave-extensions.txt" ;;
        *)        echo "unknown browser: ${browser}" >&2; exit 1 ;;
    esac
done
