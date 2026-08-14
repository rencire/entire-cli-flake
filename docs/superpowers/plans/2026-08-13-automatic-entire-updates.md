# Automatic Entire Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Renovate's split version and hash update flow with a scheduled GitHub Actions updater that creates complete PRs and auto-merges them after a read-only Nix build check.

**Architecture:** A daily updater queries GitHub Releases, updates all package metadata on an `automation/` branch, and enables auto-merge on a new PR. A separate pull-request workflow builds the final PR head without writing to it, providing the required check on `main`.

**Tech Stack:** GitHub Actions, GitHub CLI, Nix, `nix-update`, existing Nix updater app.

---

### Task 1: Create The Scheduled Updater

**Files:**
- Create: `.github/workflows/update-entire.yml`

- [ ] **Step 1: Add the release lookup and no-update exit path**

Create a daily `schedule` plus `workflow_dispatch` workflow. Read the latest
stable release with `gh api repos/entireio/cli/releases/latest --jq .tag_name`,
strip its `v`, compare it to the version in `nix/package.nix`, and exit when the
versions match.

- [ ] **Step 2: Add complete package metadata generation**

On an available update, create `automation/entire-v${version}`, set the
package version, then run:

```bash
nix run .#update-go-toolchain
nix run nixpkgs#nix-update -- --flake default --version skip
```

- [ ] **Step 3: Create and enable auto-merge for the update PR**

Commit `nix/package.nix`, push the branch, create a pull request targeting
`main`, and enable squash auto-merge. Authenticate with a short-lived private
GitHub App installation token that has `contents: write` and
`pull-requests: write` permissions. Do not build or merge directly from this
workflow.

- [ ] **Step 4: Validate workflow syntax**

Run:

```bash
nix run nixpkgs#actionlint -- .github/workflows/update-entire.yml
```

Expected: exit status 0.

### Task 2: Make PR Verification Read-Only

**Files:**
- Modify: `.github/workflows/update-hashes.yml`

- [ ] **Step 1: Rename the workflow and check job**

Rename the workflow and its job to `Verify package`. Preserve the
`pull_request` trigger for `opened` and `synchronize` events affecting
`nix/package.nix`.

- [ ] **Step 2: Remove write-back behavior**

Remove Go pin, hash generation, Git configuration, staging, and push steps.
Keep only checkout, Nix installation, and `nix build .#`. Reduce permissions to
`contents: read`.

- [ ] **Step 3: Validate workflow syntax**

Run:

```bash
nix run nixpkgs#actionlint -- .github/workflows/update-hashes.yml
```

Expected: exit status 0.

### Task 3: Remove Renovate And Update Documentation

**Files:**
- Delete: `renovate.json`
- Modify: `docs/package-maintenance.md`
- Modify: `README.md`

- [ ] **Step 1: Remove Renovate configuration**

Delete `renovate.json`, including the now-redundant `prCreation` setting.

- [ ] **Step 2: Document the scheduled workflow**

Replace Renovate and hash write-back instructions with the scheduled updater,
manual workflow dispatch, read-only PR verification, and auto-merge behavior.

- [ ] **Step 3: Validate documentation references**

Run:

```bash
rg -n 'Renovate|renovate.json|Update Nix hashes' README.md docs AGENTS.md CLAUDE.md
```

Expected: no obsolete automation instructions remain.

### Task 4: Verify The Migration

**Files:**
- Verify: `.github/workflows/update-entire.yml`
- Verify: `.github/workflows/update-hashes.yml`
- Verify: `nix/package.nix`

- [ ] **Step 1: Run both workflow linters**

Run:

```bash
nix run nixpkgs#actionlint -- .github/workflows/update-entire.yml .github/workflows/update-hashes.yml
```

Expected: exit status 0.

- [ ] **Step 2: Build the current package**

Run:

```bash
nix build .#
```

Expected: exit status 0.

- [ ] **Step 3: Inspect the final diff**

Run:

```bash
git diff --check
```

Expected: no whitespace errors and only the intended automation migration.
