{
  lib,
  stdenv,
  undmg,
  appimageTools,
  mySource,
  ...
}:

if stdenv.hostPlatform.isDarwin then
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
      description = "Path of Exile trading companion tool";
      homepage = "https://github.com/SnosMe/awakened-poe-trade";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      license = licenses.mit;
      maintainers = with maintainers; [ torifat ];
    };
  }
else
  let
    appimageContents = appimageTools.extract {
      inherit (mySource) pname version src;
    };
  in
  appimageTools.wrapType2 rec {
    inherit (mySource) pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun --sandbox %U' 'Exec=${pname} %U'

      install -m 444 -D ${appimageContents}/awakened-poe-trade.png $out/share/icons/hicolor/128x128/apps/${pname}.png
    '';

    meta = with lib; {
      description = "Path of Exile trading companion tool";
      homepage = "https://github.com/SnosMe/awakened-poe-trade";
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      license = licenses.mit;
      maintainers = with maintainers; [ torifat ];
    };
  }
