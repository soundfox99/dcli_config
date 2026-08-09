return {
    description = "System fonts: nerd fonts, font-awesome, CJK, fallbacks",
    packages = {
        "ttf-cascadia-code-nerd",
        -- "ttf-font-awesome" is only a provides, satisfied by either
        -- otf-font-awesome or woff2-font-awesome. Name the real package:
        -- woff2 ships web fonts, so Waybar/noctalia glyphs need the OTF build.
        "otf-font-awesome",
        "otf-ipafont",
        "noto-fonts",
        "noto-fonts-cjk",
        "noto-fonts-emoji",
        "ttf-dejavu",
        "ttf-liberation",
        "ttf-bitstream-vera",
        "gnu-free-fonts",
        "ttf-ms-fonts",
    },
}
