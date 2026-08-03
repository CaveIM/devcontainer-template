# Agent instructions

This repository is a platform-neutral AI devcontainer baseline, not an application.

- Do not add an application framework, language runtime, database, web server, browser, or exposed port unless the user explicitly requests it.
- Preserve the separate Compose-managed volumes for Codex, Claude Code, OpenCode data/config, and GitHub CLI.
- Do not add host home, SSH key, credential, shell configuration, browser profile, cloud configuration, or Docker socket mounts casually. Explain and document any requested boundary expansion.
- Keep every agent installation on an official mechanism, registry, or release artifact and keep it version-pinnable. Never add an unofficial fallback.
- Keep Linux AMD64 and ARM64 support. Detect architecture before selecting any architecture-specific artifact.
- Preserve the non-root interactive user, unprivileged container, bridge networking, and lack of default ports.
- Run `make lint`, `make start`, and `make verify` after container-infrastructure changes. Run `.devcontainer/scripts/acceptance-test.sh` for changes to mounts, persistence, user setup, capabilities, or installation.
- Update README.md and SECURITY.md whenever persistence, credentials, networking, mounts, permissions, or another security boundary changes.
- Do not print tokens, auth files, full environment dumps, or transcript contents in scripts, tests, logs, or issue reports.
