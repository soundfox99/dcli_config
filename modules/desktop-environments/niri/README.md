# niri

Scrollable-tiling Wayland compositor, with noctalia-shell providing the bar,
launcher, notifications and lockscreen.

## Finding the bindings

**Press `Mod+Shift+/`** for niri's built-in hotkey overlay. It reads the live
config, so it can never drift out of date the way this file can — that's what
the `hotkey-overlay-title="..."` annotations in `binds.kdl` are for.

This README is the searchable version, plus the reasoning behind the local
deviations from stock niri.

`Mod` is Super. `/usr/share/doc/niri/default-config.kdl` is the annotated
upstream config, useful for finding action names.

## Which files are actually active

| File | Status |
| --- | --- |
| `binds.kdl` | Active — the bulk of the bindings |
| `shell-switcher-binds.kdl` | Active — noctalia launcher + emoji picker |

`~/.config/niri` is a symlink to this directory, so editing either path edits
the same file. niri hot-reloads on save.

Because `shell-switcher-binds.kdl` is included last, it wins any chord it shares
with `binds.kdl`.

## Applications

| Chord | Action |
| --- | --- |
| `Mod+Return` / `Mod+T` | kitty |
| `Mod+Ctrl+Return` | kitty, floating |
| `Mod+Ctrl+Shift+Return` | `dcli sync` in a floating kitty |
| `Mod+Space` | noctalia launcher |
| `Mod+E` | noctalia emoji picker |
| `Mod+B` | Zen Browser |
| `Mod+F` | nautilus |
| `Mod+Y` | yazi |
| `Mod+D` | Discord |
| `Mod+Shift+N` | Obsidian |
| `Mod+Shift+Z` | VSCodium |
| `Mod+Shift+A` | btop |
| `Super+Alt+L` | Lock screen |
| `Super+Alt+S` | Toggle orca screen reader |

## Windows and columns

| Chord | Action |
| --- | --- |
| `Mod+H/J/K/L` or arrows | Focus left / down / up / right |
| `Mod+Ctrl+H/J/K/L` | Move column / window |
| `Mod+Shift+←→` | Move column left / right |
| `Mod+Shift+H/J/K/L` | Focus monitor |
| `Mod+Shift+Ctrl+H/J/K/L` | Move column to monitor |
| `Mod+Home` / `Mod+End` | First / last column |
| `Mod+Q` | Close window |
| `Mod+X` | Overview |
| `Mod+W` | Toggle floating |
| `Mod+Shift+W` | Focus floating ↔ tiling |
| `Mod+V` | Tabbed column display |
| `Mod+BracketLeft/Right` | Consume or expel window |
| `Mod+Comma` / `Mod+Period` | Consume into / expel from column |

## Sizing

