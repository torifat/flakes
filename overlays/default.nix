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
    in
    {
      inherit sources;
    }
    // lib.genAttrs packageNames (
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
  inherit overlay hmModules packageNames;
}
