{
  lib,
  rustPlatform,
  luajit,
  openssl,
  wayland,
  mySource,
  basePackage,
  ...
}:
basePackage.overrideAttrs (oldAttrs: {
  cargoDeps = rustPlatform.importCargoLock mySource.cargoLock."Cargo.lock";
  src = mySource.src;
  version = mySource.version;
  # 0.3.0+ bundles the Lua C modules (default `bundled-lua-modules` feature) and
  # dropped `lua/libs/lzip`, which older nixpkgs recipes still try to build.
  buildInputs = [
    luajit
    openssl
    wayland
  ];
  meta = oldAttrs.meta // {
    platforms = lib.platforms.linux;
  };
})
