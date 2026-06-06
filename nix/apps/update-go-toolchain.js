#!/usr/bin/env bun
import { $ } from "bun";

const packagePath = "nix/package.nix";

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

async function fetchText(url) {
  const response = await fetch(url);
  if (!response.ok) {
    fail(`failed to fetch ${url}: HTTP ${response.status}`);
  }
  return await response.text();
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    fail(`failed to fetch ${url}: HTTP ${response.status}`);
  }
  return await response.json();
}

const packageNix = await Bun.file(packagePath).text();
const entireVersion = packageNix.match(/^\s*version = "([0-9]+\.[0-9]+\.[0-9]+)";/m)?.[1];
if (!entireVersion) {
  fail(`could not read entire version from ${packagePath}`);
}

const goModUrl = `https://raw.githubusercontent.com/entireio/cli/v${entireVersion}/go.mod`;
const goMod = await fetchText(goModUrl);
const goVersion =
  goMod.match(/^toolchain\s+go([0-9]+\.[0-9]+\.[0-9]+)$/m)?.[1] ??
  goMod.match(/^go\s+([0-9]+\.[0-9]+\.[0-9]+)$/m)?.[1];

if (!goVersion) {
  fail(`could not read Go version from ${goModUrl}`);
}

if (!goVersion.startsWith("1.26.")) {
  fail(
    `entire ${entireVersion} requires Go ${goVersion}, but package.nix currently supports only Go 1.26.x automation`,
  );
}

const goReleaseVersion = `go${goVersion}`;
const goReleases = await fetchJson("https://go.dev/dl/?mode=json&include=all");
const goRelease = goReleases.find((release) => release.version === goReleaseVersion);
const goSource = goRelease?.files.find((file) => file.filename === `${goReleaseVersion}.src.tar.gz`);

if (!goSource?.sha256) {
  fail(`go.dev release metadata does not list ${goReleaseVersion}.src.tar.gz`);
}

const goSrcHash = (
  await $`nix hash convert --hash-algo sha256 --to sri ${goSource.sha256}`.text()
).trim();

if (!/^\s*goVersion = ".*?";/m.test(packageNix)) {
  fail(`missing goVersion assignment in ${packagePath}`);
}

let updatedPackageNix = packageNix.replace(
  /^\s*goVersion = ".*?";/m,
  `  goVersion = "${goVersion}";`,
);

if (!/^\s*goSrcHash = ".*?";/m.test(updatedPackageNix)) {
  fail(`missing goSrcHash assignment in ${packagePath}`);
}

const packageNixWithHash = updatedPackageNix.replace(
  /^\s*goSrcHash = ".*?";/m,
  `  goSrcHash = "${goSrcHash}";`,
);

await Bun.write(packagePath, packageNixWithHash);
console.log(`updated Go toolchain pin for entire ${entireVersion} to Go ${goVersion}`);
