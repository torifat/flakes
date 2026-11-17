{
  stdenvNoCC,
  lib,
  mySource,
}:

stdenvNoCC.mkDerivation {
  inherit (mySource) pname version src;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/opentype
    cp *.otf $out/share/fonts/opentype/
    runHook postInstall
  '';

  meta = with lib; {
    description = "SFMono Nerd Font Ligaturized";
    homepage = "https://github.com/shaunsingh/SFMono-Nerd-Font-Ligaturized";
    platforms = platforms.all;
  };
}
