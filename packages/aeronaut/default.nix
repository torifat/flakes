{
  lib,
  stdenv,
  unzip,
  mySource,
}:
stdenv.mkDerivation {
  inherit (mySource) pname version src;

  dontConfigure = true;
  dontBuild = true;
  # stripping invalidates the ad-hoc code signature
  dontFixup = true;

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R *.app $out/Applications/

    runHook postInstall
  '';

  meta = with lib; {
    description = "SwiftUI status bar for macOS and AeroSpace, with animated workspace and calendar pills";
    homepage = "https://github.com/torifat/aeronaut";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    license = licenses.mit;
    maintainers = with maintainers; [ torifat ];
  };
}
