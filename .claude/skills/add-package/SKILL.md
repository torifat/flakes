---
name: add-package
description: Add a new package to this Nix flakes repo. Use when the user wants to package a new tool/app (e.g. "add <tool> as a package", "package <github repo>", "add the brew/cargo/go binary X"). Handles nvfetcher source setup, the package default.nix, README/source regeneration, and verification.
---

# Add a Package

Add a new package to this flakes repo end-to-end: source definition, build, verification, and bookkeeping. Read `CLAUDE.md` first — it describes the auto-discovery, multi-arch, and platform-filtering architecture this skill relies on.

## Golden rules

- **Match an existing package.** Pick the closest sibling from the **Package types** table below and mirror its style — copy the sibling's `default.nix` as your starting point.
- **Name the package in kebab-case.** Lowercase the upstream name with hyphens at word boundaries, splitting CamelCase too (e.g. `OpenSuperWhisper` → `open-super-whisper`). This single `<name>` is the nvfetcher entry, the `packages/<name>/` dir, and the `pname`.
- **`git add` new/changed files before any `nix build` or `nix flake check`.** Flakes only see git-tracked files; an untracked `packages/<name>/default.nix` produces `does not provide attribute 'packages.<system>.<name>'`. This is the #1 gotcha.
- **Packages receive `mySource`** (has `.pname`, `.version`, `.src`) from the overlay — use `inherit (mySource) pname version src;`. `basePackage` is also injectable for overrideAttrs-style packages.
- **Set `meta.platforms`** accurately. `flake.nix` filters packages per system from this, so `nix flake check` passes on all systems. macOS-only tools → `platforms.darwin`. Also set `meta.license`, `meta.maintainers = [ torifat ]`, `meta.homepage`, `meta.description`, and `meta.mainProgram`.

## Package types

Pick the closest sibling, mirror it, and read the linked example file **only** for the type you're packaging (don't load all of them):

| Package type | Closest sibling | Example |
|---|---|---|
| Prebuilt binary tarball | `packages/pvetui` (multi-arch: `browserpass`) | mirror the sibling |
| Rust / cargo from source | `packages/television` (nvfetcher `cargo_lock`) | mirror the sibling |
| Go / Bash+Go hybrid / custom build | — | [`examples/go-hybrid.md`](examples/go-hybrid.md) |
| macOS GUI `.app` bundle (`.dmg`/`.zip`) | `packages/miaoyan` (dmg/AppImage split: `awakened-poe-trade`) | [`examples/macos-app.md`](examples/macos-app.md) |

## Workflow

### 1. Investigate upstream

Determine: language/build system, whether prebuilt binaries exist, the release tag format, platforms, license, and the real install layout. Use the GitHub API for assets and tags:

```
curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest | grep -E '"(tag_name|name|browser_download_url)"'
```

For non-trivial tools, **look at how it actually installs** — download the source tarball and read the entry script and any Homebrew formula (`https://raw.githubusercontent.com/Homebrew/homebrew-core/master/Formula/<first-letter>/<name>.rb`). The formula's `install` block is the canonical layout to replicate (where the entrypoint, libs, helper binaries, and symlinks go).

### 2. Add the nvfetcher source (`nvfetcher.toml`)

```toml
[<name>]
src.github = "<owner>/<repo>"
# src.prefix = "v"   # strip a leading v/V so version is clean (e.g. 1.2.3)
fetch.url = "https://github.com/<owner>/<repo>/releases/download/v$ver/<asset>"
```

- `$ver` is the version **after** `src.prefix` stripping.
- **`fetch.github` + `src.prefix` is broken**: `fetch.github` uses the bare (stripped) version as the git rev, so a `V1.2.3` tag becomes a 404 for rev `1.2.3`. When the tag has a prefix you want stripped, use `fetch.url` with the archive URL and re-add the prefix there:
  `fetch.url = "https://github.com/<owner>/<repo>/archive/refs/tags/V$ver.tar.gz"`.
  (`fetch.github` is only clean when the tag *is* the bare version — see `television`.)
- Multi-arch: add a second entry `[<name>-<system>]` (e.g. `pvetui-x86_64-linux`) with the arch-specific asset. The overlay auto-swaps `mySource.src` per system; the package needs no changes. See the CLAUDE.md multi-arch convention.
- Rust from source: `fetch.github = "<owner>/<repo>"` + `cargo_lock = ["Cargo.lock"]`.

Regenerate sources:

```
nix develop --command nvfetcher -f nvfetcher.toml
```

Confirm the new entry in `_sources/generated.nix` (do not hand-edit that file). If the run fails inside an **unrelated** package (e.g. a `cargo_lock`/`Cargo.lock` extraction for another entry), it's usually transient — just re-run; your entry still updates.

### 3. Write `packages/<name>/default.nix`

Prebuilt binary (simplest — copy `packages/pvetui/default.nix`): `stdenv.mkDerivation` with `inherit (mySource) pname version src;`, `sourceRoot = ".";`, and an `installPhase` that copies the binary into `$out/bin`.

For a from-source or app-bundle build, read the matching example file from the **Package types** table. Keep comments matching the terse style of sibling packages.

### 4. Build, iterate on hashes

```
git add packages/<name> nvfetcher.toml _sources/generated.nix
nix build .#<name>
```

- For `buildGoModule`/`buildRustPackage`/`importCargoLock`, start `vendorHash`/hash with a fake (`sha256-AAAA...AAA=` 44 chars) and copy the `got:` value from the mismatch error into the file.
- Inspect the result tree: `find -L result -maxdepth 3 | sort`.
- Run it: `./result/bin/<mainProgram> --version` (and any symlink aliases).

### 5. Finalize

```
nix fmt packages/<name>/default.nix  # pass the path — bare 'nix fmt' reads stdin and hangs
bash scripts/update-readme.sh        # regenerates the README package table
git add -A
nix flake check                      # must end with "all checks passed!"
```

`nix flake check` warns it omits incompatible systems (e.g. x86_64-linux for darwin-only) — that's expected and correct; the platform filter is doing its job.

### 6. Commit

Once `nix flake check` passes, commit the change (commit only — do **not** push or open a PR unless the user asks):

```
git add -A
git commit -m ":package: Add new package <name> <version>"
```

Use the new package's `<name>` and `<version>` (e.g. `:package: Add new package open-super-whisper 0.1.0`). The `update.yml` cron keeps versions current automatically once merged.
