-- Realtek RTL8821CE (rtw88) stability tuning.
-- The in-kernel rtw88_8821ce driver puts this chip into PCIe ASPM / deep
-- power-save states it doesn't handle well, which causes throughput to
-- collapse (rate stuck ~65 Mbit/s) and the link to deauth/reconnect in a
-- loop. The post-install hook drops modprobe + NetworkManager configs that
-- disable those power states. The hook self-gates on the 10ec:c821 PCI ID,
-- so it's a no-op on hosts without the card (e.g. arch-laptop).
--
-- `iw` is pulled in for wireless introspection (get power_save, station dump).
---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

return {
    description = "RTL8821CE (rtw88) WiFi tuning: disable ASPM/deep-LPS to stop disconnects",
    packages = { "iw" },

    post_install_hook = "scripts/tune-rtw88.sh",
    hook_behavior = "always",
    run_hooks_as_user = false,
}
