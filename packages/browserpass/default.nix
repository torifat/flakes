{
  lib,
  stdenv,
  gnused,
  gnumake,
  mySource,
}:

let
  appId = "com.github.browserpass.native";
  binaryName =
    if stdenv.hostPlatform.isDarwin then "browserpass-darwin-arm64" else "browserpass-linux64";
  browsers = [
    "chromium"
    "chrome"
    "arc"
    "edge"
    "vivaldi"
    "yandex"
    "brave"
    "iridium"
    "slimjet"
    "firefox"
    "librewolf"
    "waterfox"
  ];
in
stdenv.mkDerivation {
  inherit (mySource) pname version src;

  nativeBuildInputs = [ gnused ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ${binaryName} $out/bin/browserpass

    sed -i 's|"path": ".*"|"path": "'$out'/bin/browserpass"|' browser-files/chromium-host.json
    sed -i 's|"path": ".*"|"path": "'$out'/bin/browserpass"|' browser-files/firefox-host.json

    install -Dm644 browser-files/chromium-host.json   $out/lib/browserpass/hosts/chromium/${appId}.json
    install -Dm644 browser-files/chromium-policy.json $out/lib/browserpass/policies/chromium/${appId}.json
    install -Dm644 browser-files/firefox-host.json    $out/lib/browserpass/hosts/firefox/${appId}.json
    install -Dm644 Makefile $out/lib/browserpass/Makefile

    # Wrapper script to register/deregister browser hosts with correct PREFIX
    cat > $out/bin/browserpass-setup <<SCRIPT
    #!/usr/bin/env bash
    BROWSERS="${lib.concatStringsSep " " browsers}"
    usage() {
      echo "Usage: browserpass-setup <browser>"
      echo "Registers browserpass native messaging host for the given browser."
      echo ""
      echo "Supported browsers: \$BROWSERS"
      exit 1
    }
    [[ \$# -ne 1 ]] && usage
    BROWSER="\$1"
    if ! echo "\$BROWSERS" | grep -qw "\$BROWSER"; then
      echo "Error: unsupported browser '\$BROWSER'"
      usage
    fi
    PREFIX='$out' ${gnumake}/bin/make hosts-"\$BROWSER"-user -f '$out/lib/browserpass/Makefile'
    SCRIPT
    chmod +x $out/bin/browserpass-setup

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
