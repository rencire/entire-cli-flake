# entire-cli flake

Minimal Nix flake for packaging [entireio/cli](https://github.com/entireio/cli).

## Use

Build and run locally:

```bash
nix build
./result/bin/entire --help
```

Run directly from the local flake:

```bash
nix run .# -- --help
nix run .#entire -- --help
```

Run without cloning the repo:

```bash
nix run github:rencire/entire-cli-flake -- --help
nix run github:rencire/entire-cli-flake#entire -- --help
```

## Use From Another Flake

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

## Update

When upstream releases a new version:

1. Update `version`, `rev`, and `hash` in [`package.nix`](./package.nix).
2. Rebuild to refresh `vendorHash`.
