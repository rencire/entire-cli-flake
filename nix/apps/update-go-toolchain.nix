{ pkgs, ... }:
let
  script = pkgs.writeShellApplication {
    name = "update-go-toolchain";
    runtimeInputs = [
      pkgs.curl
      pkgs.nix
    ];
    text = builtins.readFile ../update-go-toolchain.sh;
  };
in
{
  type = "app";
  program = "${script}/bin/update-go-toolchain";
}
