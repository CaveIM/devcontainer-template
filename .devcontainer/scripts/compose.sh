#!/usr/bin/env bash
set -euo pipefail

action="${1:?usage: compose.sh <build|start|stop|destroy|verify|config>}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
repo_name="$(basename "${repo_root}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/^-*//; s/-*$//')"
if command -v sha256sum >/dev/null 2>&1; then
  path_hash="$(printf '%s' "${repo_root}" | sha256sum | cut -c1-10)"
else
  path_hash="$(printf '%s' "${repo_root}" | shasum -a 256 | cut -c1-10)"
fi
project_name="${COMPOSE_PROJECT_NAME:-${repo_name}-${path_hash}}"
compose=(docker compose --project-name "${project_name}" --project-directory "${repo_root}/.devcontainer" -f "${repo_root}/.devcontainer/compose.yml")

case "${action}" in
  build) "${compose[@]}" build ;;
  start)
    "${compose[@]}" up -d
    "${compose[@]}" exec -T workspace .devcontainer/scripts/post-create.sh
    ;;
  stop) "${compose[@]}" stop ;;
  verify) "${compose[@]}" exec -T workspace .devcontainer/scripts/verify.sh ;;
  config) "${compose[@]}" config ;;
  destroy)
    printf 'WARNING: this deletes project-scoped agent and GitHub CLI authentication, configuration, and history.\n'
    read -r -p 'Type DELETE AGENT STATE to continue: ' confirmation
    [[ "${confirmation}" == 'DELETE AGENT STATE' ]] || { printf 'Cancelled.\n'; exit 0; }
    "${compose[@]}" down --volumes
    ;;
  *) printf 'Unknown action: %s\n' "${action}" >&2; exit 2 ;;
esac
