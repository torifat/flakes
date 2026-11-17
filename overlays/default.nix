{
  lib,
  pkgDir ? ../packages,
  generated ? import ../_sources/generated.nix,
  broken ? import ../broken.nix,
  names ? null,
}:
let
  pkgEntries = builtins.readDir pkgDir;
  discoveredNames = builtins.filter (name: pkgEntries.${name} == "directory") (
    builtins.attrNames pkgEntries
  );
  packageNames = if names != null then names else lib.subtractLists broken discoveredNames;
  hmModules = builtins.map (name: pkgDir + "/${name}/hm-module.nix") (
    builtins.filter (name: builtins.pathExists (pkgDir + "/${name}/hm-module.nix")) packageNames
  );
  darwinModules = builtins.map (name: pkgDir + "/${name}/darwin-module.nix") (
    builtins.filter (name: builtins.pathExists (pkgDir + "/${name}/darwin-module.nix")) packageNames
  );
  overlay =
    final: prev:
    let
      sources = generated {
        inherit (final)
          fetchurl
          fetchgit
          fetchFromGitHub
          dockerTools
          ;
      };
      # Every package in ../packages, built for the host platform whether or
      # not it supports it.
      custom = lib.genAttrs packageNames (
        name:
        let
          system = final.stdenv.hostPlatform.system;
          basePackage = prev.${name} or null;
          baseSource = sources.${name} or null;
          archSource = sources."${name}-${system}" or null;
          mySource =
            if archSource != null
            then baseSource // { src = archSource.src; }
            else baseSource;
          pkg = import (pkgDir + "/${name}");
          override = builtins.intersectAttrs (builtins.functionArgs pkg) {
            inherit mySource basePackage;
          };
        in
        final.callPackage pkg override
      );
    in
    {
      inherit sources;
      # The packages as defined here, without the fallback below. flake.nix
      # and scripts/update-readme.sh read these, so a nixpkgs fallback never
      # ends up in the flake's `packages` output or the README.
      flakesPackages = custom;
    }
    # A package that shares its name with a nixpkgs one but doesn't support
    # the host platform (the macOS Steam app on Linux) would shadow a working
    # package with an unusable one. Keep the nixpkgs package there.
    // lib.mapAttrs (
      name: drv:
      if prev ? ${name} && !lib.meta.availableOn final.stdenv.hostPlatform drv then prev.${name} else drv
    ) custom;
in
{
  inherit overlay hmModules darwinModules packageNames;
}
