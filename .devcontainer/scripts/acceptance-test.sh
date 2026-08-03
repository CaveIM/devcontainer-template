#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
compose_script="${repo_root}/.devcontainer/scripts/compose.sh"
repo_name="$(basename "${repo_root}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/^-*//; s/-*$//')"
if command -v sha256sum >/dev/null 2>&1; then
  path_hash="$(printf '%s' "${repo_root}" | sha256sum | cut -c1-10)"
else
  path_hash="$(printf '%s' "${repo_root}" | shasum -a 256 | cut -c1-10)"
fi
project_name="${COMPOSE_PROJECT_NAME:-${repo_name}-${path_hash}}"
compose=(docker compose --project-name "${project_name}" --project-directory "${repo_root}/.devcontainer" -f "${repo_root}/.devcontainer/compose.yml")

"${compose_script}" build
"${compose_script}" start
"${compose_script}" verify

container_id="$("${compose[@]}" ps -q workspace)"
[[ -n "${container_id}" ]]

[[ "$(docker inspect -f '{{.Config.User}}' "${container_id}")" == vscode ]]
[[ "$(docker inspect -f '{{.HostConfig.Privileged}}' "${container_id}")" == false ]]
[[ "$(docker inspect -f '{{.HostConfig.NetworkMode}}' "${container_id}")" != host ]]
[[ "$("${compose[@]}" exec -T workspace sudo -n id -u)" == 0 ]]

mount_lines="$(docker inspect -f '{{range .Mounts}}{{println .Type "|" .Destination "|" .Name "|" .Source}}{{end}}' "${container_id}")"
if grep -Eq '\| /var/run/docker.sock \||\| /run/docker.sock \|' <<<"${mount_lines}"; then
  printf 'Docker socket mount detected.\n' >&2
  exit 1
fi

bind_sources="$(awk -F ' \\| ' '$1 == "bind" {print $4}' <<<"${mount_lines}")"
if [[ "${bind_sources}" != "${repo_root}" && "${bind_sources}" != "/host_mnt${repo_root}" ]]; then
  printf 'Unexpected bind mounts:\n%s\n' "${bind_sources}" >&2
  exit 1
fi

for destination in /home/vscode/.codex /home/vscode/.claude /home/vscode/.local/share/opencode /home/vscode/.config/opencode /home/vscode/.local/state/opencode /home/vscode/.config/gh; do
  if ! awk -F ' \\| ' -v destination="${destination}" -v prefix="${project_name}_" \
    '$1 == "volume" && $2 == destination && index($3, prefix) == 1 {found = 1} END {exit !found}' <<<"${mount_lines}"; then
    printf 'Expected project-scoped volume mount missing at %s.\n' "${destination}" >&2
    exit 1
  fi
done

for marker in \
  /home/vscode/.codex/.persistence-marker \
  /home/vscode/.claude/.persistence-marker \
  /home/vscode/.local/share/opencode/.persistence-marker \
  /home/vscode/.config/opencode/.persistence-marker \
  /home/vscode/.local/state/opencode/.persistence-marker; do
  "${compose[@]}" exec -T workspace touch "${marker}"
done

"${compose[@]}" build
"${compose[@]}" up -d --force-recreate
"${compose[@]}" exec -T workspace .devcontainer/scripts/post-create.sh
for marker in \
  /home/vscode/.codex/.persistence-marker \
  /home/vscode/.claude/.persistence-marker \
  /home/vscode/.local/share/opencode/.persistence-marker \
  /home/vscode/.config/opencode/.persistence-marker \
  /home/vscode/.local/state/opencode/.persistence-marker; do
  "${compose[@]}" exec -T workspace test -f "${marker}"
done

for marker in \
  /home/vscode/.codex/.persistence-marker \
  /home/vscode/.claude/.persistence-marker \
  /home/vscode/.local/share/opencode/.persistence-marker \
  /home/vscode/.config/opencode/.persistence-marker \
  /home/vscode/.local/state/opencode/.persistence-marker; do
  "${compose[@]}" exec -T workspace rm -f "${marker}"
done

"${compose_script}" verify
"${compose_script}" stop
printf 'Acceptance checks passed; the environment is stopped and named volumes were preserved.\n'
