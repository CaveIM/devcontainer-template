#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

install_gh="${1:?GitHub CLI toggle is required}"
extra_packages="${2:-}"

case "${install_gh}" in true|false) ;; *) printf 'INSTALL_GITHUB_CLI must be true or false.\n' >&2; exit 2 ;; esac

for package in ${extra_packages}; do
  if [[ ! "${package}" =~ ^[a-z0-9][a-z0-9.+:-]*$ ]]; then
    printf 'Unsafe EXTRA_APT_PACKAGES entry: %s\n' "${package}" >&2
    exit 2
  fi
done

apt-get update
apt-get install -y --no-install-recommends \
  bash build-essential ca-certificates curl git gnupg jq less \
  lsof make procps psmisc ripgrep sudo tar tzdata unzip util-linux wget zip

if [[ "${install_gh}" == true ]]; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  dpkg_arch="$(dpkg --print-architecture)"
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "${dpkg_arch}" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update
  apt-get install -y --no-install-recommends gh
fi

if [[ -n "${extra_packages}" ]]; then
  # Intentional word splitting after every token was validated above.
  # shellcheck disable=SC2086
  apt-get install -y --no-install-recommends ${extra_packages}
fi

rm -rf /var/lib/apt/lists/*
