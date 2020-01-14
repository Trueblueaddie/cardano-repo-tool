############################################################################
# cardano-repo-tool Nix build
#
# fixme: document top-level attributes and how to build them
#
############################################################################

{ system ? builtins.currentSystem
, crossSystem ? null
, config ? {}
# allows to override dependencies of the project without modifications,
# eg. to test build against local checkout of nixpkgs and iohk-nix:
# nix build -f default.nix iohk-skeleton --arg sourcesOverride '{
#   iohk-nix = ./../iohk-nix;
#   nixpkgs  = ./../nixpkgs;
# }'
, sourcesOverride ? {}
# pinned version of nixpkgs augmented with iohk overlays.
, pkgs ? import ./nix {
    inherit system crossSystem sourcesOverride;
  }
}:
let
  # commonLib include iohk-nix utilities and nixpkgs lib.
  inherit (pkgs) commonLib;
  haskell = pkgs.callPackage commonLib.nix-tools.haskell {};
  src = commonLib.cleanSourceHaskell ./.;
  util = import ./nix/util.nix { inherit pkgs; };

  # Example of using a package from iohk-nix
  # TODO: Declare packages required by the build.
  inherit (commonLib.rust-packages.pkgs) jormungandr;

  # Import the Haskell package set.
  haskellPackages = import ./nix/pkgs.nix {
    inherit pkgs haskell src;
    # Pass in any extra programs necessary for the build as function arguments.
    # TODO: Declare packages required by the build.
    # jormungandr and cowsay are just examples and should be removed for your
    # project, unless needed.
    inherit jormungandr;
    inherit (pkgs) cowsay;
    # Provide cross-compiling secret sauce
    inherit (commonLib.nix-tools) iohk-extras iohk-module;
  };

in {
  inherit (haskellPackages.cardano-repo-tool.identifier) version;
  inherit pkgs commonLib src haskellPackages;

  # Grab the executable component of our package.
  inherit (haskellPackages.cardano-repo-tool.components.exes) cardano-repo-tool;

  tests = util.collectComponents "tests" util.isIohkSkeleton haskellPackages;
  benchmarks = util.collectComponents "benchmarks" util.isIohkSkeleton haskellPackages;

  # This provides a development environment that can be used with nix-shell or
  # lorri. See https://input-output-hk.github.io/haskell.nix/user-guide/development/
  shell = haskellPackages.shellFor {
    name = "cardano-repo-tool-shell";
    # TODO: List all local packages in the project.
    packages = ps: with ps; [
      cardano-repo-tool
    ];
    # These programs will be available inside the nix-shell.
    buildInputs =
      with pkgs.haskellPackages; [ hlint stylish-haskell weeder ghcid lentil ]
      # TODO: Add your own packages to the shell.
      ++ [ jormungandr ];
  };

  # Example of a linting script used by Buildkite.
  checks.lint-fuzz = pkgs.callPackage ./nix/check-lint-fuzz.nix {};

  # Attrset of PDF builds of LaTeX documentation.
  docs = pkgs.callPackage ./docs/default.nix {};
}
