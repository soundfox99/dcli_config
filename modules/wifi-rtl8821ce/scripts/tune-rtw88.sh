#!/usr/bin/env bash
# Stabilize the Realtek RTL8821CE (rtw88_8821ce) WiFi adapter.
#
# This chip's throughput collapses and the link deauth-loops when the driver
# uses PCIe ASPM and deep link power save. We disable both via a modprobe
# drop-in, and turn off NetworkManager WiFi power saving. Idempotent, and a
# no-op on machines that don't have the card. Run as root by dcli
# (run_hooks_as_user = false).
#
# NOTE: rtw88_8821ce honors `iw dev <dev> set power_save off` but ignores
# NetworkManager's declarative `wifi.powersave = 2` at association time, so the
# NM conf.d drop-in alone leaves 802.11 power save "on". We keep the conf.d
# (correct declarative intent; may work after a driver fix) AND install an NM
# dispatcher script that forces power save off with `iw` on every wifi up.
#
# Applying the modprobe change requires a reboot (or a driver reload); this
# script only writes config and reports what's needed — it does NOT tear the
# live connection down mid-sync.

set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "tune-rtw88.sh must run as root" >&2
    exit 1
fi

# --- Gate on the card actually being present -------------------------------
# 10ec:c821 = RTL8821CE. Prefer lspci; fall back to sysfs if pciutils is absent.
card_present() {
    if command -v lspci >/dev/null 2>&1; then
        lspci -n 2>/dev/null | grep -qi '10ec:c821' && return 0
    fi
    grep -qiRl '0x10ec' /sys/bus/pci/devices/*/vendor 2>/dev/null &&
        grep -qiRl '0xc821' /sys/bus/pci/devices/*/device 2>/dev/null && return 0
    return 1
}

if ! card_present; then
    echo "RTL8821CE (10ec:c821) not present — nothing to tune."
    exit 0
fi

SENTINEL="# Managed by arch-config wifi-rtl8821ce module."
changed=0

# write_managed <path> <content> [mode]: write only if content differs. If an
# existing file is NOT ours (no sentinel), back it up before replacing.
write_managed() {
    local path="$1" content="$2" mode="${3:-644}"
    if [ -f "${path}" ] && diff -q <(printf '%s\n' "${content}") "${path}" >/dev/null 2>&1; then
        return 0  # already up to date
    fi
    if [ -f "${path}" ] && ! grep -qF "${SENTINEL}" "${path}"; then
        local backup="${path}.bak.$(date +%Y%m%d-%H%M%S)"
        cp -a "${path}" "${backup}"
        echo "Backed up existing ${path} to ${backup}"
    fi
    install -Dm"${mode}" /dev/stdin "${path}" <<<"${content}"
    echo "Wrote ${path}"
    changed=1
}

# --- 1. modprobe: disable ASPM + deep LPS ----------------------------------
write_managed /etc/modprobe.d/rtw88-8821ce.conf "${SENTINEL}
# RTL8821CE stability fix: PCIe ASPM and deep link power save on this chip
# cause throughput collapse and repeated deauth/disconnect. Disable both.
options rtw88_pci disable_aspm=1
options rtw88_core disable_lps_deep=1"

# --- 2. NetworkManager: disable WiFi power save (2 = off) -------------------
write_managed /etc/NetworkManager/conf.d/wifi-powersave.conf "${SENTINEL}
# rtw88 LPS drops packets on the RTL8821CE; force WiFi power save off.
[connection]
wifi.powersave = 2"

# --- 3. NM dispatcher: force power_save off via iw on every wifi up ---------
# rtw88_8821ce ignores NM's declarative wifi.powersave, so enforce it directly.
write_managed /etc/NetworkManager/dispatcher.d/50-rtw88-powersave.sh "#!/bin/sh
${SENTINEL}
# rtw88_8821ce honors \`iw ... set power_save off\` but not NM's wifi.powersave.
# Force it off whenever a wireless interface comes up or changes state.
interface=\"\$1\"
action=\"\$2\"
case \"\${action}\" in
    up | dhcp4-change | dhcp6-change | connectivity-change) ;;
    *) exit 0 ;;
esac
case \"\${interface}\" in
    wl*) exec iw dev \"\${interface}\" set power_save off ;;
esac" 755

if [ "${changed}" -eq 1 ]; then
    echo
    echo ">>> WiFi tuning written. To activate:"
    echo ">>>   reboot                       (applies the modprobe ASPM/LPS change)"
    echo ">>> The dispatcher forces power_save off on the next wifi up event;"
    echo ">>> apply now without a reboot with:  iw dev <wlan> set power_save off"
    echo ">>> Not rebooting now avoids tearing down the connection mid-sync."
else
    echo "RTL8821CE tuning already in place — nothing to do."
fi
