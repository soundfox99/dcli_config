#!/usr/bin/env bash
# Re-enable Chromium VA-API on NVIDIA hosts by overriding its desktop entry.
#
# Chromium hard-skips any DRM render node named "nvidia-drm" during VA-API
# probing (media/gpu/vaapi/vaapi_wrapper.cc), so on such a host it falls back to
# CPU decode for everything and refuses HEVC outright — Chromium has no software
# H.265 decoder, so H.265 sites play audio over a black video frame. The system
# VA-API stack is fine (nvidia_drv_video.so reports "VA-API NVDEC driver [direct
# backend]" and ffmpeg decodes through it); it is only Chromium's blocklist.
# --enable-features=VaapiOnNvidiaGPUs lifts exactly that skip; it is sufficient
# on its own, no --ignore-gpu-blocklist needed.
#
# Arch's /usr/bin/chromium is the real binary, not a wrapper, so there is no
# chromium-flags.conf to write and Chromium policy cannot set feature flags. The
# supported lever is the .desktop entry. /usr/local/share sorts ahead of
# /usr/share in XDG_DATA_DIRS, and the file keeps the ID "chromium.desktop", so
# this replaces the packaged entry rather than adding a second launcher item.
# Derived from the stock file by rewriting Exec= only, so Chromium upgrades (new
# translations, new actions) carry over on the next sync.
#
# Caveat: this only covers launches that go through the desktop entry. Typing
# `chromium` in a terminal still gets the stock flags and stock behaviour.
#
# Previously lived in modules/browsers/scripts/install-browser-policies.sh,
# which also deployed extension auto-install policies. That policy machinery was
# removed along with bookmark sync; this hardware workaround outlived it and now
# hangs off the hardware module, where GPU-conditional behaviour belongs.
#
# Idempotent. Runs as root (writes under /usr/local/share).

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "chromium-nvidia-vaapi.sh must run as root" >&2
    exit 1
fi

CHROMIUM_NVIDIA_FLAGS="--enable-features=VaapiOnNvidiaGPUs"

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

stock=/usr/share/applications/chromium.desktop
override=/usr/local/share/applications/chromium.desktop

if ! host_has_nvidia_gpu; then
    # Not an NVIDIA host — make sure a stale override from one doesn't linger.
    rm -f "${override}"
    exit 0
fi
if [ ! -f "${stock}" ]; then
    # Chromium isn't installed on this host.
    rm -f "${override}"
    exit 0
fi

install -d /usr/local/share/applications
sed -E "s|^Exec=/usr/bin/chromium|Exec=/usr/bin/chromium ${CHROMIUM_NVIDIA_FLAGS}|" \
    "${stock}" > "${override}"
echo "chromium.desktop override: VA-API enabled on NVIDIA (${CHROMIUM_NVIDIA_FLAGS})."

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/local/share/applications || true
fi
