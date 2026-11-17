{
  lib,
  rustPlatform,
  mySource,
  basePackage,
  ...
}:
# buildInputs come from the nixpkgs recipe. An earlier override here replaced
# the list and so dropped `aws-lc`, which nixpkgs added later. The cargo setup
# hook sets AWS_LC_SYS_USE_SYSTEM=1, so aws-lc-sys (pulled in by 0.3.4) then
# failed to find a system AWS-LC.
basePackage.overrideAttrs (oldAttrs: {
  cargoDeps = rustPlatform.importCargoLock mySource.cargoLock."Cargo.lock";
  src = mySource.src;
  version = mySource.version;
  meta = oldAttrs.meta // {
    platforms = lib.platforms.linux;
  };
})
