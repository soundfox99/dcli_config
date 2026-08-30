return {
    description = "Web browsers (firefox, chromium, brave)",
    -- Extension auto-install policies and bookmark sync were removed: managed
    -- by hand now. The NVIDIA VA-API desktop-entry override that used to ride
    -- along with the policy hook moved to modules/hardware.lua, where
    -- GPU-conditional behaviour belongs.
    packages = {
        "firefox",
        "chromium",
        "brave-bin",
    },
}
