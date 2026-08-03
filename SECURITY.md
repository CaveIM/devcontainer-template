# Security policy

## Threat model

This template reduces accidental host exposure while running powerful coding agents. The agents can execute commands, edit the checked-out repository, access the network, and read credentials that users create inside their own state volume. The default CLI configurations intentionally bypass approval prompts, so the devcontainer is the primary filesystem boundary.

The template aims to protect unrelated host files and credentials from ordinary agent actions and prompt injection. It does not defend against a Docker/container escape, a compromised Docker daemon, a malicious kernel or runtime, hostile image/installer supply chains, physical access, or secrets deliberately placed in the workspace.

## Protected host resources

The default configuration does not share the host home, SSH files or agent, Git credential store, cloud-provider directories, shell startup files, browser profiles, Docker socket, other repositories, arbitrary environment secrets, or ports. The container is not privileged, does not use host networking, drops all capabilities before adding only the small set needed for passwordless sudo, and mounts only this repository from the host.

## Intentionally shared resources

The current checkout is a writable bind mount. Docker's host kernel, network path, CPU, and memory are necessarily shared. Compose-managed named volumes retain agent and GitHub CLI credentials, configuration, transcripts, and history per Compose project. Anything in the repository—including secrets accidentally committed or generated there—is visible to all three agents.

Named volumes are isolation from the host home, not encryption. Docker administrators and processes with daemon access can read them. Agent histories can contain source, tool output, prompts, and secrets printed by commands.

## Container and runtime limitations

A container is not a VM. It shares the host kernel, and vulnerabilities in the kernel, Docker daemon, runtime, images, or enabled capabilities can cross the boundary. Passwordless sudo makes root available inside the container; capability restrictions still apply, but root can read all container state and alter the workspace. Network access means a compromised agent or dependency can exfiltrate anything visible inside the container.

The Docker socket is deliberately absent. Mounting it generally gives effective control over the host Docker daemon and can allow host filesystem access. Privileged mode, host networking, broad device access, extra capabilities, and host credential mounts similarly weaken the intended boundary.

## Agent permission differences

Codex approval policy and OS sandboxing are separate controls. Claude Code has permission modes, protected paths, and optional Bash sandboxing. OpenCode evaluates per-action permission rules. Their unrestricted modes are not equivalent and do not add an inner security boundary here. OpenAI and Anthropic explicitly warn that bypass/full-access modes should be limited to isolated environments, and that devcontainers do not prevent every attack.

For untrusted repositories, change the tools back to prompt-based/workspace-limited modes, restrict outbound networking, use a disposable environment, and avoid authenticating valuable accounts. A VM with carefully scoped credentials may be more appropriate.

## Supply chain

The Dockerfile uses the official Node.js image, Debian packages, GitHub's signed apt repository, and the official npm packages named in README.md. npm lifecycle scripts can run because the official CLI packages use them to select/link platform binaries. OpenCode's official glibc platform package is selected explicitly by detected CPU architecture; its documented data/config paths and observed XDG state path are separately persisted. Pin exact versions for reproducible review, rebuild regularly for security updates, and inspect upstream release notes and package provenance before changing pins.

`latest` is convenient but not reproducible. It can change without a repository diff. Production or regulated users should pin image digests and exact CLI/package versions after their own review. ARM64 and AMD64 builds can resolve different platform packages published under the same npm release.

## Secret handling

- Authenticate interactively only after reviewing the repository.
- Prefer narrowly scoped, revocable credentials and separate development accounts.
- Never add API keys to `.devcontainer/.env`, Compose YAML, the Dockerfile, build arguments, the workspace, shell history, or Git.
- Do not print full environments, auth files, or agent transcripts in diagnostics.
- Remember that unrestricted agents can read each other's mounted state only if they intentionally access those absolute paths; separate volumes organize persistence but do not isolate processes within the same container.
- Run `make destroy` before transferring or disposing of the environment. Docker volume deletion is not a guaranteed secure erase of underlying storage.

## Reporting a vulnerability

Do not open a public issue for a vulnerability that could expose credentials or provide an active exploit. Use GitHub's **Security → Report a vulnerability** private reporting feature for the published repository. If private vulnerability reporting is unavailable, contact the repository owner through a private channel listed on their GitHub profile and include affected versions, impact, reproduction steps, and a minimal proof of concept. Do not include real tokens or private transcripts.
