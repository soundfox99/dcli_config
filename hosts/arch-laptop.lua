-- Host configuration for arch-laptop (Dell Latitude 5410, Intel CPU + iGPU)
-- Subset of arch-desktop: excludes games and comfyui. KDE Plasma is the
-- current session; niri is installed alongside it and selectable from SDDM.
--
-- No wifi-rtl8821ce here: this machine has Intel CNVi wireless (8086:02f0),
-- not the Realtek RTL8821CE that module tunes.

return {
    host = "arch-laptop",
    description = "Personal Laptop",

    enabled_modules = {
        -- Conditional / system-wide
        "hardware",
        "system-packages-arch-laptop",

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
        "editors/obsidian",
        "git-config",

        -- Programming languages
        "programming-languages/rust",
        "programming-languages/go",
        "programming-languages/python",
        "programming-languages/nodejs",
        "programming-languages/ruby",

        -- Apps — Zen is the only browser on the laptop, so browsers/module
        -- (firefox + chromium + brave) is deliberately not enabled here.
        "browsers/zen",
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

        -- Desktop environments — both install side-by-side; SDDM picks the
        -- session at login. KDE Plasma is the current daily-driver here.
        "desktop-environments/kde-plasma",
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
            "tlp",
            "acpid",
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
        default_apps = {
            scope = "user",
            browser = "zen.desktop",
            text_editor = "vscodium",
            file_manager = "dolphin",
            video_player = "mpv",
            audio_player = "mpv",
            image_viewer = "dolphin",
            pdf_viewer = "zen.desktop",
            meme_types = {},
        },
    },
}
