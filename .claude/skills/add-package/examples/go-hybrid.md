# Go (Bash+Go hybrid) example

Referenced from [`../SKILL.md`](../SKILL.md) → "Package types" table. Use for a `buildGoModule` (pure Go) or a Bash CLI that shells out to Go helper binaries.

From packaging `mole` (a Bash CLI whose shell scripts shell out to Go helper binaries). Mirrors the Homebrew formula: build the Go helpers, point the entrypoint at a bundled `libexec`, install the script with an alias.

```nix
{
  lib,
  buildGoModule,
  mySource,
}:
buildGoModule {
  inherit (mySource) pname version src;

  vendorHash = "sha256-...";   # fake first, paste the `got:` value

  subPackages = [
    "cmd/analyze"
    "cmd/status"
  ];

  ldflags = [ "-s" "-w" ];

  # Upstream tests need macOS userland (e.g. BSD `du -I`); sandbox has GNU coreutils.
  doCheck = false;

  # cwd at postInstall is the unpacked source root; helper binaries land in $out/bin.
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
    description = "...";
    homepage = "https://github.com/<owner>/<repo>";
    mainProgram = "<name>";
    platforms = platforms.darwin;
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ torifat ];
  };
}
```

Lessons baked in above:
- `buildGoModule` needs a Go ≥ the `go.mod` directive; nixpkgs default Go is usually new enough — verify with `nix eval --raw nixpkgs#go.version` if a build complains.
- Disable upstream test suites that assume macOS userland with `doCheck = false`.
- A from-source Go archive (`.../archive/refs/tags/V$ver.tar.gz`) unpacks to a single `<Repo>-<ver>/` dir; stdenv auto-detects it as `sourceRoot`, so relative paths in `postInstall` just work.
- `-X main.Version=...` ldflags are harmless if the symbol doesn't exist (Go linker ignores unknown `-X`), but only add them if upstream actually declares the var.
