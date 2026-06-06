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

Package updates are split across Renovate and GitHub Actions: Renovate bumps the
upstream `entire` version, `nix run .#update-go-toolchain` matches upstream's Go
requirement, and `nix-update --flake default --version skip` refreshes Nix hashes.

## Local State

- `GSTACK_HOME=.gstack` — gstack data lives in the repo, not `~/.gstack/`.
