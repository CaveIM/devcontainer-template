# Contributing

Keep changes small, platform-neutral, and focused on the reusable container baseline. Open an issue before adding a runtime, service, mount, capability, port, or credential integration that changes the security or stack-neutral scope.

## Development

1. Copy `.devcontainer/.env.example` to `.devcontainer/.env` only if you need overrides. Never put secrets there.
2. Make the change and update README.md, SECURITY.md, and AGENTS.md when the boundary or maintenance workflow changes.
3. Run:

   ```bash
   make lint
   make build
   make start
   make verify
   .devcontainer/scripts/acceptance-test.sh
   git diff --check
   ```

4. Inspect `git diff` for credentials, machine-specific paths, and accidental generated files.

Pull requests should state which host architectures were tested, whether existing volumes were preserved, and any security tradeoff. Do not include auth tokens or transcript output in logs.

## Updating dependencies

Verify agent installation changes against the official links in README.md and update the verification date. Use exact versions when evaluating a release. Important GitHub Actions are pinned to immutable SHAs; Dependabot opens update proposals. Confirm that a proposed SHA belongs to the expected upstream release tag and review its release notes before merging.

Do not commit changes unless the repository owner asks you to.
