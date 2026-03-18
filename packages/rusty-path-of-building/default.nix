
{
  rustPlatform,
  mySource,
  basePackage,
  ...
}:
basePackage.overrideAttrs (
  builtins.removeAttrs mySource [ "cargoLock" ]
  // {
    cargoDeps = rustPlatform.importCargoLock mySource.cargoLock."Cargo.lock";
  }
)
