-- Host configuration for arch-laptop (Personal Laptop)
-- Subset of arch-desktop: excludes games and comfyui; niri is the only DE.
-- The matching hostname will be set later; rename the file if needed so it
-- matches the machine's actual hostname (dcli auto-picks hosts/<hostname>.lua).

return {
    host = "arch-laptop",
    description = "Personal Laptop",

    enabled_modules = {
        -- Conditional / system-wide
        "hardware",
        -- TODO: create modules/system-packages-arch-laptop/ mirroring the
        -- desktop one, then enable it here. Left off for now.
        -- "system-packages-arch-laptop",

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

        -- LLMs
        "llms/module",

        -- Desktop environment — niri only on the laptop.
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
