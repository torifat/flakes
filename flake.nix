{
  description = "Custom Nix packages with auto-updating sources";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      overlayData = import ./overlays/default.nix { inherit lib; };
    in
    {
      overlays.default = overlayData.overlay;

      homeManagerModules =
        let
          individual = lib.listToAttrs (
            map (path: {
              name = lib.removeSuffix "/hm-module.nix" (
                lib.removePrefix (toString ./packages + "/") (toString path)
              );
              value = path;
            }) overlayData.hmModules
          );
        in
        individual // { default.imports = builtins.attrValues individual; };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlayData.overlay ];
            config.allowUnfree = true;
          };
        in
        lib.filterAttrs (
          _: pkg: builtins.elem system (pkg.meta.platforms or supportedSystems)
        ) (lib.genAttrs overlayData.packageNames (name: pkgs.${name}))
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlayData.overlay ];
            config.allowUnfree = true;
          };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nvfetcher
              nixfmt
              nil
              deadnix
              statix
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
