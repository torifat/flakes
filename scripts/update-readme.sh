#!/usr/bin/env bash
# Updates the package list in README.md from flake package metadata.
# Requires: nix with flakes, and any source changes staged (so nix eval sees them).
# Usage: ./scripts/update-readme.sh [system]
set -euo pipefail

cd "$(dirname "$0")/.."

system="${1:-$(nix eval --raw --impure --expr 'builtins.currentSystem')}"

pkglist=$(nix eval --raw --impure --expr "
  let
    flake = builtins.getFlake (toString ./.);
    system = \"${system}\";
    pkgs = import flake.inputs.nixpkgs {
      inherit system;
      overlays = [ flake.overlays.default ];
      config.allowUnfree = true;
    };
    overlayData = import ./overlays/default.nix { lib = pkgs.lib; };
    names = builtins.sort builtins.lessThan overlayData.packageNames;
  in
  \"| Package | Version |\n|---------|---------|\" + \"\n\" +
  builtins.concatStringsSep \"\n\" (
    map (name:
      let
        pkg = pkgs.\${name};
        homepage = pkg.meta.homepage or \"\";
        version = pkg.version or \"unknown\";
      in
      \"| [\${name}](\${homepage}) | \`\${version}\` |\"
    ) names
  )
")

# Replace content between markers using sed
# 1. Print up to and including <!-- pkgs start -->
# 2. Insert package list
# 3. Skip old content until <!-- pkgs end -->
{
  sed -n '1,/<!-- pkgs start -->/p' README.md
  echo "$pkglist"
  sed -n '/<!-- pkgs end -->/,$p' README.md
} > README.md.tmp
mv README.md.tmp README.md

echo "README.md updated with package list for ${system}"
