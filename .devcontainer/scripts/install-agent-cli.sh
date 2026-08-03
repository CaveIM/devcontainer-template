#!/usr/bin/env bash
set -euo pipefail

tool="${1:?tool is required}"
enabled="${2:?install toggle is required}"
version="${3:?version is required}"

case "${enabled}" in
  true)
    ;;
  false)
    printf 'Skipping %s installation.\n' "${tool}"
    exit 0
    ;;
  *)
    printf 'Invalid install toggle for %s: expected true or false.\n' "${tool}" >&2
    exit 2
    ;;
esac

if [[ ! "${version}" =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]]; then
  printf 'Invalid %s version selector: %s\n' "${tool}" "${version}" >&2
  exit 2
fi

case "${tool}" in
  codex) package='@openai/codex' ;;
  claude) package='@anthropic-ai/claude-code' ;;
  opencode)
    case "$(uname -m)" in
      x86_64|amd64) package='opencode-linux-x64' ;;
      aarch64|arm64) package='opencode-linux-arm64' ;;
      *) printf 'OpenCode has no configured official artifact for architecture: %s\n' "$(uname -m)" >&2; exit 1 ;;
    esac
    ;;
  *) printf 'Unknown tool: %s\n' "${tool}" >&2; exit 2 ;;
esac

printf 'Installing %s from the official npm package (%s@%s).\n' "${tool}" "${package}" "${version}"
npm install --global --omit=dev "${package}@${version}"
if [[ "${tool}" == opencode ]]; then
  platform_binary="${NPM_CONFIG_PREFIX:-/opt/agent-tools}/lib/node_modules/${package}/bin/opencode"
  [[ -x "${platform_binary}" ]] || { printf 'Official OpenCode binary was not found at %s\n' "${platform_binary}" >&2; exit 1; }
  ln -sfn "${platform_binary}" "${NPM_CONFIG_PREFIX:-/opt/agent-tools}/bin/opencode"
fi
command -v "${tool}" >/dev/null
"${tool}" --version
