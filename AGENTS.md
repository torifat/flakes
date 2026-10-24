# Flakes Repository

Nix flake repo for custom packages with auto-updating sources via nvfetcher.

## Architecture

- **Package discovery**: `overlays/default.nix` auto-discovers `packages/*/default.nix` dirs, subtracts `broken.nix` list
- **Source management**: nvfetcher (`nvfetcher.toml`) manages all package sources → `_sources/generated.nix`
- **Multi-arch convention**: nvfetcher entries named `<pkg>-<system>` (e.g. `pvetui-x86_64-linux`) provide arch-specific sources. The overlay auto-swaps `mySource.src` per system — packages just use `mySource` unaware of arch differences
- **Platform filtering**: `flake.nix` filters `packages.<system>` by `meta.platforms` so `nix flake check` works on all systems (e.g. darwin-only packages excluded from x86_64-linux)
- **README package list**: Auto-generated between `<!-- pkgs start -->` / `<!-- pkgs end -->` markers via `scripts/update-readme.sh`

## Key Files

| File | Purpose |
|------|---------|
| `nvfetcher.toml` | Source definitions (GitHub releases, manual versions) |
| `_sources/generated.nix` | nvfetcher output (hashes, URLs) — do not edit manually |
| `overlays/default.nix` | Package overlay with auto-discovery + multi-arch mySource logic |
| `flake.nix` | Flake outputs: overlay, packages (platform-filtered), devShell, homeManagerModules, darwinModules; `nixConfig` advertises the binary cache |
| `broken.nix` | List of package names to exclude from discovery |
| `scripts/update-readme.sh` | Generates package list in README via `nix eval` |

## Conventions

- Each package dir has a `default.nix`, optionally a `hm-module.nix` for home-manager or a `darwin-module.nix` for nix-darwin
- Packages accept `mySource` arg from overlay (has `.pname`, `.version`, `.src`), and `basePackage` (the nixpkgs package of the same name) when overriding one
- To add multi-arch support: add `<pkg>-<system>` entry in `nvfetcher.toml` — no package changes needed
- Dev tools: `nix develop` gives nvfetcher, nixfmt, nil, deadnix, statix
- Update sources: `nix develop --command nvfetcher`
- Format: `nix fmt`

## Gotchas

- nvfetcher bumps versions but not Go `vendorHash` (e.g. `mole`). After a bump, CI fails with a fixed-output hash mismatch; copy the `got:` hash into the package. Rust packages use nvfetcher's `cargo_lock`, so their hashes update automatically
- `basePackage.overrideAttrs` packages (e.g. `rusty-path-of-building`) inherit the nixpkgs recipe, which can lag upstream. When upstream restructures, override the affected attrs (`buildInputs`, phases) rather than waiting for nixpkgs
- Linux-only packages can't be built on macOS; push and let CI's ubuntu job build them

## Binary cache

- CI pushes every built package to the public Cachix cache `rifat` (`https://rifat.cachix.org`, key `rifat.cachix.org-1:fGsDn1VSmzo+Fgz55h+Glc3zT6GXCdyD3EVbdAOw0co=`, Cachix-managed signing). Pushing needs the `CACHIX_AUTH_TOKEN` repo secret
- The overlay builds against the consumer's nixpkgs, so consumers only get cache hits when their nixpkgs matches this flake's `flake.lock`. Downstream configs (e.g. torifat/nix-den) set `nixpkgs.follows = "flakes/nixpkgs"`; that's why CI keeps nixpkgs current. Changing the `nixpkgs` input here changes what every consumer builds against

## CI (`.github/workflows/`)

Both workflows build on `ubuntu-latest` and `macos-latest` with `fail-fast: false`: they run `nix flake check`, then build every `packages.<system>` entry with `--keep-going` (flake check alone doesn't build packages), and `cachix-action` pushes the outputs.

- **check.yml**: Runs on push/PR
- **update.yml**: Cron every 6h (also `workflow_dispatch`)
  1. `nix flake update nixpkgs`, committed separately as `nixpkgs: <old> -> <new>`
  2. nvfetcher, README package list, then one commit (single change → nvfetcher's line, e.g. `aeronaut: 0.1.0 → 0.1.1`; multiple → `N packages updated: a, b & more` plus the list)
  3. If either step committed, a `check` job builds and caches `main`. It's needed because commits pushed with `GITHUB_TOKEN` don't trigger check.yml
