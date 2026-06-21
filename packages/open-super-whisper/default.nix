{
  lib,
  stdenv,
  undmg,
  mySource,
}:
stdenv.mkDerivation {
  inherit (mySource) pname version src;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R *.app $out/Applications/

    runHook postInstall
  '';

  meta = with lib; {
    description = "macOS dictation app";
    homepage = "https://github.com/Starmel/OpenSuperWhisper";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    license = licenses.mit;
    maintainers = with maintainers; [ torifat ];
  };
}
