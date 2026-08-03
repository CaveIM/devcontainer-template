#!/usr/bin/env bash
set -euo pipefail

failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

if [[ "$(id -u)" -ne 0 && "$(id -un)" == vscode ]]; then pass 'running as non-root vscode'; else fail 'must run as non-root vscode'; fi

workspace=/workspaces/workspace
if [[ -d "${workspace}" && -w "${workspace}" ]]; then pass 'workspace is writable'; else fail 'workspace is not writable'; fi

check_tool() {
  local toggle="$1" command_name="$2"
  if [[ "${toggle}" == true ]]; then
    if command -v "${command_name}" >/dev/null 2>&1 && "${command_name}" --version >/dev/null 2>&1; then
      pass "${command_name} is installed and reports a version"
    else
      fail "${command_name} is enabled but unavailable"
    fi
  else
    pass "${command_name} is disabled"
  fi
}

check_tool "${INSTALL_CODEX:-true}" codex
check_tool "${INSTALL_CLAUDE_CODE:-true}" claude
check_tool "${INSTALL_OPENCODE:-true}" opencode

mount_source() { findmnt -n -o SOURCE --target "$1" 2>/dev/null || true; }
workspace_source="$(mount_source "${workspace}")"
for state_dir in \
  /home/vscode/.codex \
  /home/vscode/.claude \
  /home/vscode/.local/share/opencode \
  /home/vscode/.config/opencode \
  /home/vscode/.local/state/opencode; do
  state_source="$(mount_source "${state_dir}")"
  if [[ -n "${state_source}" && "${state_source}" != "${workspace_source}" ]]; then
    pass "${state_dir} is mounted separately from the workspace"
  else
    fail "${state_dir} is not on a separate mount"
  fi
done

if [[ ! -e /var/run/docker.sock && ! -e /run/docker.sock ]]; then pass 'Docker socket is absent'; else fail 'Docker socket is mounted'; fi

if findmnt -rn -o TARGET | grep -Eq '^/(Users|mnt/[a-zA-Z]|home/[^/]+)$'; then
  fail 'a possible host home/root path is mounted'
else
  pass 'no host home root is mounted'
fi

cap_eff="$(awk '/^CapEff:/ {print $2}' /proc/1/status)"
if [[ "${cap_eff}" != 0000003fffffffff && "${cap_eff}" != 000001ffffffffff ]]; then pass 'container does not have the full privileged capability set'; else fail 'container appears privileged'; fi

if [[ -f "${workspace}/.devcontainer/compose.yml" ]]; then
  if grep -Eq '^    network_mode:[[:space:]]*host' "${workspace}/.devcontainer/compose.yml"; then fail 'Compose config uses host networking'; else pass 'Compose config does not declare host networking'; fi
  if grep -Eq '/var/run/docker.sock|/run/docker.sock' "${workspace}/.devcontainer/compose.yml"; then fail 'Compose config mounts a Docker socket'; else pass 'Compose config does not mount a Docker socket'; fi
  if grep -Eq '^    privileged:[[:space:]]*true' "${workspace}/.devcontainer/compose.yml"; then fail 'Compose config enables privileged mode'; else pass 'Compose config does not enable privileged mode'; fi
fi

if (( failures > 0 )); then
  printf '%d verification check(s) failed.\n' "${failures}" >&2
  exit 1
fi
printf 'All verification checks passed.\n'
