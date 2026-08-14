# CLAUDE.md

## Table Of Contents

- [Project Context](#project-context)
- [Workflow References](#workflow-references)
- [Local State](#local-state)

## Project Context

- Keep changes small and focused on packaging `entire`.
- Prefer direct edits to `flake.nix` and `nix/package.nix` over extra layers.
- Run repo commands through Nix when practical.

## Workflow References

- Package maintenance: [`docs/package-maintenance.md`](docs/package-maintenance.md)
- Release policy: [`docs/releasing.md`](docs/releasing.md)

Package updates use GitHub Actions: the scheduled updater bumps the upstream
`entire` version, runs `nix run .#update-go-toolchain`, and runs
`nix-update --flake default --version skip` before opening an update PR.

## Local State

- `GSTACK_HOME=.gstack` — gstack data lives in the repo, not `~/.gstack/`.
