{ pkgs, ... }:
let
  script = pkgs.writeShellApplication {
    name = "update-go-toolchain";
    runtimeInputs = [ pkgs.bun ];
    text = ''
      bun ./nix/apps/update-go-toolchain.js
    '';
  };
in
{
  type = "app";
  program = "${script}/bin/update-go-toolchain";
}
