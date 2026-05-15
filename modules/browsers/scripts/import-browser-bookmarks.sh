#!/usr/bin/env bash
# Import Chromium/Brave bookmarks from the repo's *-bookmarks.html exports
# by writing the browser's internal Bookmarks JSON directly.
#
# Modes:
#   (no args)   auto: only import when the browser's Bookmarks file has
#               zero user URLs (i.e. a fresh / default profile). Safe to run
#               on every sync.
#   --force     always overwrite, even if the browser already has bookmarks.
#               Use this when you want the repo to be the source of truth.
#
# Both browsers must be CLOSED while this runs — Chromium/Brave overwrite the
# file on shutdown, so a live import would be clobbered.
#
# Firefox is intentionally not handled here (uses places.sqlite, no clean
# automated import; use the Library → Import HTML dialog).

set -euo pipefail

MODULE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORCE=0
case "${1:-}" in
    --force) FORCE=1 ;;
    --help|-h)
        sed -n '2,16p' "$0"; exit 0 ;;
    "") ;;
    *) echo "Unknown arg: $1 (use --force or no args)" >&2; exit 2 ;;
esac

count_existing_bookmarks() {
    python3 - "$1" <<'PY' 2>/dev/null || echo 0
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    print(0); sys.exit(0)
total = 0
def walk(n):
    global total
    if n.get("type") == "url":
        total += 1
    for c in n.get("children", []) or []:
        walk(c)
for k in ("bookmark_bar", "other", "synced"):
    if k in data.get("roots", {}):
        walk(data["roots"][k])
print(total)
PY
}

html_to_chromium_json() {
    python3 - "$1" <<'PY'
import sys, json
from html.parser import HTMLParser

class P(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = [{"type": "folder", "name": "ROOT", "children": []}]
        self.href = None
        self.in_a = False
        self.in_h3 = False
        self.buf = []
    def handle_starttag(self, tag, attrs):
        d = dict(attrs)
        if tag == "h3":
            self.in_h3 = True; self.buf = []
        elif tag == "a":
            self.in_a = True; self.href = d.get("href", ""); self.buf = []
    def handle_endtag(self, tag):
        text = "".join(self.buf).strip()
        if tag == "h3" and self.in_h3:
            folder = {"type": "folder", "name": text, "children": []}
            self.stack[-1]["children"].append(folder)
            self.stack.append(folder)
            self.in_h3 = False
        elif tag == "dl":
            if len(self.stack) > 1:
                self.stack.pop()
        elif tag == "a" and self.in_a:
            self.stack[-1]["children"].append(
                {"type": "url", "name": text, "url": self.href}
            )
            self.in_a = False
    def handle_data(self, data):
        if self.in_h3 or self.in_a:
            self.buf.append(data)

p = P(); p.feed(open(sys.argv[1]).read())
# Top-level folders from our renderer: 1st=bookmark_bar, 2nd=other, 3rd=synced
roots_order = ["bookmark_bar", "other", "synced"]
names = {"bookmark_bar": "Bookmarks bar",
         "other": "Other bookmarks",
         "synced": "Mobile bookmarks"}
top = p.stack[0]["children"]
roots = {}
for i, key in enumerate(roots_order):
    children = top[i].get("children", []) if i < len(top) and top[i].get("type") == "folder" else []
    roots[key] = {"type": "folder", "name": names[key], "children": children}
print(json.dumps({"checksum": "", "roots": roots, "version": 1}, indent=2))
PY
}

import_to_browser() {
    local label="$1"
    local profile_dir="$2"
    local html_file="$3"
    local bookmarks_file="${profile_dir}/Bookmarks"

    [ -d "${profile_dir}" ] || { echo "  ${label}: no profile at ${profile_dir} — skip"; return 0; }
    [ -f "${html_file}" ]   || { echo "  ${label}: no ${html_file##*/} in repo — skip"; return 0; }

    # Don't touch ciphertext (git-crypt locked)
    if head -c 9 "${html_file}" 2>/dev/null | grep -q GITCRYPT; then
        echo "  ${label}: bookmarks still encrypted — run 'git-crypt unlock' first"
        return 0
    fi

    # Safety: skip auto mode when the profile already has bookmarks
    if [ "${FORCE}" -ne 1 ] && [ -f "${bookmarks_file}" ]; then
        local existing
        existing=$(count_existing_bookmarks "${bookmarks_file}")
        if [ "${existing}" -gt 0 ]; then
            echo "  ${label}: ${existing} bookmark(s) already present — skip (use --force to overwrite)"
            return 0
        fi
    fi

    # Refuse if the browser is running — would just be clobbered on shutdown
    if pgrep -fx "${label}" >/dev/null 2>&1; then
        echo "  ${label}: browser is running. Close it and re-run." >&2
        return 0
    fi

    html_to_chromium_json "${html_file}" > "${bookmarks_file}.new"
    mv "${bookmarks_file}.new" "${bookmarks_file}"
    rm -f "${profile_dir}/Bookmarks.bak"
    echo "  ${label}: imported $(count_existing_bookmarks "${bookmarks_file}") bookmark(s)"
}

import_to_browser "chromium" \
    "${HOME}/.config/chromium/Default" \
    "${MODULE_ROOT}/data/chromium-bookmarks.html"

import_to_browser "brave" \
    "${HOME}/.config/BraveSoftware/Brave-Browser/Default" \
    "${MODULE_ROOT}/data/brave-bookmarks.html"
