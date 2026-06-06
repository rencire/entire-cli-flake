{ pkgs, ... }:
let
  script = pkgs.writeShellApplication {
    name = "update-go-toolchain";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.nix
      pkgs.perl
    ];
    text = builtins.readFile ../update-go-toolchain.sh;
  };
in
{
  type = "app";
  program = "${script}/bin/update-go-toolchain";
}
