{
  lib,
  stdenv,
  mySource,
}:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;
  mainProgram = "wt";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./${mainProgram} $out/bin/${mainProgram}
    chmod +x $out/bin/${mainProgram}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Worktrunk is a CLI for Git worktree management, designed for parallel AI agent workflows";
    homepage = "https://github.com/max-sixty/worktrunk";
    inherit mainProgram;
    platforms = platforms.darwin;
    license = licenses.mit;
    maintainers = with maintainers; [ torifat ];
  };
}
