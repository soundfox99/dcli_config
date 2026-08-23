-- Host configuration for arch-desktop (Personal Desktop)
-- niri is the daily driver and the only DE deployed here. kde-plasma and
-- hyprland modules still exist in the repo (the laptop enables kde-plasma),
-- they are just not enabled on this host.

return {
    host = "arch-desktop",
    description = "Personal Desktop",

    enabled_modules = {
        -- Conditional / system-wide
        "hardware",
        "system-packages-arch-desktop",
        "wifi-rtl8821ce/module", -- RTL8821CE (rtw88) disconnect/throughput fix

        -- Theming, fonts, notifications
        "fonts/module",
        "theming/module",
        "theming/wallpapers",
        "notifications/module",

        -- CLI + shell
        "cli/module",
        "cli/yazi",
        "shell/bash",
        "shell/starship",
        "shell/tmux",

        -- Terminal + editors
        "terminals/kitty",
        "editors/neovim",
        "editors/vscodium",
        "editors/office",
        "editors/obsidian",
        "git-config",

        -- Programming languages
        "programming-languages/rust",
        "programming-languages/go",
        "programming-languages/python",
        "programming-languages/nodejs",
        "programming-languages/ruby",

        -- Apps — both browser modules: browsers/module is firefox + chromium
        -- + brave, browsers/zen is Zen on its own. They don't conflict; the
        -- split exists so the laptop can take Zen alone.
        "browsers/module",
        "browsers/zen",
        "socials/module",
        "media/module",
        "torrents/module",
        "flatpak/module",
        "games/module",

        -- VMs and containers
        "containers/module",
        "virtualization/module",
        "vpns/module",

        -- LLMs
        "llms/module",

        -- ComfyUI (Stable Diffusion image gen — installs in ~/ComfyUI/.venv)
        "comfyui/module",

        -- Desktop environment — niri only. SDDM still picks the session at
        -- login, but niri is the only one this host deploys packages and
        -- dotfiles for. Re-add "desktop-environments/kde-plasma" or
        -- "desktop-environments/hyprland" here to bring either back.
        "desktop-environments/niri",

        -- Interactive first-run setup (SSH key, git-crypt unlock, docker group)
        "onboarding/module",

        -- Ad-hoc dcli installs land here
        "declared-packages",
    },

    packages = {},
    exclude = {},

    flatpak_scope = "user",
    auto_prune = false,
    module_processing = "parallel",
    aur_helper = "yay",
    editor = "nvim",

    config_backups = {
        enabled = true,
        max_backups = 5,
    },

    system_backups = {
        enabled = true,
        backup_on_sync = true,
        backup_on_update = true,
        tool = "timeshift",
        snapper_config = "root",
        max_backups = 5,
    },

    services = {
        scope = "system",
        enabled = {
            "NetworkManager",
            "bluetooth",
            "cups",
            "docker",
            "containerd",
            "libvirtd",
            "sddm",
            "sshd",
            "fstrim.timer",
            "comfyui",
        },
        disabled = {},
    },

    theming = {
        cursor = {
            -- Must match the directory name bibata-cursor-theme installs
            -- under /usr/share/icons — dcli compares case-sensitively.
            theme = "Bibata-Modern-Ice",
            size = 24,
        },
    },

    default_apps = {
        scope = "user",
        browser = "firefox.desktop",
        text_editor = "vscodium",
        file_manager = "org.kde.dolphin.desktop",
        video_player = "mpv",
        audio_player = "mpv",
        image_viewer = "org.kde.dolphin.desktop",
        pdf_viewer = "firefox.desktop",
        mime_types = {
            ["text/csv"] = "libreoffice-calc.desktop",
            ["application/vnd.oasis.opendocument.spreadsheet"] = "libreoffice-calc.desktop",
            ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] = "libreoffice-calc.desktop",
            ["application/vnd.oasis.opendocument.text"] = "libreoffice-writer.desktop",
            ["application/vnd.openxmlformats-officedocument.wordprocessingml.document"] = "libreoffice-writer.desktop",
            ["application/vnd.oasis.opendocument.presentation"] = "libreoffice-impress.desktop",
            ["application/vnd.openxmlformats-officedocument.presentationml.presentation"] = "libreoffice-impress.desktop",
        },
    },
}
