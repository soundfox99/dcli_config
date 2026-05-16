#
# ~/.bashrc
#

eval "$(starship init bash)"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
# cargo: source rustup's env helper if present, otherwise fall back to
# adding ~/.cargo/bin to PATH directly (pacman's rustup doesn't ship the
# env file; rustup-init creates it).
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
elif [ -d "$HOME/.cargo/bin" ]; then
    case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH";; esac
fi

# fnm — Node.js version manager (user-space). Shim node/npm/npx to whatever
# version fnm has active so the system nodejs-lts-jod (used by tools like
# bitwarden-cli) and your dev Node can coexist.
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi

# ── arch-config helpers ────────────────────────────────────────────────────
# Three composable steps. `dcli sync` stays vanilla so it doesn't trample
# work-in-progress edits with a forced rebase.
#
#   dcli-pull   git pull --rebase --autostash (catch up from remote)
#   dcli-push   snapshot system state → safe-commit-push (encrypted-only check)
#   dcli-full   dcli-pull && dcli sync && dcli-push  (full cycle)
#
# Typical flows:
#   - editing modules locally:        dcli sync                 # vanilla
#   - daily on a passive machine:     dcli-full
#   - "I just added a vscodium ext":  dcli-push
#   - "remote has new modules":       dcli-pull && dcli sync
alias dcli-pull='git -C ~/.config/arch-config pull --rebase --autostash'
alias dcli-push='~/.config/arch-config/scripts/snapshot-system-state.sh && ~/.config/arch-config/scripts/safe-commit-push.sh'
# update --devel refreshes pacman + AUR (rebuilding -git pkgs from latest commits);
# avoids stale-DB 404s on subsequent dcli sync.
alias dcli-full='dcli-pull && dcli update --devel && dcli sync && dcli-push'
# dcli theming
[ -f ~/.dcli/environment ] && source ~/.dcli/environment

