#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
status=0
while IFS=: read -r file line target; do
  target="${target%%#*}"
  [[ -z "${target}" || "${target}" =~ ^(https?://|mailto:) ]] && continue
  base="$(dirname "${file}")"
  if [[ ! -e "${base}/${target}" ]]; then
    printf '%s:%s: broken local link: %s\n' "${file}" "${line}" "${target}" >&2
    status=1
  fi
done < <(
  cd "${repo_root}"
  rg -n -o --replace '$1' '\[[^]]+\]\(([^ )]+)(?: "[^"]+")?\)' --glob '*.md' . || true
)
exit "${status}"
