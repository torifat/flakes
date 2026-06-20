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

  nativeBuildInputs = [ unzip ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R *.app $out/Applications/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight Markdown app to help you write great sentences";
    homepage = "https://github.com/tw93/MiaoYan";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    license = licenses.mit;
    maintainers = with maintainers; [ torifat ];
  };
}
