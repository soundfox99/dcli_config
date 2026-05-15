#
# ~/.bashrc
#

eval "$(starship init bash)"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
. "$HOME/.cargo/env"

# fnm — Node.js version manager (user-space). Shim node/npm/npx to whatever
# version fnm has active so the system nodejs-lts-jod (used by tools like
# bitwarden-cli) and your dev Node can coexist.
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
fi
# dcli theming
[ -f ~/.dcli/environment ] && source ~/.dcli/environment

