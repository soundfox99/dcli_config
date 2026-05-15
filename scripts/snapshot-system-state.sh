#!/usr/bin/env bash
# Capture mutable state from the running system back into the repo:
#   - Chromium / Brave / Firefox extension IDs
#   - Chromium / Brave bookmarks (converted to Netscape HTML)
#   - VSCodium extensions
#
# Idempotent — re-running with no changes is a no-op. The repo's HEAD must be
# unlocked by git-crypt for bookmark writes to make sense (will still write
# correctly if locked, but commit will refuse to publish plaintext via
# safe-commit-push.sh).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ─── Browser extensions ─────────────────────────────────────────────────────
capture_chromium_ext() {
    local browser_dir="$1"
    local out_file="$2"
    local ext_dir="${browser_dir}/Default/Extensions"
    [ -d "${ext_dir}" ] || return 0
    {
        echo "# Captured from ${ext_dir} at $(date -Iseconds)"
        echo "# Find names: https://chrome.google.com/webstore/detail/<ID>"
        ls "${ext_dir}" | sort
    } > "${out_file}"
    echo "  ${out_file##*/}: $(ls "${ext_dir}" | wc -l) extension(s)"
}

capture_firefox_ext() {
    local out_file="$1"
    local profile_dir
    profile_dir=$(ls -d "${HOME}/.mozilla/firefox/"*.default* 2>/dev/null | head -n1 || true)
    [ -n "${profile_dir}" ] && [ -d "${profile_dir}/extensions" ] || return 0
    {
        echo "# Captured from ${profile_dir}/extensions at $(date -Iseconds)"
        echo "# Find names on addons.mozilla.org by GUID"
        ls "${profile_dir}/extensions" | sed 's/\.xpi$//' | sort
    } > "${out_file}"
    echo "  ${out_file##*/}: $(ls "${profile_dir}/extensions" | wc -l) extension(s)"
}

echo "[snapshot] Capturing browser extensions..."
capture_chromium_ext "${HOME}/.config/chromium" \
    "${REPO_ROOT}/modules/browsers/data/chromium-extensions.txt"
capture_chromium_ext "${HOME}/.config/BraveSoftware/Brave-Browser" \
    "${REPO_ROOT}/modules/browsers/data/brave-extensions.txt"
capture_firefox_ext "${REPO_ROOT}/modules/browsers/data/firefox-extensions.txt"

# ─── Browser bookmarks (Chromium/Brave JSON → Netscape HTML) ────────────────
chromium_bookmarks_to_html() {
    local src="$1"
    local out="$2"
    [ -f "${src}" ] || return 0
    python3 - "${src}" > "${out}" <<'PY'
import json, sys, html
data = json.load(open(sys.argv[1]))

def walk(node, depth=1):
    pad = "  " * depth
    out = []
    t = node.get("type")
    name = html.escape(node.get("name", ""))
    if t == "url":
        url = html.escape(node["url"], quote=True)
        out.append(f'{pad}<DT><A HREF="{url}">{name}</A>')
    elif t == "folder":
        out.append(f'{pad}<DT><H3>{name}</H3>')
        out.append(f'{pad}<DL><p>')
        for child in node.get("children", []):
            out.extend(walk(child, depth + 1))
        out.append(f'{pad}</DL><p>')
    return out

print('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
print('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
print('<TITLE>Bookmarks</TITLE>')
print('<H1>Bookmarks</H1>')
print('<DL><p>')
for key in ("bookmark_bar", "other", "synced"):
    root = data.get("roots", {}).get(key)
    if root:
        for line in walk(root):
            print(line)
print('</DL><p>')
PY
    echo "  ${out##*/}: bookmarks rendered"
}

echo "[snapshot] Capturing bookmarks..."
chromium_bookmarks_to_html "${HOME}/.config/chromium/Default/Bookmarks" \
    "${REPO_ROOT}/modules/browsers/data/chromium-bookmarks.html"
chromium_bookmarks_to_html "${HOME}/.config/BraveSoftware/Brave-Browser/Default/Bookmarks" \
    "${REPO_ROOT}/modules/browsers/data/brave-bookmarks.html"
# Firefox: requires reading places.sqlite, skipped — export manually via
# Bookmarks → Manage → Export to HTML when you actually use Firefox.

# ─── VSCodium extensions ────────────────────────────────────────────────────
# Replace-style (matches browser snapshot): the running VSCodium is the source
# of truth. Uninstalling in the IDE then `dcli-push` removes the ID from the
# repo on next sync. If you want to declare an ID without installing yet, add
# it to the file AND run `dcli sync` before the next `dcli-push`.
if command -v codium >/dev/null 2>&1; then
    out="${REPO_ROOT}/modules/editors/vscodium/data/extensions.txt"
    installed=$(codium --list-extensions 2>/dev/null | sort -u || true)
    {
        echo "# VSCodium extensions captured from \`codium --list-extensions\`."
        echo "# Last snapshot: $(date -Iseconds)"
        echo "# This file is overwritten on every dcli-push — edit the running"
        echo "# VSCodium (install/uninstall), or add an ID below and run"
        echo "# 'dcli sync' to install it before the next push."
        echo
        echo "${installed}"
    } > "${out}"
    echo "  vscodium: $(echo "${installed}" | grep -c .) extension(s)"
fi

echo "[snapshot] Done."
