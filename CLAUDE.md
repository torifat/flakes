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
| `flake.nix` | Flake outputs: overlay, packages (platform-filtered), devShell, homeManagerModules |
| `broken.nix` | List of package names to exclude from discovery |
| `scripts/update-readme.sh` | Generates package list in README via `nix eval` |

## Conventions

- Each package dir has a `default.nix`, optionally a `hm-module.nix` for home-manager
- Packages accept `mySource` arg from overlay (has `.pname`, `.version`, `.src`)
- To add multi-arch support: add `<pkg>-<system>` entry in `nvfetcher.toml` — no package changes needed
- Dev tools: `nix develop` gives nvfetcher, nixfmt, nil, deadnix, statix
- Update sources: `nix develop --command nvfetcher`
- Format: `nix fmt`

## CI (`.github/workflows/`)

- **check.yml**: Runs `nix flake check` on push/PR
- **update.yml**: Cron every 6h — runs nvfetcher, updates README package list, commits only if changes detected with descriptive commit message (single change → direct message, multiple → "Auto update:" list)
