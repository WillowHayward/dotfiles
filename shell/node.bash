# Node for launcher-started editors and AI Bash commands.
export PATH="${FNM_DIR:-$HOME/.local/share/fnm}:$PATH"
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash --version-file-strategy recursive)"
    fnm use --silent-if-unchanged >/dev/null
fi
