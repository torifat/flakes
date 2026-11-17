{
  appimageTools,
  pkgs,
  mySource,
  ...
}:
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
    for icon in ${appimageContents}/usr/share/icons/hicolor/*/apps/${pname}.png; do
      size=$(basename "$(dirname "$icon")")
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/${pname}.png"
    done
  '';

  extraPkgs = pkgs: [ pkgs.fuse ];
  meta = with pkgs.lib; {
    description = "Price checker overlay for Path of Exile 2";
    homepage = "https://kvan7.github.io/Exiled-Exchange-2";
    license = licenses.unfreeRedistributable;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
