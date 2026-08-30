# supernote

Two capabilities that share one hook, both aimed at the Obsidian vault in
`~/Documents/ObsidianVaults`.

## 1. `.note` → markdown

Supernote `.note` files are a proprietary binary format. The Obsidian
**Supernote (Unofficial)** plugin renders them natively, so viewing already
works — but Obsidian's **search, graph and Autolink cannot see inside a
`.note`**. Everything handwritten is invisible to them.

`supernotelib` extracts the device's own handwriting-recognition text.
`supernote-note2md` reads `.note` files from `Supernote/Backup/` and writes the
corresponding `.md` into `Supernote/Markdown/`, mirroring the folder structure.
The two trees are kept separate so no folder holds `Foo.note` and `Foo.md` side
by side — that makes Obsidian's shortest-path link resolution ambiguous and
clutters the file explorer. `Supernote/Backup/` is the untouched device clone;
`Supernote/Markdown/` is entirely generated, rewritten on change with orphans
pruned, so it must not be hand-edited.

Each `.md` carries two layers: the recognised text, and **a locally rendered
PNG of every page embedded inline**. The images are what make an equation-heavy
note readable at all — the device recogniser emits one flat line of plain text,
so `10^-19` arrives as `/o-19` and `v` is read as a tick. That is a format
limit, not a tuning problem, so text-bearing notes get a callout telling the
reader to trust the images over the text for maths. Rendering is local
(`supernote-tool`); no OCR service is involved.

Pages are reused when they are newer than their `.note`, so a full `--force`
rebuild costs ~23 s instead of re-rendering 294 images.

Each note also gets **kebab-case tags derived from its device folder** and is
listed in a generated `Supernote Index.md`. Both are deterministic — unlike
title matching, a tag cannot produce a false link. The converter also emits a `## Related` section with two kinds of link:

* **mentions** — another note's title appears in this note's text. Both sides are
  normalised to lowercase alphanumerics first, since titles are filenames
  (`ModularRelayCard`) while the text spells them out (`Modular Relay Card`).
* **shared vocabulary** — TF-IDF over every `.md` in the vault, so a Supernote
  lecture links to a `Work/NAI/` task when they share distinctive terms. Cross
  folder by design; that is the point of a vault.

Title matching alone reaches 2 links across the whole corpus — handwritten notes
do not cite each other by filename. Keyword similarity reaches 49 across 17
notes. Three thresholds keep that from becoming noise, all set by measuring the
corpus rather than guessing:

| Guard | Value | Why |
| --- | --- | --- |
| `df >= 2` | idf floor | OCR garbage (`deoripticn`) appears once and would otherwise score as maximally distinctive |
| `df <= 30%` | idf ceiling | terms common enough to connect everything to everything |
| `MIN_DOC_TERMS = 15` | per note | a thin note gives a tiny denominator and a spurious score — two notes with *no* recognised text scored 1.74 against each other |
| `MIN_SCORE = 0.50` | per pair | measured noise sits at 0.27–0.46; without a floor every note got 5 links whether good ones existed or not, giving a hiking list five Leetcode links |

The **Note Linker** plugin does title matching only, so it surfaces the same two
mentions and none of the keyword links. The Autolink plugin cannot do either,
being an as-you-type `EditorSuggest` with no batch mode.

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
`ObsidianVaults/.obsidian/plugins/*/data.json`:

| Plugin | Key setting |
| --- | --- |
| `supernote` | `syncFolder: "Supernote/Backup"`; `directConnectIP` blank until the device's IP is filled in |
| `autolink` | `mode: "autonomous"`, `minWordLength: 4` |
| `obsidian-languagetool-plugin` | `urlMode: "custom"`, `serverUrl: "http://localhost:8081"` |

`ObsidianVault/Supernote Clone.md` documents the USB clone procedure.

## USB clones

`android-file-transfer` provides `aft-mtp-cli`, which pulls the whole device in
one MTP session:

```bash
cd ~/Documents/ObsidianVaults/Supernote/Backup
aft-mtp-cli -b "get -r /"
```

libmtp's own CLI can only fetch one file at a time by numeric ID, which is why
a packaged tool is preferable to scripting `mtp-getfile` in a loop.

MTP allows one claimant at a time, and a file manager's daemon (`kiod6` for
Dolphin, `gvfsd-mtp` for Nautilus) holds the device even after its window
closes. `fuser -v /dev/bus/usb/<bus>/<dev>` names the holder.

## Ports

LanguageTool binds `127.0.0.1:8081`. See `PORTS.md` at the repo root for the
full local allocation table.

## Gotcha: systemctl --user inside a hook

`dcli sync` runs under sudo, and `sudo -u` does **not** set
`XDG_RUNTIME_DIR` or `DBUS_SESSION_BUS_ADDRESS`. Without them `systemctl --user`
fails with *"Failed to connect to user scope bus"* and takes the whole sync down
with it. The hook reconstructs both from the target uid, and skips unit
activation with instructions — rather than failing — when no session bus exists
(a tty-only sync, or a chroot).
