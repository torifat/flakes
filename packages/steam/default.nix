{
  lib,
  stdenvNoCC,
  undmg,
  mySource,
  ...
}:

stdenvNoCC.mkDerivation {
  inherit (mySource) pname version src;

  nativeBuildInputs = [
    undmg
  ];

  unpackPhase = ''
    undmg $src
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R Steam.app $out/Applications/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Steam client for macOS (self-updating bootstrapper)";
    homepage = "https://store.steampowered.com/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    license = licenses.unfree;
  };
}
