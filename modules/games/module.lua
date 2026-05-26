---@diagnostic disable: undefined-global -- dcli globals are provided by dcli runtime

-- 32-bit GPU/Vulkan userland (lib32-vulkan-*, lib32-mesa, lib32-nvidia-utils)
-- is emitted by modules/hardware.lua based on the detected GPU + multilib
-- probe, so this module does not redeclare it.

local packages = {
    -- Steam + native runtime
    "steam",

    -- Wine + Proton tooling
    "wine",
    "wine-mono",
    "wine-gecko",
    "winetricks",
    "protontricks",
    "proton-ge-custom-bin",     -- AUR: GloriousEggroll Proton build

    -- Launchers
    "lutris",
    "heroic-games-launcher-bin", -- AUR: Epic / GOG / Amazon

    -- Performance / overlay
    "gamemode",
    "mangohud",
    "goverlay",                  -- GUI to configure MangoHud

    -- Controllers (udev rules for Xbox / DualShock / 8BitDo / etc.)
    "game-devices-udev",
}

-- 32-bit gamemode/mangohud only meaningful with multilib; gate the same way
-- hardware.lua does to avoid a sandbox-blocked pacman.conf read.
if dcli.package.is_available("lib32-gamemode") then
    table.insert(packages, "lib32-gamemode")
    table.insert(packages, "lib32-mangohud")
end

return {
    description = "Gaming stack: Steam, Wine/Proton, Lutris/Heroic, GameMode + MangoHud",
    packages = packages,
}
