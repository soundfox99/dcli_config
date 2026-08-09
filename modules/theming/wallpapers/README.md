# Wallpapers

Fetches [`dharmx/walls`](https://github.com/dharmx/walls) into
`~/Pictures/Wallpapers` — roughly 1700 images, **3.3 GB**, across ~50 category
folders (`abstract`, `anime`, `gruvbox`, `nord`, `minimal`, `stalenhag`, …).

The images are **not** tracked in this repo. A config repo that otherwise holds
text has no business carrying 3.3 GB of JPEGs.

## Why a tarball and not git

A `git clone --depth 1` was tried first and failed: the pack passed 1.6 GB and
then died on a mid-transfer disconnect (`fetch-pack: unexpected disconnect`,
`fatal: early EOF`). **Git cannot resume a failed pack transfer** — a retry
starts from zero.

GitHub's `codeload` tarball is a single stream that `curl -C -` resumes across
runs, and it leaves no `.git` objects behind. For a wallpaper collection there's
nothing git buys: no history worth keeping, no local commits to preserve.

## Behaviour

`scripts/install-wallpapers.sh` resolves upstream HEAD with `git ls-remote`
(cheap — no objects transferred) and compares it to `.walls-version` in the
target:

| State | What happens |
| --- | --- |
| Stamp matches upstream | No-op |
| Directory has files, no stamp | **Adopted** — stamp written, nothing downloaded |
| Stamp differs, or empty directory | Download tarball, extract, write stamp |
| `git ls-remote` fails | Skip with exit 0, so a dead network can't fail the sync |

The adopt path matters because `hook_behavior = "always"` runs this on every
`dcli sync`. Pulling 3.3 GB to land bytes that are already on disk would be
absurd, so an unstamped-but-populated directory is assumed to be this
collection.

Extraction uses `--strip-components=1` to drop the `walls-<sha>/` wrapper.
Existing files are overwritten; local-only files survive.

## Forcing a refresh

```sh
WALLS_FORCE=1 ./scripts/install-wallpapers.sh
```

Overrides both the stamp check and the adopt path. Partial downloads live in
`~/Pictures/.walls-download` and resume on the next run, so an interrupted
3.3 GB fetch doesn't restart from zero.

## Changing the source

`REPO` and `BRANCH` at the top of the script. Delete `.walls-version` in the
target afterwards, or the stamp check will report the new source as up to date.
