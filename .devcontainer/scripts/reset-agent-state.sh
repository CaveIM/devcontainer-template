#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
This reset removes only this Compose project's named volumes for:
  - Codex authentication, configuration, and history
  - Claude Code authentication, configuration, and history
  - OpenCode authentication, configuration, and history
  - GitHub CLI authentication and configuration

It does not delete the checked-out repository. It signs all tools out and the
deleted container-local history cannot be recovered unless Docker volume data
was backed up.
EOF

read -r -p 'Type DELETE AGENT STATE to print the host-side reset command: ' confirmation
if [[ "${confirmation}" != 'DELETE AGENT STATE' ]]; then
  printf 'Cancelled; nothing was changed.\n'
  exit 0
fi

project_name="${COMPOSE_PROJECT_NAME:-<project-name>}"
printf '\nRun this from the repository on the host (Docker is intentionally unavailable here):\n'
if [[ "${project_name}" == '<project-name>' ]]; then
  printf '  make destroy\n'
else
  printf '  docker compose --project-name %q --project-directory .devcontainer -f .devcontainer/compose.yml down --volumes\n' "${project_name}"
fi
