# Automatic Entire Updates Design

## Table Of Contents

- [Goal](#goal)
- [Architecture](#architecture)
- [Scheduled Updater](#scheduled-updater)
- [PR Verification](#pr-verification)
- [Auto-Merge](#auto-merge)
- [Failure Handling](#failure-handling)
- [Repository Configuration](#repository-configuration)
- [Migration](#migration)

## Goal

Replace Renovate and the write-back hash workflow with GitHub Actions workflows
that open complete update PRs for stable `entireio/cli` releases and merge them
only after the package builds successfully.

## Architecture

Two workflows divide responsibility cleanly:

- A scheduled updater detects new upstream releases and creates a complete PR.
- A read-only PR verifier builds the package and reports the required GitHub
  check. It never changes the PR branch.

The updater checks the latest stable GitHub release through
`GET /repos/entireio/cli/releases/latest`. Draft and prerelease releases are
not returned by that endpoint.

## Scheduled Updater

The updater runs daily and supports `workflow_dispatch` for on-demand runs.

1. Read the current package version from `nix/package.nix`.
2. Query the latest stable upstream release and strip its leading `v`.
3. Exit successfully when the versions match.
4. Create an `automation/entire-vX.Y.Z` branch when an update is available.
5. Update the package version, run `nix run .#update-go-toolchain`, and run
   `nix run nixpkgs#nix-update -- --flake default --version skip`.
6. Commit the complete package metadata update and open a PR targeting `main`.
7. Enable squash auto-merge for the PR.

The updater obtains a short-lived installation token from a private GitHub App
with `contents: write` and `pull-requests: write` permissions. It does not use
the workflow `GITHUB_TOKEN` for write operations.

## PR Verification

The verifier runs for opened and synchronized automatic update PRs. It checks
out the PR head and runs `nix build .#`.

It does not regenerate hashes, update files, or push commits. Therefore a
successful verification run cannot trigger another verification run.

## Auto-Merge

The `main` ruleset requires the verifier's check. GitHub auto-merges the PR
only after that check passes. The final PR head is therefore the exact revision
that was built by CI.

## Failure Handling

- If release lookup fails, the updater fails and creates no PR.
- If package metadata refresh fails, the updater fails and creates no PR.
- If PR verification fails, the PR remains open and auto-merge does not occur.
- The next daily run retries failed release detection or package metadata
  refresh from the current `main` branch.

## Repository Configuration

- Keep the branch ruleset scoped to `main` only.
- Replace the old `update-hashes` required check with the read-only verifier
  check.
- Keep the Actions allowlist for `actions/checkout@*` and
  `cachix/install-nix-action@*`, and add `actions/create-github-app-token@*`.
- Store the private GitHub App's numeric App ID as an Actions repository
  variable and its PEM private key as an Actions repository secret.

## Migration

1. Add the scheduled updater and read-only verifier workflows.
2. Verify a manually dispatched updater run against a test release branch.
3. Update the `main` ruleset to require the verifier check.
4. Remove `renovate.json` and replace the write-back hash workflow with the
   read-only verifier.
5. Remove the redundant `prCreation: "immediate"` setting introduced during
   the previous investigation.