| Chord | Action |
| --- | --- |
| `Mod+R` / `Mod+Shift+R` | Cycle column width / window height |
| `Mod+Ctrl+R` | Reset window height |
| `Mod+Minus` / `Mod+Equal` | Column width ∓10% |
| `Mod+Shift+Minus/Equal` | Window height ∓10% |
| `Mod+Ctrl+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen |
| `Mod+M` | Maximize window to edges |
| `Mod+C` / `Mod+Alt+C` | Center column / all visible columns |

## Workspaces

| Chord | Action |
| --- | --- |
| `Mod+1`…`9` | Focus workspace N |
| `Mod+Ctrl+1`…`9` | Move column to workspace N |
| `Mod+U` / `Mod+I` | Focus workspace down / up |
| `Mod+Ctrl+U` / `Mod+Ctrl+I` | Move column to workspace down / up |
| `Mod+Ctrl+Alt+J/K` | Move **window** to workspace down / up |
| `Mod+Shift+U` / `Mod+Shift+I` | Reorder workspace |
| `Mod+WheelUp/Down` | Scroll workspaces |

## System

| Chord | Action |
| --- | --- |
| `Mod+Shift+S` | Screenshot (interactive) |
| `Ctrl+Print` / `Alt+Print` | Screenshot screen / window |
| `Mod+Escape` | Toggle shortcut inhibit (lets an app grab all keys) |
| `Mod+Shift+P` | Power off monitors |
| `Mod+Shift+E` / `Ctrl+Alt+Delete` | Quit niri |
| `Mod+Shift+/` | Hotkey overlay |

Media and brightness keys (`XF86Audio*`, `XF86MonBrightness*`) are bound with
`allow-when-locked=true`. Audio goes through `wpctl`, transport controls through
`playerctl`, backlight through `brightnessctl`.

## Deviations from stock niri

Roughly 100 of the bindings are unmodified upstream defaults. The intentional
changes:

| Chord | Stock | Here |
| --- | --- | --- |
| `Mod+W` / `Mod+V` | tabbed / floating | **swapped** |
| `Mod+Shift+←→` | focus-monitor | move-column |
| `Mod+Ctrl+←→` | move-column | focus-monitor |
| `Mod+F` | maximize-column | nautilus |
| `Mod+Ctrl+F` | expand-column-to-available-width | maximize-column |
| `Mod+T` | alacritty | kitty |
| `Mod+D` | fuzzel | Discord |
| `Mod+Ctrl+C` | center-visible-columns | OpenCode (moved to `Mod+Alt+C`) |
| `Mod+X` | — | overview (stock is `Mod+O`) |

Stock binds dropped because an equivalent exists here: `Mod+O` (→ `Mod+X`),
`Mod+Page_Up/Down` (→ `Mod+U/I`), `Mod+Shift+V` (→ `Mod+Shift+W`), `Mod+Ctrl+Up`
(→ `Mod+Ctrl+K`), `Mod+Ctrl+Shift+R` (→ `Mod+Shift+R`).

## Notes

**No fuzzel.** noctalia already provides the launcher (`Mod+Space`) and emoji
picker (`Mod+E`), themed with the rest of the shell. Stock niri binds fuzzel to
`Mod+D`, which is Discord here, so it had no binding at all — the package was
dropped from `module.lua` rather than given a second, differently-themed
launcher. It is still installed on this host; `dcli remove fuzzel` to actually
uninstall, since auto-prune is disabled.

**The locker is noctalia, not swaylock.** Both the 30-minute idle lock
(`startup.kdl`, via swayidle) and `Super+Alt+L` call
`qs -c noctalia-shell ipc call lockScreen lock`. One locker, not two.

**noctalia's IPC target names are case-sensitive and fail silently.** The target
is `lockScreen`, camelCase. Anything else — `lockscreen` included — prints
`Target not found.` and exits **0**, so a wrong name looks like success and the
lock simply never fires. Both call sites had `lockscreen` and neither worked,
which meant idle auto-lock was dead too. `qs -c noctalia-shell ipc show` lists
every target and function; check spelling there before binding a new one.

There is also a `sessionMenu` target with `lock()` and `lockAndSuspend()`. That
one goes through the session menu; `lockScreen lock` locks directly.

**`Ctrl+Shift+S` is deliberately unbound**, left to Zen's full-page screenshot.
It used to spawn `shell-switch` — a switcher between noctalia and
DankMaterialShell — but neither `shell-switch` nor `dms` was ever installed, and
noctalia is the settled choice, so the bind, the dormant `dms/` config and the
switcher's commented-out leftovers were all removed. niri's own screenshots are
unaffected: `Mod+Shift+S`, `Ctrl+Print`, `Alt+Print`.

**Bindings pointing at software that isn't installed:** `Mod+Alt+F` (felix),
`Mod+G` (Telegram), `Mod+Shift+B` (qutebrowser), `Mod+S` (steam — deliberately
excluded on the laptop host), `Mod+Ctrl+C` (opencode), `Mod+Ctrl+P`
(perplexity), `Mod+Shift+O` (OBS, not declared anywhere), `Super+Alt+S` (orca).
They fail silently.

**Zen Browser's shortcuts live in `modules/browsers/zen/README.md`.** They sit
on `Ctrl+Alt+*` specifically to avoid niri, which claims `Mod` outright and
grabs chords before any application sees them.
