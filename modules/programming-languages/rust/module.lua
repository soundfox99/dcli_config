return {
    description = "Rust toolchain via rustup (manages stable/nightly + components)",
    packages = {
        -- rustup conflicts with the standalone `rust` package; use one or the other.
        -- rust-analyzer and rust-src are installed as rustup components, not pacman pkgs.
        "rustup",
        "cargo-watch",
        -- Build/link/cache acceleration. Opt-in per-project via cargo config
        -- or RUSTC_WRAPPER=sccache; installed by default so they're ready.
        "mold",
        "cargo-binstall",
        "sccache",
    },
    post_install_hook = "scripts/rustup-default.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
