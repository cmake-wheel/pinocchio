{
  description = "Fast and flexible implementation of Rigid Body Dynamics algorithms and their analytical derivatives.";

  inputs = {
    coal.url = "github:nim65s/coal/only-py";
    flake-parts.follows = "coal/flake-parts";
    nixpkgs.follows = "coal/nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          inputs',
          pkgs,
          self',
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                coal = inputs'.coal.packages.coal-cpp;
                pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                  (python-final: python-prev: {
                    coal = inputs'.coal.packages.coal-py;
                  })
                ];
              })
            ];
          };
          apps.default = {
            type = "app";
            program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
          };
          packages = {
            default = self'.packages.pinocchio;
            pinocchio = pkgs.python3Packages.toPythonModule (
              pkgs.pinocchio.overrideAttrs (super: {
                cmakeFlags = super.cmakeFlags ++ [ "-DCOAL_DISABLE_HPP_FCL_WARNINGS=ON" ];
                src = pkgs.lib.fileset.toSource {
                  root = ./.;
                  fileset = pkgs.lib.fileset.unions [
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
              })
            );
            pinocchio-cpp =
              (self'.packages.pinocchio.override { pythonSupport = false; }).overrideAttrs
                (super: {
                  src = pkgs.lib.fileset.toSource {
                    root = ./.;
                    fileset = pkgs.lib.fileset.unions [
                      ./benchmark
                      # ./bindings
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
            pinocchio-py = (self'.packages.pinocchio.override { pythonSupport = true; }).overrideAttrs (super: {
              cmakeFlags = super.cmakeFlags ++ [ "-DBUILD_STANDALONE_PYTHON_INTERFACE=ON" ];
              src = pkgs.lib.fileset.toSource {
                root = ./.;
                fileset = pkgs.lib.fileset.unions [
                  ./benchmark
                  ./bindings
                  ./CMakeLists.txt
                  ./doc
                  ./examples
                  ./include
                  ./models
                  ./package.xml
                  ./sources.cmake
                  # ./src
                  ./unittest
                  ./utils
                ];
              };
              propagatedBuildInputs = super.propagatedBuildInputs ++ [
                self'.packages.pinocchio-cpp
              ];
            });
          };
        };
    };
}
