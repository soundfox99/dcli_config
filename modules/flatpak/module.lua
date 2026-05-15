return {
    description = "Flatpak runtime + apps that aren't packaged natively for Arch",
    -- Most apps on Arch are better installed via AUR/extra (faster, better
    -- hardware integration, no sandbox quirks). Reach for Flatpak only when:
    --   - the app isn't on AUR/extra at all
    --   - you specifically want sandboxing for that app
    --   - the flatpak release is materially newer than what's packaged
    --
    -- Add IDs from flathub.org with the `flatpak:` prefix:
    --   "flatpak:com.example.AppId",
    packages = {
        "flatpak",
    },
}
