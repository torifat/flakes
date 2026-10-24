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
  imports = [ flakes.homeManagerModules.awakened-poe-trade ];
};
```

### Binary cache

CI builds every package for `aarch64-darwin` and `x86_64-linux` and pushes the results to [rifat.cachix.org](https://rifat.cachix.org). Add it to your NixOS or nix-darwin config:

```nix
nix.settings = {
  extra-substituters = [ "https://rifat.cachix.org" ];
  extra-trusted-public-keys = [
    "rifat.cachix.org-1:fGsDn1VSmzo+Fgz55h+Glc3zT6GXCdyD3EVbdAOw0co="
  ];
};
```

The overlay builds packages against your nixpkgs, so they only come from the cache when your nixpkgs is the same revision as the one in this flake's `flake.lock`. CI moves that revision to the latest `nixpkgs-unstable` every 6 hours. To stay on it, make your nixpkgs follow this flake's:

```nix
inputs = {
  flakes.url = "github:torifat/flakes";
  nixpkgs.follows = "flakes/nixpkgs";
};
```

`nix flake update flakes` then updates both. If you rebuild before CI has finished building a new nixpkgs revision, those packages build locally.

If you keep your own nixpkgs, use `flakes.packages.${system}.<name>` for the packages you want cached instead of taking them from the overlay.

## Packages

<!-- pkgs start -->
| Package | Version |
|---------|---------|
| [aeronaut](https://github.com/torifat/aeronaut) | `0.1.4` |
| [awakened-poe-trade](https://github.com/SnosMe/awakened-poe-trade) | `3.29.108` |
| [googlesans-code](https://github.com/googlefonts/googlesans-code) | `v7.001` |
| [miaoyan](https://github.com/tw93/MiaoYan) | `4.5.0` |
| [mole](https://github.com/tw93/mole) | `1.62.0` |
| [open-super-whisper](https://github.com/Starmel/OpenSuperWhisper) | `0.1.0` |
| [prek](https://github.com/j178/prek) | `v0.5.7` |
| [pvetui](https://github.com/devnullvoid/pvetui) | `1.4.4` |
| [rusty-path-of-building](https://github.com/meehl/rusty-path-of-building) | `v0.3.3` |
| [sf-symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols) | `7` |
| [television](https://github.com/alexpasmantier/television) | `0.15.9` |
| [worktrunk](https://github.com/max-sixty/worktrunk) | `v0.81.0` |
<!-- pkgs end -->
