{
  lib,
  buildGoModule,
  mySource,
}:
buildGoModule {
  inherit (mySource) pname version src;

  vendorHash = "sha256-HcCJ3DYj5AXX+E5AD6jxBysCq4TAoIs2I6oVN4dCBxQ=";

  # mole is a Bash CLI; the Go sources build the `analyze` and `status` helper
  # binaries that the shell scripts invoke as `analyze-go`/`status-go`.
  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [
    "-s"
    "-w"
  ];

  # Tests exercise macOS userland (e.g. BSD `du -I`) unavailable in the sandbox.
  doCheck = false;

  # Point the Bash entrypoint at the bundled libexec instead of resolving its
  # own location (mirrors the Homebrew formula).
  postInstall = ''
    substituteInPlace mole \
      --replace-fail \
        'SCRIPT_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"' \
        "SCRIPT_DIR='$out/libexec'"

    mkdir -p $out/libexec
    cp -r bin lib $out/libexec/
    mv $out/bin/analyze $out/libexec/bin/analyze-go
    mv $out/bin/status $out/libexec/bin/status-go

    install -Dm755 mole $out/bin/mole
    ln -s mole $out/bin/mo
  '';

  meta = with lib; {
    description = "macOS system maintenance utility: clean, uninstall, analyze, optimize, and monitor";
    homepage = "https://github.com/tw93/mole";
    mainProgram = "mole";
    platforms = platforms.darwin;
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ torifat ];
  };
}
