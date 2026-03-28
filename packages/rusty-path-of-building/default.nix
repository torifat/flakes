
{
  lib,
  rustPlatform,
  mySource,
  basePackage,
  ...
}:
basePackage.overrideAttrs (oldAttrs: {
  cargoDeps = rustPlatform.importCargoLock mySource.cargoLock."Cargo.lock";
  src = mySource.src;
  version = mySource.version;
  meta = oldAttrs.meta // {
    platforms = lib.platforms.linux;
  };
})
