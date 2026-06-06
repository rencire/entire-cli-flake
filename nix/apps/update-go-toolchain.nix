{ pkgs, ... }:
let
  script = pkgs.writeShellApplication {
    name = "update-go-toolchain";
    runtimeInputs = [
      pkgs.bun
      pkgs.nix
    ];
    text = ''
      bun ./nix/update-go-toolchain.js
    '';
  };
in
{
  type = "app";
  program = "${script}/bin/update-go-toolchain";
}
