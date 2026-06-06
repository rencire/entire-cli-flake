#!/usr/bin/env bash
set -euo pipefail

package_file="nix/package.nix"

entire_version=$(awk -F'"' '/^[[:space:]]*version = "[0-9]+\.[0-9]+\.[0-9]+";/ { print $2; exit }' "$package_file")
if [[ -z "$entire_version" ]]; then
  printf 'error: could not read entire version from %s\n' "$package_file" >&2
  exit 1
fi

go_mod_url="https://raw.githubusercontent.com/entireio/cli/v${entire_version}/go.mod"
go_mod=$(curl --fail --silent --show-error --location "$go_mod_url")

go_version=$(awk '
  $1 == "toolchain" && $2 ~ /^go[0-9]+\.[0-9]+\.[0-9]+$/ { sub(/^go/, "", $2); print $2; found = 1; exit }
  $1 == "go" && $2 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ { fallback = $2 }
  END { if (!found && fallback != "") print fallback }
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

release_json=$(curl --fail --silent --show-error --location 'https://go.dev/dl/?mode=json&include=all')
go_src_sha256=$(awk -v version="go${go_version}" '
  $0 ~ "\"version\": \"" version "\"" { in_release = 1 }
  in_release && $0 ~ "\"filename\": \"" version "\\.src\\.tar\\.gz\"" { in_file = 1 }
  in_release && in_file && /"sha256":/ {
    gsub(/[",]/, "", $2)
    print $2
    exit
  }
' <<< "$release_json")

if [[ -z "$go_src_sha256" ]]; then
  printf 'error: go.dev release metadata does not list go%s.src.tar.gz\n' "$go_version" >&2
  exit 1
fi

go_src_hash=$(nix hash convert --hash-algo sha256 --to sri "$go_src_sha256")

tmp=$(mktemp)
awk -v go_version="$go_version" -v go_src_hash="$go_src_hash" '
  /^[[:space:]]*goVersion = "/ { print "  goVersion = \"" go_version "\";"; next }
  /^[[:space:]]*goSrcHash = "/ { print "  goSrcHash = \"" go_src_hash "\";"; next }
  { print }
' "$package_file" > "$tmp"
mv "$tmp" "$package_file"

printf 'updated Go toolchain pin for entire %s to Go %s\n' "$entire_version" "$go_version"
