FROM node:24-bookworm-slim

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ARG INSTALL_CODEX=true
ARG CODEX_VERSION=latest
ARG INSTALL_CLAUDE_CODE=true
ARG CLAUDE_CODE_VERSION=latest
ARG INSTALL_OPENCODE=true
ARG OPENCODE_VERSION=latest
ARG INSTALL_GITHUB_CLI=true
ARG EXTRA_APT_PACKAGES=""

ENV NPM_CONFIG_PREFIX=/opt/agent-tools \
    PATH=/opt/agent-tools/bin:${PATH}

COPY .devcontainer/scripts/install-system-packages.sh /usr/local/bin/install-system-packages
RUN chmod 0755 /usr/local/bin/install-system-packages \
    && install-system-packages "${INSTALL_GITHUB_CLI}" "${EXTRA_APT_PACKAGES}" \
    && rm -f /usr/local/bin/install-system-packages

RUN set -eux; \
    if id node >/dev/null 2>&1; then userdel --remove node; fi; \
    if getent group node >/dev/null 2>&1; then groupdel node; fi; \
    if getent group "${USER_GID}" >/dev/null; then group_name="$(getent group "${USER_GID}" | cut -d: -f1)"; else groupadd --gid "${USER_GID}" "${USERNAME}"; group_name="${USERNAME}"; fi; \
    useradd --uid "${USER_UID}" --gid "${group_name}" --create-home --shell /bin/bash "${USERNAME}"; \
    printf '%s ALL=(root) NOPASSWD:ALL\n' "${USERNAME}" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    install -d -o "${USERNAME}" -g "${group_name}" \
      /opt/agent-tools \
      /workspaces/workspace \
      "/home/${USERNAME}/.codex" \
      "/home/${USERNAME}/.claude" \
      "/home/${USERNAME}/.config/gh" \
      "/home/${USERNAME}/.config/opencode" \
      "/home/${USERNAME}/.local/share/opencode" \
      "/home/${USERNAME}/.local/state/opencode"; \
    chown -R "${USERNAME}:${group_name}" "/home/${USERNAME}"

COPY --chown=vscode .devcontainer/scripts/install-agent-cli.sh /tmp/install-agent-cli.sh
USER vscode
RUN chmod 0755 /tmp/install-agent-cli.sh \
    && /tmp/install-agent-cli.sh codex "${INSTALL_CODEX}" "${CODEX_VERSION}" \
    && /tmp/install-agent-cli.sh claude "${INSTALL_CLAUDE_CODE}" "${CLAUDE_CODE_VERSION}" \
    && /tmp/install-agent-cli.sh opencode "${INSTALL_OPENCODE}" "${OPENCODE_VERSION}" \
    && rm -f /tmp/install-agent-cli.sh

USER root
RUN chown -R vscode:$(id -gn vscode) /opt/agent-tools /home/vscode /workspaces
USER vscode

ENV CODEX_HOME=/home/vscode/.codex \
    CLAUDE_CONFIG_DIR=/home/vscode/.claude \
    GH_CONFIG_DIR=/home/vscode/.config/gh

WORKDIR /workspaces/workspace
CMD ["sleep", "infinity"]
