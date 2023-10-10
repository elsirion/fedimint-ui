{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    fedimint = {
      # Snapshot of Fedimint after AlephBFT was merged: https://github.com/fedimint/fedimint/pull/3313
      url = "github:fedimint/fedimint?rev=a71267934a5ec2f0df28686fa21362386e762ca0";
    };
  };
  outputs = { self, nixpkgs, flake-utils, fedimint }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        fmLib = fedimint.lib.${system};

        guardian-ui = pkgs.mkYarnPackage rec {
          src = ./.;
          packageJSON = ./package.json;
          yarnLock = ./yarn.lock;

          configurePhase = ''
            cp -r $node_modules node_modules
            chmod +w node_modules
          '';
          buildPhase = ''
            set -xeuo pipefail
            export HOME=$(mktemp -d)
            cp -r $node_modules node_modules
            yarn --offline run build:guardian-ui
          '';
          distPhase = "true";
        };
      in
      {
        devShells = fmLib.devShells // {
          default = fmLib.devShells.default.overrideAttrs (prev: {
            nativeBuildInputs = [
              pkgs.mprocs
              pkgs.nodejs
              pkgs.yarn
              fedimint.packages.${system}.devimint
              fedimint.packages.${system}.gateway-pkgs
              fedimint.packages.${system}.fedimint-pkgs
            ] ++ prev.nativeBuildInputs;
          });
          ui = fmLib.devShells.default.overrideAttrs (prev: {
             nativeBuildInputs = [
               pkgs.nodejs
               pkgs.yarn
             ] ++ prev.nativeBuildInputs;
           });
        };
        packages.guardian = guardian-ui;
      });
}
