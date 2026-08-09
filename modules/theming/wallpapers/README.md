# Wallpapers

Shallow-clones [`dharmx/walls`](https://github.com/dharmx/walls) into
`~/Pictures/Wallpapers` — roughly 1700 images across ~50 category folders
(`abstract`, `anime`, `gruvbox`, `nord`, `minimal`, `stalenhag`, …).

The images are **not** tracked in this repo. A config repo that otherwise holds
text has no business carrying a couple of gigabytes of JPEGs, so the collection
is fetched from its upstream remote instead.

## Behaviour

`scripts/install-wallpapers.sh` handles three cases and is safe to re-run:

| State of `~/Pictures/Wallpapers` | What happens |
| --- | --- |
| Already a git repo | `fetch --depth 1` + `checkout -f`, fast-forwarding to the current upstream snapshot |
| Exists, has files, no `.git` | Remote is **adopted in place** — nothing is deleted |
| Missing or empty | `git clone --depth 1 --single-branch` |

The adopt path exists because `git clone` refuses a non-empty target. Wiping
1700 existing images to re-download the same bytes would be the wrong trade, so
the script inits in place and lets `checkout -f` reconcile only the files that
differ. Local-only files survive.

## Why shallow

`--depth 1` and `--single-branch`. Upstream history is large and offers nothing
here — only the current snapshot of the images matters. Staying shallow also
keeps every subsequent `dcli sync` cheap rather than re-walking history.

## Changing the source

Edit `REPO_URL` / `BRANCH` at the top of the script. Pointing at a different
remote on a directory that is already a repo will need the old `origin` removed
first (`git -C ~/Pictures/Wallpapers remote remove origin`), since the update
path assumes `origin` is already correct.
