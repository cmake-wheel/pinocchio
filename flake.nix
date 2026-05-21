{
  description = "Fast and flexible implementation of Rigid Body Dynamics algorithms and their analytical derivatives.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, lib, ... }:
      {
        systems = lib.systems.flakeExposed;
        flake.overlays = {
          default = final: prev: {
            pinocchio = prev.pinocchio.overrideAttrs (super: {
              src = lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.unions [
                  ./benchmark
                  ./bindings
                  ./CMakeLists.txt
                  ./doc
                  ./examples
                  ./include
                  ./models
                  ./package.xml
                  ./sources.cmake
                  ./src
                  ./unittest
                  ./utils
                ];
              };
            });
          };
        };
        perSystem =
          {
            inputs',
            pkgs,
            self',
            system,
            ...
          }:
          {
            _module.args = {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [
                  self.overlays.default
                ];
              };
            };
            apps.default = {
              type = "app";
              program = pkgs.python3.withPackages (p: [
                self'.packages.default
                p.example-robot-data
                p.meshcat
                p.viser
              ]);
            };
            packages = {
              default = self'.packages.pinocchio-py;
              pinocchio = pkgs.python3Packages.pinocchio.override { buildStandalone = false; };
              libpinocchio = pkgs.pinocchio;
              pinocchio-py = pkgs.python3Packages.pinocchio;
            };
          };
      }
    );
}
