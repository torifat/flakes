{
  lib,
  stdenvNoCC,
  runtimeShell,
  coreutils,
  mySource,
  steamRoot ? "$HOME/.local/share/steamcmd",
  ...
}:

stdenvNoCC.mkDerivation {
  inherit (mySource) pname version src;

  # The tarball has no top-level directory
  unpackPhase = ''
    mkdir steamcmd
    tar -xzf $src -C steamcmd
  '';

  sourceRoot = "steamcmd";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/steamcmd
    cp -R . $out/share/steamcmd/

    mkdir -p $out/bin
    substitute ${./steamcmd.sh} $out/bin/steamcmd \
      --subst-var out \
      --subst-var-by runtimeShell ${runtimeShell} \
      --subst-var-by coreutils ${coreutils} \
      --subst-var-by steamRoot '${steamRoot}'
    chmod 0755 $out/bin/steamcmd

    runHook postInstall
  '';

  meta = with lib; {
    description = "Steam command-line tools for macOS (self-updating bootstrapper; x86_64 via Rosetta)";
    homepage = "https://developer.valvesoftware.com/wiki/SteamCMD";
    mainProgram = "steamcmd";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    license = licenses.unfreeRedistributable;
  };
}
