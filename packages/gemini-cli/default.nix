{
  stdenv,
  lib,
  unzip,
  makeWrapper,
  bun,
  mySource,
  ...
}:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib/${pname}

    cp -r . $out/lib/${pname}

    makeWrapper ${bun}/bin/bun $out/bin/gemini \
      --add-flags "run" \
      --add-flags "$out/lib/${pname}/${pname}.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Gemini CLI tool running on Bun";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
