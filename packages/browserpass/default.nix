{
  lib,
  stdenv,
  gnused,
  mySource,
}:

let
  appId = "com.github.browserpass.native";
  binaryName =
    if stdenv.hostPlatform.isDarwin then "browserpass-darwin-arm64" else "browserpass-linux64";
in
stdenv.mkDerivation {
  inherit (mySource) pname version src;

  nativeBuildInputs = [ gnused ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${binaryName} $out/bin/browserpass

    # Configure browser host JSON files with the correct binary path
    sed -i 's|"path": ".*"|"path": "'$out'/bin/browserpass"|' browser-files/chromium-host.json
    sed -i 's|"path": ".*"|"path": "'$out'/bin/browserpass"|' browser-files/firefox-host.json

    # Install browser host manifests and policy
    install -Dm644 browser-files/chromium-host.json   $out/lib/browserpass/hosts/chromium/${appId}.json
    install -Dm644 browser-files/chromium-policy.json $out/lib/browserpass/policies/chromium/${appId}.json
    install -Dm644 browser-files/firefox-host.json    $out/lib/browserpass/hosts/firefox/${appId}.json

    # Install Makefile for browser host registration
    install -Dm644 Makefile $out/lib/browserpass/Makefile

    runHook postInstall
  '';

  meta = with lib; {
    description = "Host application for browser extension providing access to your password store";
    homepage = "https://github.com/browserpass/browserpass-native";
    mainProgram = "browserpass";
    license = licenses.isc;
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    maintainers = with maintainers; [ torifat ];
  };
}
