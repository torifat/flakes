{
  lib,
  stdenv,
  mySource,
}:
stdenv.mkDerivation {
  inherit (mySource) pname version src;

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./${mySource.pname} $out/bin/${mySource.pname}
    chmod +x $out/bin/${mySource.pname}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal UI for Proxmox VE";
    homepage = "https://github.com/devnullvoid/pvetui";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    license = licenses.mit;
    maintainers = with maintainers; [ torifat ];
  };
}
