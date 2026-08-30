-- Supernote + offline writing tools.
--
-- Two related capabilities that share a hook:
--
--   1. Supernote .note handling. The Obsidian plugin renders .note files
--      natively, but Obsidian's search, graph and Autolink cannot see inside
--      them. supernotelib (installed per-user via uv, not pacman) extracts the
--      device's handwriting-recognition text, and a systemd timer regenerates a
--      sibling .md for each .note so that text is searchable and linkable.
--
--   2. LanguageTool as a local server. The Obsidian plugin defaults to
--      LanguageTool's public API, which means note text leaves the machine.
--      Pointing it at 127.0.0.1:8081 keeps grammar checking fully offline; the
--      packaged server pulls in java-runtime-headless (~390 MB installed).
return {
    description = "Supernote .note -> markdown pipeline and offline LanguageTool server",
    packages = {
        -- Rule-based grammar/spell server. Not an LLM; runs on loopback only.
        "languagetool",
        -- Recursive MTP pull in a single session: `aft-mtp-cli -b "get -r /"`.
        -- libmtp's own CLI can only fetch one file at a time by numeric ID.
        "android-file-transfer",
    },
    -- No dotfiles_sync: dcli symlinks whole directories, and ~/.config/systemd
    -- is a shared namespace no single module should own. The hook copies the
    -- units in as plain files instead.
    --
    -- Installs supernotelib into a uv-managed venv, drops the converter into
    -- ~/.local/bin, installs and enables the user units. Idempotent.
    post_install_hook = "scripts/install-supernote-tooling.sh",
    hook_behavior = "always",
    run_hooks_as_user = true,
}
