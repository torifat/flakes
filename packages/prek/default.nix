{
  lib,
  stdenv,
  mySource,
}:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;

  # sourceRoot = ".";

  installPhase = ''
    runHook preBuild

    mkdir -p $out/bin
    cp ./${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}

    runHook postBuild
  '';

  meta = with lib; {
    description = "Better pre-commit, re-engineered in Rust";
    homepage = "https://github.com/j178/prek";
    mainProgram = pname;
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ torifat ];
  };
}
