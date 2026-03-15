{
  stdenvNoCC,
  lib,
  unzip,
  mySource,
}:

stdenvNoCC.mkDerivation {
  inherit (mySource) pname version src;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    install -Dm644 *.ttf -t $out/share/fonts/googlesans-code

    runHook postInstall
  '';

  meta = {
    description = "Google Sans Code variable fonts (Roman + Italic)";
    homepage = "https://github.com/googlefonts/googlesans-code";
    license = lib.licenses.ofl; # OFL-1.1
    platforms = lib.platforms.all;
  };
}
