import { expect, test } from "bun:test";
import { updatePin } from "./update-go-toolchain.js";

const packageNix = '  goVersion = "1.27.2";\n  goSrcHash = "old";\n  version = "0.11.5";\n';
const releases = [2, 3, 10].map((patch) => ({
  version: `go1.27.${patch}`,
  files: [{ kind: "source", filename: `go1.27.${patch}.src.tar.gz`, sha256: "ab".repeat(32) }],
}));

test("advances the pin for the failing Go 1.27.3 requirement", () => {
  const updated = updatePin(packageNix, "go 1.27.3\n", releases);
  expect(updated).toContain('goVersion = "1.27.3";');
  expect(updated).toContain(`goSrcHash = "sha256-${Buffer.from("ab".repeat(32), "hex").toString("base64")}";`);
  expect(updated).toContain('version = "0.11.5";');
});

test("retains a newer pin and is idempotent", () => {
  const updated = updatePin(packageNix, "go 1.27.1\n", releases);
  expect(updated).toContain('goVersion = "1.27.2";');
  expect(updatePin(updated, "go 1.27.1\n", releases)).toBe(updated);
});

test("honors toolchain suggestions using numeric patch ordering", () => {
  expect(updatePin(packageNix, "go 1.27\ntoolchain go1.27.10\n", releases))
    .toContain('goVersion = "1.27.10";');
});

test("does not let a lower toolchain suggestion override the minimum", () => {
  expect(updatePin(packageNix, "go 1.27.3\ntoolchain go1.27.1\n", releases))
    .toContain('goVersion = "1.27.3";');
});

test("rejects minor-family changes and unpublished releases", () => {
  expect(() => updatePin(packageNix, "go 1.28.0\n", releases)).toThrow("new Nixpkgs Go family");
  expect(() => updatePin(packageNix, "go 1.27.4\n", releases)).toThrow("valid hash");
});

test("rejects malformed inputs before updating metadata", () => {
  expect(() => updatePin(packageNix, "module example\n", releases)).toThrow("Go requirement");
  expect(() => updatePin(packageNix.replace('  goSrcHash = "old";\n', ""), "go 1.27.3\n", releases))
    .toThrow("missing goSrcHash");
  expect(() => updatePin(packageNix, "go 1.27.3\n", [{
    version: "go1.27.3", files: [{ kind: "source", filename: "go1.27.3.src.tar.gz", sha256: "bad" }],
  }])).toThrow("valid hash");
});
