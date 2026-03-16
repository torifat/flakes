# flakes

Custom Nix packages with auto-updating sources via [nvfetcher](https://github.com/berberman/nvfetcher).

## Usage

```nix
{
  inputs.flakes.url = "github:torifat/flakes";

  outputs = { nixpkgs, flakes, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [
        { nixpkgs.overlays = [ flakes.overlays.default ]; }
      ];
    };
  };
}
```

## Packages

<!-- pkgs start -->
* [gemini-cli](https://github.com/google-gemini/gemini-cli) - v0.33.1
* [googlesans-code](https://github.com/googlefonts/googlesans-code) - v6.001
* [prek](https://github.com/j178/prek) - v0.3.6
* [pvetui](https://github.com/devnullvoid/pvetui) - 1.2.1
<!-- pkgs end -->
