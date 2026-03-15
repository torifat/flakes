# Packages

Each subdirectory in `packages/` is discovered automatically by `overlays/default.nix` and exposed as a package attribute with the same name as the directory.

For example:

- `packages/atlas` -> `pkgs.atlas`
- `packages/worktrunk` -> `pkgs.worktrunk`

## Build a single package

This flake does not export packages directly under `.#<name>`, so the easiest way to build one package is to import the flake's overlay and build the package attribute from that package set.

Replace `atlas` below with the package you want to build:

```sh
nix build --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.atlas
'
```

That will create a `result` symlink for the built package.

## Useful debugging commands

### Show build logs

```sh
nix build -L --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.atlas
'
```

### Keep failed build directories around

```sh
nix build -L --keep-failed --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.atlas
'
```

### Dry-run a build

```sh
nix build --dry-run --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.atlas
'
```

### Inspect package metadata in eval

```sh
nix eval --impure --raw --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.atlas.pname
'
```

### Print the current build directory

If you want to see the current working directory inside a Nix build, temporarily add a hook like this to the package's `default.nix`:

```nix
postPatch = ''
  echo "PWD during build: $PWD"
  echo "src: $src"
  ls -la
  find . -maxdepth 2 | sort
'';
```

If you want to print it from the main build step instead, you can temporarily override `buildPhase`:

```nix
buildPhase = ''
  runHook preBuild

  echo "PWD during build: $PWD"
  echo "src: $src"
  ls -la
  find . -maxdepth 2 | sort

  # existing build commands go here

  runHook postBuild
'';
```

Then rebuild with logs enabled:

```sh
nix build -L --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import flake.inputs.nixpkgs {
    system = "aarch64-darwin";
    overlays = [ flake.overlays.default ];
    config.allowUnfree = true;
  };
in
pkgs.prek
'
```

Notes:

- `$PWD` is usually the unpacked source directory inside the Nix sandbox, not your local repo checkout.
- `postUnpack`, `postPatch`, or `buildPhase` are all reasonable places to print it, depending on what you want to inspect.
- Add `--keep-failed` if you also want Nix to preserve failed build directories for inspection.

## Where package sources come from

Most package sources are wired through `nvfetcher`:

- source definitions live in `nvfetcher.toml`
- generated source metadata lives in `_sources/generated.nix` and `_sources/generated.json`
- package derivations usually consume that via the `mySource` argument

So if a package fetch or version looks wrong, check both the package's `default.nix` and the corresponding entry in `nvfetcher.toml`.
