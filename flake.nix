{
  # Based on https://github.com/bobvanderlinden/templates/blob/master/ruby/flake.nix
  # Useage: see README.md

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        ruby = nixpkgs.legacyPackages.${system}.ruby_3_4;
        pkgs = nixpkgs.legacyPackages.${system};
        myRubyPackage = pkgs.bundlerEnv {
          inherit ruby;
          name = "gemset";
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
        };
      in
      {

        defaultPackage = myRubyPackage;

        # used by nix shell and nix develop
        devShell =
          with pkgs;
          mkShell {
            buildInputs = [
              ruby
              bundix
            ];
          };
      }
    );
}
