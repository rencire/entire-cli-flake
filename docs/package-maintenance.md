# Package Maintenance

## Table Of Contents

- [Overview](#overview)
- [Package Shape](#package-shape)
- [Manual Update Workflow](#manual-update-workflow)
- [Renovate Workflow](#renovate-workflow)
- [Hash Update Workflow](#hash-update-workflow)
- [Go Toolchain Pin](#go-toolchain-pin)
- [Failure Modes](#failure-modes)
- [Verification](#verification)
- [Related Docs](#related-docs)

## Overview

This repo packages upstream [`entireio/cli`](https://github.com/entireio/cli) as
the default flake package. Upstream releases are tracked by Renovate, and a
GitHub Actions workflow repairs the Nix-specific hashes on Renovate PRs.

The package update flow has three responsibilities:

- Renovate owns the upstream `entire` version bump.
- `nix run .#update-go-toolchain` matches the Go toolchain pin to upstream
  `entire`'s `go.mod`.
- `nix-update --flake default --version skip` refreshes `src.hash` and
  `vendorHash` without changing the version.

## Package Shape

The package lives in [`nix/package.nix`](../nix/package.nix). It exposes
`entire` as the flake's default package, so use `.#` or `default` when building
or updating it.

Important fields:

- `version`: upstream `entireio/cli` release without the leading `v`.
- `goVersion`: Go patch version required by upstream `entire`.
- `goSrcHash`: Nix SRI hash for `go${goVersion}.src.tar.gz` from `go.dev`.
- `src.hash`: Nix hash for the upstream `entireio/cli` release source.
- `vendorHash`: Nix hash for the vendored Go module dependency tree.

## Manual Update Workflow

When updating by hand:

1. Change `version` in [`nix/package.nix`](../nix/package.nix).
2. Run `nix run .#update-go-toolchain`.
3. Run `nix run nixpkgs#nix-update -- --flake default --version skip`.
4. Run `nix build .#`.
5. Inspect the diff before committing.

Do not use `--flake entire`; this flake exposes the package as `default`.

## Renovate Workflow

[`renovate.json`](../renovate.json) uses a regex custom manager for
`nix/package.nix` because this repo does not use a standard package-manager
manifest for upstream `entire`.

Renovate reads:

```nix
version = "0.6.1";
```

It compares that value against GitHub releases for `entireio/cli`, strips the
leading `v` from release tags, and immediately opens a PR that changes only
`version`. This prevents a pending update from remaining only in Renovate's
Dependency Dashboard.

Renovate should not update the Nix hashes. Hash refresh is handled by the GitHub
workflow so the update is reproducible through Nix.

## Hash Update Workflow

[`Update Nix hashes`](../.github/workflows/update-hashes.yml) runs on Renovate
PRs that touch `nix/package.nix`.

The workflow does this in order:

1. Check out the Renovate PR branch.
2. Run `nix run .#update-go-toolchain`.
3. Run `nix run nixpkgs#nix-update -- --flake default --version skip`.
4. Run `nix build .#`.
5. Commit updated package metadata back to the PR branch when there is a diff.

`--version skip` matters: Renovate already selected the upstream version, so
`nix-update` should only recompute `src.hash` and `vendorHash`.

## Go Toolchain Pin

[`nix/apps/update-go-toolchain.js`](../nix/apps/update-go-toolchain.js) keeps
the local Go source pin aligned with upstream `entire`.

The updater:

1. Reads `version` from `nix/package.nix`.
2. Fetches upstream `entireio/cli` `go.mod` for tag `v${version}`.
3. Reads `toolchain goX.Y.Z` if present, otherwise falls back to `go X.Y.Z`.
4. Fetches Go release metadata from `https://go.dev/dl/?mode=json&include=all`.
5. Finds `goX.Y.Z.src.tar.gz` and converts its SHA256 to Nix SRI form.
6. Updates only `goVersion` and `goSrcHash` in `nix/package.nix`.

The updater is exposed as a Nix app by
[`nix/apps/update-go-toolchain.nix`](../nix/apps/update-go-toolchain.nix). The
app declares its runtime dependencies through Nix and uses only Bun built-ins
plus `nix hash convert`; it does not pull npm packages.

The updater currently supports automatic Go `1.26.x` patch updates. If upstream
`entire` moves to a new Go minor family, the updater fails clearly so the Nix
package can be adjusted deliberately.

## Failure Modes

- If `nix-update` reports that `go.mod requires go >= ...`, run
  `nix run .#update-go-toolchain` before retrying.
- If the updater says a Go version is unsupported, update `nix/package.nix` to
  use the matching Nixpkgs Go family before expanding the automation.
- If Go release metadata does not list the requested source tarball, upstream
  `entire` may require a Go release that is not published yet.
- If the workflow tries `--flake entire`, change it back to `--flake default`.

## Verification

Use these checks for package maintenance changes:

```bash
nix run .#update-go-toolchain
nix run nixpkgs#nix-update -- --flake default --version skip
nix build .#
git diff --check
```

For a Renovate-style smoke test, temporarily change `version` in
`nix/package.nix`, run `nix run .#update-go-toolchain`, inspect `goVersion` and
`goSrcHash`, then restore the version before committing unless the version bump
is intentional.

## Related Docs

- [README](../README.md): user-facing install, build, setup, and update quick
  start.
- [Releasing](./releasing.md): release policy for commits, tags, and version
  boundaries.
