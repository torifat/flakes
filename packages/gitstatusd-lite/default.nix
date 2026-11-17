{
  stdenvNoCC,
  lib,
  makeWrapper,
  git,
  coreutils,
  gnugrep,
  ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "gitstatusd-lite";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${pname}.sh $out/bin/${pname}
    chmod +x $out/bin/${pname}

    wrapProgram $out/bin/${pname} \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          coreutils
          gnugrep
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "Lightweight gitstatusd replacement for powerlevel10k";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
