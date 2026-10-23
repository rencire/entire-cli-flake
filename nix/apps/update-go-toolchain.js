#!/usr/bin/env bun

function newer(a, b) {
  const left = a.split(".").map(Number);
  const right = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) {
    if (left[i] !== right[i]) return left[i] > right[i] ? a : b;
  }
  return a;
}

export function updatePin(packageNix, goMod, releases) {
  const current = packageNix.match(/^\s*goVersion = "(\d+\.\d+\.\d+)";/m)?.[1];
  const minimum = goMod.match(/^go\s+(\d+\.\d+(?:\.\d+)?)(?:\s|$)/m)?.[1];
  const toolchain = goMod.match(/^toolchain\s+go(\d+\.\d+\.\d+)(?:\s|$)/m)?.[1];
  if (!current || !minimum) throw new Error("could not read package pin or go.mod Go requirement");
  const required = minimum.split(".").length === 2 ? `${minimum}.0` : minimum;
  // Preserve newer patch pins instead of downgrading to an older go.mod floor.
  const version = newer(current, newer(required, toolchain ?? required));
  if (!version.startsWith("1.27.")) {
    throw new Error(`Go ${version} needs a new Nixpkgs Go family; only 1.27.x is supported`);
  }
  const filename = `go${version}.src.tar.gz`;
  const source = releases.find((release) => release.version === `go${version}`)
    ?.files.find((file) => file.filename === filename && file.kind === "source");
  if (!/^[a-f0-9]{64}$/i.test(source?.sha256 ?? "")) {
    throw new Error(`go.dev release metadata does not list a valid hash for ${filename}`);
  }
  if (!/^\s*goSrcHash = "[^"]+";/m.test(packageNix)) {
    throw new Error("missing goSrcHash assignment in package.nix");
  }
  const hash = `sha256-${Buffer.from(source.sha256, "hex").toString("base64")}`;
  return packageNix
    .replace(/^([ \t]*)goVersion = "[^"]+";/m, `$1goVersion = "${version}";`)
    .replace(/^([ \t]*)goSrcHash = "[^"]+";/m, `$1goSrcHash = "${hash}";`);
}

async function fetchChecked(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`failed to fetch ${url}: HTTP ${response.status}`);
  return response;
}

if (import.meta.main) {
  try {
    const path = "nix/package.nix";
    const packageNix = await Bun.file(path).text();
    const version = packageNix.match(/^\s*version = "(\d+\.\d+\.\d+)";/m)?.[1];
    if (!version) throw new Error(`could not read Entire version from ${path}`);
    const goMod = await (await fetchChecked(
      `https://raw.githubusercontent.com/entireio/cli/v${version}/go.mod`,
    )).text();
    const releases = await (await fetchChecked("https://go.dev/dl/?mode=json&include=all")).json();
    const updated = updatePin(packageNix, goMod, releases);
    if (updated !== packageNix) await Bun.write(path, updated);
    console.log(`Go toolchain pin ready for Entire ${version}`);
  } catch (error) {
    console.error(`error: ${error.message}`);
    process.exitCode = 1;
  }
}
