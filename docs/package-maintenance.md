# Package Maintenance

## Table Of Contents

- [Overview](#overview)
- [Package Shape](#package-shape)
- [Manual Update Workflow](#manual-update-workflow)
- [Automatic Update Workflow](#automatic-update-workflow)
- [Updater Authentication Setup](#updater-authentication-setup)
- [PR Verification Workflow](#pr-verification-workflow)
- [Go Toolchain Pin](#go-toolchain-pin)
- [Failure Modes](#failure-modes)
- [Verification](#verification)
- [Related Docs](#related-docs)

## Overview

This repo packages upstream [`entireio/cli`](https://github.com/entireio/cli) as
the default flake package. A scheduled GitHub Actions workflow tracks upstream
releases and creates complete package update PRs.

The package update flow has three responsibilities:

- The scheduled updater detects the latest stable `entire` release and updates
  the package metadata.
- The PR verifier runs `nix build .#` on the final update commit.
- GitHub auto-merges an update only after the verifier check passes.

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

## Automatic Update Workflow

[`Update Entire`](../.github/workflows/update-entire.yml) runs daily and can be
started manually with `workflow_dispatch`. It reads the latest stable GitHub
release for `entireio/cli`, compares it with `nix/package.nix`, and exits when
the package is current.

When an update is available, it creates an `automation/entire-vX.Y.Z` branch,
updates `version`, `goVersion`, `goSrcHash`, `src.hash`, and `vendorHash`, then
opens a PR with squash auto-merge enabled.

## Updater Authentication Setup

The updater authenticates as a private GitHub App so that its PRs trigger the
normal `pull_request` verification workflow without manual approval. Install
the App only on this repository and grant it `Contents: Read and write` and
`Pull requests: Read and write` permissions.

Store the numeric GitHub App ID as the repository variable
`ENTIRE_UPDATER_APP_ID` and the complete generated PEM private key as the
repository secret `ENTIRE_UPDATER_APP_PRIVATE_KEY`. Do not create an Actions
environment for these values.

Configure both values in the GitHub web UI: repository **Settings** ->
**Secrets and variables** -> **Actions**. Use the **Secrets** tab for the
private key and the **Variables** tab for the App ID. The private key must
never be committed or pasted into workflow YAML.

If the repository restricts allowed actions, add
`actions/create-github-app-token@*` alongside the existing checkout and Nix
installer entries.

## PR Verification Workflow

[`Verify package`](../.github/workflows/update-hashes.yml) runs on package PRs
that open or change. It only runs `nix build .#`; it never modifies the PR
branch. Configure its `verify-package` check as required for `main` so GitHub
auto-merges only a successful package build.

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

For an updater-style smoke test, temporarily change `version` in
`nix/package.nix`, run `nix run .#update-go-toolchain`, inspect `goVersion` and
`goSrcHash`, then restore the version before committing unless the version bump
is intentional.

## Related Docs

- [README](../README.md): user-facing install, build, setup, and update quick
  start.
- [Releasing](./releasing.md): release policy for commits, tags, and version
  boundaries.
