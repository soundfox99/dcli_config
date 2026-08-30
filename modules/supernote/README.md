# supernote

Two capabilities that share one hook, both aimed at the Obsidian vault in
`~/Documents/ObsidianVaults/ObsidianVault`.

## 1. `.note` → markdown

Supernote `.note` files are a proprietary binary format. The Obsidian
**Supernote (Unofficial)** plugin renders them natively, so viewing already
works — but Obsidian's **search, graph and Autolink cannot see inside a
`.note`**. Everything handwritten is invisible to them.

`supernotelib` extracts the device's own handwriting-recognition text.
`supernote-note2md` writes a sibling `.md` per `.note` carrying that text plus
frontmatter and a link back to the original, which gives search and Autolink
something to work on. The `.note` files are never modified.

**Recognition is not universal.** `FILE_RECOGN_TYPE: 1` means recognition is
*enabled*, not that the device has *performed* it on every page. On the initial
run, 42 of 55 files yielded text; the other 13 got a stub saying so rather than
a silently empty note. Pages written with recognition off produce strokes only.

`supernote-note2md` is incremental — a `.note` older than its `.md` is skipped,
so a scheduled run with nothing to do takes ~30 ms. `--force` rebuilds all.

| Unit | Role |
| --- | --- |
| `supernote-note2md.timer` | 2 min after login, then every 15 min. `Persistent=true` catches up after sleep. |
| `supernote-note2md.service` | oneshot; `Nice=10` + idle IO so it never competes with the desktop |

`inotify` would be tighter than polling, but `inotify-tools` isn't installed and
systemd `.path` units don't recurse into subdirectories — which this tree needs.
A cheap timer beats a new dependency here.

## 2. LanguageTool, locally

The Obsidian **LanguageTool Integration** plugin defaults to
`api.languagetool.org`, meaning the text being edited leaves the machine. Given
this vault holds work notes and financial research, `languagetool.service` runs
the same engine on `127.0.0.1:8081` and the plugin points at it via
`urlMode: "custom"`.

LanguageTool is rule-based (POS tagging + a hand-written rule database), not a
language model. Nothing is generated; every flag traces to a rule.

Costs: ~390 MB installed, pulls `java-runtime-headless`, and the JVM is capped
at `-Xmx1g` in the unit so it cannot crowd the desktop. There is no offline mode
without the server — for LanguageTool, "offline" and "runs a server" are the
same setting.

## Hook

`scripts/install-supernote-tooling.sh` (`hook_behavior = "always"`, idempotent):

1. installs `supernotelib` via **uv**, not pacman — it isn't packaged for Arch,
   and a uv tool venv keeps it off the system python
2. installs `supernote-note2md` into `~/.local/bin`
3. `daemon-reload`, enables the timer, and enables `languagetool.service`
   **only if** `/usr/bin/languagetool-server` exists — enabling a unit with a
   missing `ExecStart` would just crashloop

It requires `programming-languages/python` for `uv`, which both hosts enable.

## Vault-side configuration

Plugin settings live in the vault, not here — `dcli` does not manage
`.obsidian/`. Configured in
`ObsidianVaults/ObsidianVault/.obsidian/plugins/*/data.json`:

| Plugin | Key setting |
| --- | --- |
| `supernote` | `syncFolder: "Supernote"`; `directConnectIP` blank until the device's IP is filled in |
| `autolink` | `mode: "autonomous"`, `minWordLength: 4` |
| `obsidian-languagetool-plugin` | `urlMode: "custom"`, `serverUrl: "http://localhost:8081"` |

`ObsidianVault/Supernote Clone.md` documents the USB clone procedure.

## USB clones

`android-file-transfer` provides `aft-mtp-cli`, which pulls the whole device in
one MTP session:

```bash
cd ~/Documents/ObsidianVaults/ObsidianVault/Supernote
aft-mtp-cli -b "get -r /"
```

libmtp's own CLI can only fetch one file at a time by numeric ID, which is why
a packaged tool is preferable to scripting `mtp-getfile` in a loop.

MTP allows one claimant at a time, and a file manager's daemon (`kiod6` for
Dolphin, `gvfsd-mtp` for Nautilus) holds the device even after its window
closes. `fuser -v /dev/bus/usb/<bus>/<dev>` names the holder.

## Gotcha: systemctl --user inside a hook

`dcli sync` runs under sudo, and `sudo -u` does **not** set
`XDG_RUNTIME_DIR` or `DBUS_SESSION_BUS_ADDRESS`. Without them `systemctl --user`
fails with *"Failed to connect to user scope bus"* and takes the whole sync down
with it. The hook reconstructs both from the target uid, and skips unit
activation with instructions — rather than failing — when no session bus exists
(a tty-only sync, or a chroot).
