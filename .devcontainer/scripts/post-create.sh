#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  printf 'post-create must run as the non-root vscode user.\n' >&2
  exit 1
fi

if [[ "$(id -un)" != vscode ]]; then
  printf 'Expected user vscode, found %s.\n' "$(id -un)" >&2
  exit 1
fi

install -d -m 0700 \
  "${CODEX_HOME:-/home/vscode/.codex}" \
  "${CLAUDE_CONFIG_DIR:-/home/vscode/.claude}" \
  "${GH_CONFIG_DIR:-/home/vscode/.config/gh}" \
  /home/vscode/.config/opencode \
  /home/vscode/.local/share/opencode \
  /home/vscode/.local/state/opencode

codex_config="${CODEX_HOME:-/home/vscode/.codex}/config.toml"
if [[ ! -e "${codex_config}" ]]; then
  cp /workspaces/workspace/.devcontainer/templates/codex-config.toml "${codex_config}"
  chmod 0600 "${codex_config}"
fi

claude_settings="${CLAUDE_CONFIG_DIR:-/home/vscode/.claude}/settings.json"
if [[ ! -e "${claude_settings}" ]]; then
  cp /workspaces/workspace/.devcontainer/templates/claude-settings.json "${claude_settings}"
  chmod 0600 "${claude_settings}"
fi

opencode_config=/home/vscode/.config/opencode/opencode.json
if [[ ! -e "${opencode_config}" && ! -e /home/vscode/.config/opencode/opencode.jsonc ]]; then
  cp /workspaces/workspace/.devcontainer/templates/opencode.json "${opencode_config}"
  chmod 0600 "${opencode_config}"
fi

printf 'AI agent devcontainer ready (user: %s).\n' "$(id -un)"
for tool in codex claude opencode gh; do
  if command -v "${tool}" >/dev/null 2>&1; then
    printf '%-10s ' "${tool}:"
    "${tool}" --version 2>&1 | head -n 1
  fi
done
printf '\nFirst use: run codex, claude, or opencode and follow that tool\x27s login flow.\n'
printf 'For GitHub access, run: gh auth login\n'
printf 'No authentication was started and no secret values were inspected.\n'
