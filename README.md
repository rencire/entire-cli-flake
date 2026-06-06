# entire-cli flake

Minimal Nix flake for packaging [entireio/cli](https://github.com/entireio/cli).

## Use

Run it without cloning the repo:

```bash
nix run github:rencire/entire-cli-flake -- --help
```

Run it from a local checkout:

```bash
nix run .# -- --help
```

## Use in Another Flake

Agent prompt for wiring this flake into a consumer project:

> Add `entire-cli-flake` as a flake input, expose `packages.${system}.entire`
> from the consumer flake, and include the package in the default dev shell.

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

## Setup

After cloning this repo, run the setup apps to bootstrap AI agent tooling:

```bash
nix run .#setup-entire
nix run .#setup-gstack
```

These are one-shot setup commands — commit the generated files after running
them.

See `nix/config/setup-entire-config.nix` and
`nix/config/setup-gstack-config.nix` to configure agents, checkpoint remotes,
hosts, and team mode.

## Update

When upstream releases a new version:

1. Update `version` in [`nix/package.nix`](./nix/package.nix).
2. Run `nix run .#update-go-toolchain` to match upstream's Go requirement.
3. Run `nix run nixpkgs#nix-update -- --flake default --version skip` to refresh
   `hash` and `vendorHash`.
