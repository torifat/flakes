{
  lib,
  stdenv,
  mySource,
  ...
}:
stdenv.mkDerivation rec {
  inherit (mySource) pname version src;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes
    cp -r themes/* $out/share/sddm/themes/

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/Darkkal44/qylock";
    description = "Qylock SDDM themes";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
