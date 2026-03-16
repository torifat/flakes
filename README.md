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
* [gemini-cli](https://github.com/google-gemini/gemini-cli) - v0.33.1
* [googlesans-code](https://github.com/googlefonts/googlesans-code) - v6.001
* [prek](https://github.com/j178/prek) - v0.3.6
* [pvetui](https://github.com/devnullvoid/pvetui) - 1.2.1
<!-- pkgs end -->
