.PHONY: build start stop verify destroy lint config

build:
	@.devcontainer/scripts/compose.sh build

start:
	@.devcontainer/scripts/compose.sh start

stop:
	@.devcontainer/scripts/compose.sh stop

verify:
	@.devcontainer/scripts/compose.sh verify

destroy:
	@.devcontainer/scripts/compose.sh destroy

config:
	@.devcontainer/scripts/compose.sh config

lint:
	@shellcheck .devcontainer/scripts/*.sh
	@.devcontainer/scripts/check-doc-links.sh
	@.devcontainer/scripts/compose.sh config >/dev/null
	@if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then git diff --check; else echo 'git metadata unavailable; skipped git diff --check'; fi
