#!/usr/bin/env bash
set -euo pipefail

package_file="nix/package.nix"

entire_version=$(perl -ne 'print "$1\n" and exit if /^\s*version = "([0-9]+\.[0-9]+\.[0-9]+)";/' "$package_file")
if [[ -z "$entire_version" ]]; then
  printf 'error: could not read entire version from %s\n' "$package_file" >&2
  exit 1
fi

go_mod_url="https://raw.githubusercontent.com/entireio/cli/v${entire_version}/go.mod"
go_mod=$(curl --fail --silent --show-error --location "$go_mod_url")

go_version=$(perl -0ne '
  if (/^toolchain\s+go([0-9]+\.[0-9]+\.[0-9]+)$/m) { print "$1\n"; exit }
  if (/^go\s+([0-9]+\.[0-9]+\.[0-9]+)$/m) { print "$1\n"; exit }
' <<< "$go_mod")

if [[ -z "$go_version" ]]; then
  printf 'error: could not read Go version from %s\n' "$go_mod_url" >&2
  exit 1
fi

case "$go_version" in
  1.26.*) ;;
  *)
    printf 'error: entire %s requires Go %s, but package.nix currently supports only Go 1.26.x automation\n' "$entire_version" "$go_version" >&2
    exit 1
    ;;
esac

go_src_sha256=$(
  curl --fail --silent --show-error --location 'https://go.dev/dl/?mode=json&include=all' \
    | jq --raw-output --arg version "go${go_version}" '
        .[]
        | select(.version == $version)
        | .files[]
        | select(.filename == ($version + ".src.tar.gz"))
        | .sha256
      '
)

if [[ -z "$go_src_sha256" ]]; then
  printf 'error: go.dev release metadata does not list go%s.src.tar.gz\n' "$go_version" >&2
  exit 1
fi

go_src_hash=$(nix hash convert --hash-algo sha256 --to sri "$go_src_sha256")

GO_VERSION="$go_version" GO_SRC_HASH="$go_src_hash" perl -0pi -e '
  s/^\s*goVersion = ".*?";/  goVersion = "$ENV{GO_VERSION}";/m or die "missing goVersion assignment\n";
  s/^\s*goSrcHash = ".*?";/  goSrcHash = "$ENV{GO_SRC_HASH}";/m or die "missing goSrcHash assignment\n";
' "$package_file"

printf 'updated Go toolchain pin for entire %s to Go %s\n' "$entire_version" "$go_version"
