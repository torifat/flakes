{
  stdenv,
  lib,
  makeWrapper,
  bun,
  mySource,
  ...
}:

stdenv.mkDerivation rec {
  inherit (mySource) pname version src;

  nativeBuildInputs = [ makeWrapper ];

  # Since the source is a single file, we don't need to unpack it
  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib/${pname}

    cp $src $out/lib/${pname}/${pname}.js

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
