-- Host configuration for arch-desktop (Personal Desktop)
-- KDE Plasma is the active DE; niri and hyprland modules are present but
-- opt-in (uncomment in enabled_modules to switch).

return {
    host = "arch-desktop",
    description = "Personal Desktop",

    enabled_modules = {
        -- Conditional / system-wide
        "hardware",
        "system-packages-arch-desktop",

        -- Theming, fonts, notifications
        "fonts/module",
        "theming/module",
        "notifications/module",

        -- CLI + shell
        "cli/module",
        "shell/bash",
        "shell/starship",
        "shell/tmux",

        -- Terminal + editors
        "terminals/kitty",
        "editors/neovim",
        "editors/vscodium",
        "editors/office",
        "git-config",

        -- Programming languages
        "programming-languages/rust",
        "programming-languages/go",
        "programming-languages/python",
        "programming-languages/nodejs",
        "programming-languages/ruby",

        -- Apps
        "browsers/module",
        "socials/module",
        "media/module",
        "torrents/module",
        "flatpak/module",

        -- VMs and containers
        "containers/module",
        "virtualization/module",
        "vpns/module",

        -- Desktop environment (only one active at a time)
        "desktop-environments/kde-plasma",
        -- "desktop-environments/niri",
        -- "desktop-environments/hyprland",

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
            "sddm",
            "sshd",
            "fstrim.timer",
        },
        disabled = {},
    },

    theming = {
        cursor = {
            theme = "bibata-modern-ice",
            size = 24,
        },
        default_apps = {
            scope = "user",
            browser = "firefox.desktop",
            text_editor = "vscodium",
            file_manager = "dolphin",
            video_player = "mpv",
            audio_player = "mpv",
            image_viewer = "dolphin",
            pdf_viewer = "firefox.desktop",
            meme_types = {},
        },
    },
}
