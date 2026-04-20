# entire-cli flake

Minimal Nix flake for packaging [entireio/cli](https://github.com/entireio/cli).

## Use

Run it without cloning the repo:

```bash
nix run github:rencire/entire-cli-flake -- --help
nix run github:rencire/entire-cli-flake#entire -- --help
```

Run it from a local checkout:

```bash
nix run .# -- --help
nix run .#entire -- --help
```

## Use in Another Flake

Agent prompt for wiring this flake into a consumer project:

> Add `entire-cli-flake` as a flake input, expose `packages.${system}.entire` from the consumer flake, and include the package in the default dev shell.

Example code:

```nix
{
  inputs.entire-cli-flake.url = "github:rencire/entire-cli-flake";

  outputs = { self, nixpkgs, entire-cli-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system}.default = entire-cli-flake.packages.${system}.entire;

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          entire-cli-flake.packages.${system}.entire
        ];
      };
    };
}
```

## Build

Build and run locally if you want the installed symlink instead of `nix run`:

```bash
nix build
./result/bin/entire --help
```

## Update

When upstream releases a new version:

1. Update `version` and `hash` in [`package.nix`](./package.nix).
2. Rebuild to refresh `vendorHash`.
