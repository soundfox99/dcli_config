# Zen Browser

Installs `zen-browser-bin` and deploys a keyboard-shortcut scheme built around
keeping both hands on the keyboard — workspace switching, split view and tab
handling all reachable without the mouse.

## Files

| Path | Role |
| --- | --- |
| `module.lua` | Package + hook declaration |
| `data/keyboard-shortcuts.json` | The bindings (edit here, not in the profile) |
| `scripts/install-zen-shortcuts.sh` | Merges the bindings into every Zen profile |

## Bindings

Everything sits on `Ctrl+Alt`. Super/Meta is deliberately unused — niri owns
`Mod` as its compositor key and swallows those chords before Zen sees them.

### Workspaces

| Chord | Action |
| --- | --- |
| `Ctrl+Alt+1` … `Ctrl+Alt+9` | Jump to workspace 1–9 |
| `Ctrl+Alt+0` | Jump to workspace 10 |
| `Ctrl+Alt+N` | New workspace |
| `Ctrl+Alt+→` / `Ctrl+Alt+←` | Next / previous workspace |

### Split view

| Chord | Action |
| --- | --- |
| `Ctrl+Alt+V` | Split vertical |
| `Ctrl+Alt+H` | Split horizontal |
| `Ctrl+Alt+G` | Split grid |
| `Ctrl+Alt+A` | Add current tab to split |
| `Ctrl+Alt+E` | Separate tab out of split |
| `Ctrl+Alt+U` | Unsplit |

### Tabs, sidebar, page

| Chord | Action |
| --- | --- |
| `Ctrl+Alt+D` | Duplicate tab |
| `Ctrl+Alt+Z` | Toggle sidebar |
| `Ctrl+Alt+B` | Show sidebar in compact mode |
| `Ctrl+Alt+C` | Copy URL as markdown *(Zen default)* |
| `Ctrl+Alt+R` | Reader mode *(see note below)* |
| `Ctrl+Alt+S` | Save page *(Zen default)* |

Zen's own defaults worth knowing, left as shipped: `Ctrl+S` toggles compact
mode (not save — save moved to `Ctrl+Alt+S`), `Ctrl+Shift+D` pins a tab,
`Alt+1`…`Alt+9` select tabs, `Ctrl+O` expands Glance.

**`Ctrl+Shift+S` — full-page screenshot.** Firefox's capture tool, and the one
thing an OS screenshot cannot do: it grabs the entire scrollable page, not just
the viewport. It was unreachable until niri's `shell-switch` bind was removed —
the compositor grabbed the chord first. niri's own screenshots are separate and
unaffected: `Mod+Shift+S`, `Ctrl+Print`, `Alt+Print`.

## Editing the bindings

Edit `data/keyboard-shortcuts.json`, close Zen, then re-run the hook:

```sh
./scripts/install-zen-shortcuts.sh
```

Chord syntax is `Ctrl+Alt+K`, key last. `Ctrl` maps to Zen's `accel` modifier
(Ctrl on Linux). `VK_*` names bind a keycode rather than a character, e.g.
`Ctrl+Alt+VK_RIGHT`.

The file holds **only the overrides**, not all ~128 shortcuts. A Zen version
bump regenerates its own defaults and the hook reapplies just these on top,
rather than a stale pinned copy of the whole table fighting the new defaults.
Removing an id from the file hands that shortcut back to Zen's default.

The script writes a `.bak` beside each profile's file, and refuses to write if
an override would collide with another enabled shortcut.

## Notes

**`Ctrl+Alt+U` used to do nothing useful.** Zen ships it bound to
`viewOpenTabsSidebarKb`, but `sidebar.revamp` is `false` **and `locked`** in
Zen's default prefs, so `viewOpenTabsSidebar` is never registered as a panel.
The chord fell through to toggling the sidebar onto whatever panel was last
open, which read as "it opens bookmarks". Because the pref is locked, no
`about:config` or `user.js` change can revive it — so the id is retired and the
chord reassigned to `zen-split-view-unsplit`.

**`Ctrl+Alt+R` is left `disabled` in the shortcut table on purpose.** Reader
mode already fires from Firefox's inherited keyset, so enabling Zen's entry too
risks toggling twice and cancelling itself out.

**Three conflicts are Zen's own defaults** and are reported but left alone:
`Ctrl+Shift+W`, `Ctrl+Shift+Z` and `Ctrl+Shift+K` each have a browser action
and a devtools action on the same chord.

**Why not edit the profile directly:** Zen holds the shortcut table in memory
and rewrites `zen-keyboard-shortcuts.json` on change and on exit, so edits made
while it is running are silently discarded. The hook enforces this by refusing
to run when a `zen`/`zen-bin` process is alive.

**The hook de-escalates to `$SUDO_USER`** before reading `$HOME`, since profiles
are user-owned and `dcli sync` runs under sudo. See the root README's hooks
section.
