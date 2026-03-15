{
  lib,
  stdenv,
  mySource,
}:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;

  buildPhase = ''
    runHook preBuild
    $CC -std=c99 -O3 helper.c -o helper
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    if [ ! -f "helper" ]; then
      echo "ERROR: helper binary not found after build"
      exit 1
    fi

    mkdir -p $out/bin
    cp helper $out/bin/${pname}
    chmod +x $out/bin/${pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Helper process for sketchybar status bar";
    longDescription = ''
      A helper process that provides system information to sketchybar.
      Compiled from C source and invoked by sketchybar configuration.
    '';
    homepage = "https://github.com/FelixKratz/SketchyBar";
    platforms = platforms.darwin;
    license = licenses.gpl3;
    maintainers = with maintainers; [ torifat ];
  };
}
