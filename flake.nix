{
  description = "Custom Nix packages with auto-updating sources";

  nixConfig = {
    extra-substituters = [ "https://rifat.cachix.org" ];
    extra-trusted-public-keys = [ "rifat.cachix.org-1:fGsDn1VSmzo+Fgz55h+Glc3zT6GXCdyD3EVbdAOw0co=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "aarch64-darwin"
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

      darwinModules =
        let
          individual = lib.listToAttrs (
            map (path: {
              name = lib.removeSuffix "/darwin-module.nix" (
                lib.removePrefix (toString ./packages + "/") (toString path)
              );
              value = path;
            }) overlayData.darwinModules
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
          packageAvailableOn =
            name:
            let
              pkg = builtins.tryEval pkgs.${name};
            in
            pkg.success && builtins.elem system ((pkg.value.meta.platforms or supportedSystems));
          packageNamesForSystem = builtins.filter packageAvailableOn overlayData.packageNames;
        in
        lib.genAttrs packageNamesForSystem (name: pkgs.${name})
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
