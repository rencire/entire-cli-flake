{
  description = "Standalone flake packaging entireio/cli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      eachSystem = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          entire = pkgs.callPackage ./package.nix { };
        in
        {
          default = entire;
          entire = entire;
        });

      apps = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          entire = pkgs.callPackage ./package.nix { };
        in
        {
          default = {
            type = "app";
            program = "${pkgs.lib.getExe entire}";
          };
        });

      formatter = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixpkgs-fmt);

      devShells = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          entire = pkgs.callPackage ./package.nix { };
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ entire ];
            packages = with pkgs; [
              git
            ];
          };
        });
    };
}
