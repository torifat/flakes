# flakes

Custom Nix packages with auto-updating sources via [nvfetcher](https://github.com/berberman/nvfetcher).

## Usage

Add the flake input and apply the overlay:

```nix
{
  inputs.flakes.url = "github:torifat/flakes";

  outputs = { nixpkgs, flakes, ... }: {
    # NixOS
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ flakes.overlays.default ]; }
      ];
    };

    # nix-darwin
    darwinConfigurations.myHost = nix-darwin.lib.darwinSystem {
      modules = [
        { nixpkgs.overlays = [ flakes.overlays.default ]; }
      ];
    };
  };
}
```

### Home Manager Modules

Some packages ship with Home Manager modules. You can import them all at once with `homeManagerModules.default`, or pick individual ones:

```nix
# All modules
home-manager.users.myUser = {
  imports = [ flakes.homeManagerModules.default ];
};

# Individual module
home-manager.users.myUser = {
  imports = [ flakes.homeManagerModules.worktrunk ];
};
```

## Packages

<!-- pkgs start -->
| Package | Version |
|---------|---------|
| [awakened-poe-trade](https://github.com/SnosMe/awakened-poe-trade) | `3.28.103` |
| [gemini-cli](https://github.com/google-gemini/gemini-cli) | `v0.37.2` |
| [googlesans-code](https://github.com/googlefonts/googlesans-code) | `v7.000` |
| [prek](https://github.com/j178/prek) | `v0.3.9` |
| [pvetui](https://github.com/devnullvoid/pvetui) | `1.3.0` |
| [rusty-path-of-building](https://github.com/meehl/rusty-path-of-building) | `v0.2.16` |
| [sf-symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols) | `7` |
| [sketchybar-helper](https://github.com/FelixKratz/SketchyBar) | `73ee34d377f62fc12ddbf519a2bcdb4b7946292a` |
| [television](https://github.com/alexpasmantier/television) | `0.15.5` |
| [worktrunk](https://github.com/max-sixty/worktrunk) | `v0.37.0` |
<!-- pkgs end -->
