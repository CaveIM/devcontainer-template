# AI Devcontainer Baseline

A small, platform-neutral GitHub template for AI-assisted development in a Docker Compose-backed [Development Container](https://containers.dev/). It installs the Codex CLI, Claude Code, and OpenCode without adding an application framework, database, browser, language SDK, exposed port, Docker daemon, or host credential mount.

> [!WARNING]
> The agent CLIs default to unrestricted/bypass approval modes at the template owner's request. The container is therefore the primary filesystem boundary. Use only trusted repositories, review agent activity, and read [SECURITY.md](SECURITY.md). A container is not a VM and does not make untrusted code safe.

## What is included

- Debian Bookworm-based official Node.js 24 LTS image, supporting Linux AMD64 and ARM64
- Non-root `vscode` user with passwordless sudo and a normal Bash shell
- Codex (`codex`), Claude Code (`claude`), and OpenCode (`opencode`)
- Git, GitHub CLI, curl, wget, CA certificates, GnuPG, jq, ripgrep, build essentials, archive tools, and process inspection tools
- Project-scoped Docker volumes for each agent and for GitHub CLI
- No ports, privileged mode, host networking, Docker socket, host home, SSH keys, shell files, browser profile, or cloud credentials

The repository itself is bind-mounted at `/workspaces/workspace`. It is not copied or cloned by the image.

## Start from the GitHub template

1. Publish this repository on GitHub and enable **Template repository** under repository settings.
2. Select **Use this template**, create a new repository, then clone that new repository.
3. Optionally copy `.devcontainer/.env.example` to `.devcontainer/.env` and choose a unique `COMPOSE_PROJECT_NAME`.
4. Open the folder in VS Code and choose **Dev Containers: Reopen in Container**. Other tools implementing the Dev Container specification can use `.devcontainer/devcontainer.json` too.

Windows users should clone into the WSL2 filesystem (for example, under `~/src`) and open the folder from WSL. Docker Desktop must be configured for WSL2 integration. macOS users need Docker Desktop or another compatible Docker runtime. Linux users need Docker Engine with Compose v2.

Without an editor, install the [Dev Container CLI](https://github.com/devcontainers/cli) and run:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

For direct Compose use, prefer the clone-unique Make wrapper:

```bash
make build
make start
make verify
```

The wrapper derives a Compose project name from the clone path. If you invoke `docker compose` yourself, set a unique `COMPOSE_PROJECT_NAME`; Compose scopes the named volumes by that project name.

## First use and authentication

The post-create hook prints versions but never starts login or prints environment contents.

```bash
codex                 # follow the ChatGPT or API-key login flow
claude                # follow the Claude account/Console login flow
opencode              # use /connect and select a provider
gh auth login         # optional, stores GitHub CLI auth in its own volume
```

No host credentials are required. Choose one Git strategy deliberately:

1. Run `gh auth login` in the container. `GH_CONFIG_DIR` points to the project-scoped GitHub CLI volume.
2. Use HTTPS and configure a container-local Git credential helper. Understand whether that helper stores credentials in plaintext before enabling it.
3. In a downstream repository only, opt into SSH-agent forwarding. Forward the agent socket rather than mounting `~/.ssh`, limit the keys exposed, and remember that an unrestricted agent can use the forwarded agent while connected.

The template does not copy Git credentials, mount private keys, or forward an SSH agent automatically.

## Persistence and isolation

Compose creates these project-scoped volumes:

| Volume | Container path | Contents |
|---|---|---|
| `codex-state` | `/home/vscode/.codex` | Codex auth, configuration, logs, and conversations (`CODEX_HOME`) |
| `claude-state` | `/home/vscode/.claude` | Claude settings, credentials, plugins, transcripts, and history (`CLAUDE_CONFIG_DIR`) |
| `opencode-data` | `/home/vscode/.local/share/opencode` | OpenCode auth, logs, project/session data |
| `opencode-config` | `/home/vscode/.config/opencode` | OpenCode global configuration and plugins |
| `opencode-state` | `/home/vscode/.local/state/opencode` | OpenCode XDG runtime state observed from the official CLI |
| `github-cli-state` | `/home/vscode/.config/gh` | GitHub CLI auth and configuration (`GH_CONFIG_DIR`) |

An ordinary stop/start preserves the container and volumes. An image rebuild replaces the container but preserves all named volumes. A reset deletes those volumes, signs the tools out, and removes their container-local history. It does not touch the repository.

```bash
make stop       # preserves volumes
make destroy    # requires typing DELETE AGENT STATE; deletes volumes
```

From inside the container, `.devcontainer/scripts/reset-agent-state.sh` explains the same effect and prints the host-side command. It cannot delete volumes because the Docker socket is intentionally absent.

Unrelated clones stay isolated when they use different Compose project names. Do not set one global `COMPOSE_PROJECT_NAME` for every clone.

## Permission defaults

The generated user configurations are copied only when the corresponding file does not already exist:

- Codex uses `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`. Normal work uses medium reasoning. `codex --profile plan` selects the included high-effort profile; Codex does not currently document a setting that automatically changes effort when `/plan` is entered.
- Claude Code uses `permissions.defaultMode = "bypassPermissions"`, suppresses the one-time dangerous-mode prompt, and uses medium effort. Claude's bypass mode skips its permission layer; its separate plan mode remains a planning workflow. Claude does not document per-permission-mode effort defaults, so high planning effort can be selected with `/effort high` when needed.
- OpenCode uses the documented global `"permission": "allow"`. OpenCode's provider/model variants are model-specific, so this template does not fabricate a portable effort setting.

These are not equivalent security systems. Codex distinguishes approvals from its OS sandbox, Claude has permission modes plus optional Bash sandboxing, and OpenCode evaluates permission rules per action. Here, all three are deliberately permissive inside the outer container.

To restore a conservative Codex setup, edit `/home/vscode/.codex/config.toml`:

```toml
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

Likewise, use Claude's `default`/`acceptEdits` mode or OpenCode's `ask` rules when the container contains sensitive data.

## Customize versions and packages

Copy the example environment file and edit non-secret values:

```bash
cp .devcontainer/.env.example .devcontainer/.env
```

`CODEX_VERSION`, `CLAUDE_CODE_VERSION`, and `OPENCODE_VERSION` accept `latest`, a release tag, or an exact version without shell metacharacters. The `INSTALL_*` toggles independently disable tools. Change a pin and rebuild to update that tool. With `latest`, rebuilding resolves the current npm release; a running container does not automatically change the image-installed npm packages.

`EXTRA_APT_PACKAGES` accepts space-separated Debian package names. It rejects option-like values and shell syntax. Keep stack-specific runtimes in downstream Dockerfile layers instead:

```dockerfile
# In a downstream .devcontainer/Dockerfile, keep this template as the base
# or copy its stages, then add the project's official runtime installation.
RUN sudo-or-root-project-specific-install-command
```

Alternatively, add infrastructure to `compose.yml` without changing agent installation logic:

```yaml
services:
  postgres:
    image: postgres:17-bookworm
    environment:
      POSTGRES_PASSWORD: choose-a-development-only-value
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

Do not publish a database port unless the host needs it; containers on the Compose network can use the service name.

## Security boundary

The workspace is intentionally the only host bind mount. The absence of `/var/run/docker.sock` prevents agents from trivially controlling the host Docker daemon, which would largely defeat this boundary. Docker itself, its kernel, the runtime, the current repository contents, network access, and any credentials created inside the container remain part of the trust model.

To add a downstream mount, edit `compose.yml` explicitly and document why it is required. A read-only mount still exposes data to an agent and potentially to network exfiltration. A writable mount also permits modification or deletion. Never mount a whole home directory for convenience.

See [SECURITY.md](SECURITY.md) for the full threat model.

## Updating and diagnosing platforms

- Codex: change `CODEX_VERSION`, then `make build` and `make start`.
- Claude Code: change `CLAUDE_CODE_VERSION` and rebuild. Because this template uses Anthropic's supported npm distribution, update through npm/image rebuild rather than `claude update`.
- OpenCode: change `OPENCODE_VERSION` and rebuild.

For architecture trouble:

```bash
docker info --format '{{.Architecture}}'
docker buildx inspect --bootstrap
docker compose -f .devcontainer/compose.yml build --no-cache
```

The official npm packages select their own Linux AMD64/ARM64 optional artifacts. The Dockerfile never guesses an archive name. On Apple Silicon, avoid forcing `linux/amd64` unless emulation is intentional. On Windows, keep the clone in WSL2 and confirm Docker Desktop reports a Linux engine. If a package version lacks your architecture, pin a version that officially publishes it; this template never falls back to an unofficial binary.

## Validation

```bash
make lint
make start
make verify
.devcontainer/scripts/acceptance-test.sh
```

The acceptance test rebuilds once to confirm marker persistence, inspects mounts and runtime settings, then stops the environment without deleting volumes. CI builds AMD64, builds ARM64 through QEMU/Buildx, runs ShellCheck and documentation checks, and never authenticates an agent.

## Verified official installation sources

Installation and configuration sources were checked on **2026-08-03**:

- [OpenAI Codex official repository and installation options](https://github.com/openai/codex#installing-and-running-codex-cli)
- [OpenAI Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference#configtoml)
- [OpenAI guidance for Codex in devcontainers](https://learn.chatgpt.com/docs/agent-approvals-security#run-codex-in-dev-containers)
- [Anthropic Claude Code advanced installation](https://code.claude.com/docs/en/installation) (npm is an officially supported alternative and publishes AMD64/ARM64 native optional packages)
- [Anthropic Claude Code permission modes](https://code.claude.com/docs/en/permission-modes)
- [Anthropic Claude configuration/state directory](https://code.claude.com/docs/en/claude-directory)
- [OpenCode installation](https://opencode.ai/docs/#install)
- [OpenCode permissions](https://opencode.ai/docs/permissions/)
- [OpenCode storage locations](https://opencode.ai/docs/troubleshooting/#storage)
- [GitHub CLI Debian/Ubuntu installation](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
- [Official Node.js Docker image](https://hub.docker.com/_/node)

The npm packages used are `@openai/codex`, `@anthropic-ai/claude-code`, and OpenCode's own architecture-specific `opencode-linux-x64` or `opencode-linux-arm64` artifact. OpenCode's official `opencode-ai` meta-package currently mis-selects its musl optional dependency under npm 11 on Linux ARM64; selecting the matching official glibc package explicitly makes the architecture choice auditable and follows the meta-package's own failure guidance. No unofficial fallback is present.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Important GitHub Actions are pinned to commit SHAs; Dependabot proposes updates, which should be reviewed against upstream release notes before merging.
