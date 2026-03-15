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
* [prek](https://github.com/j178/prek) - v0.3.5
* [pvetui](https://github.com/devnullvoid/pvetui) - 1.2.1
* [sf-symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols) - 7
* [sketchybar-helper](https://github.com/FelixKratz/SketchyBar) - 73ee34d377f62fc12ddbf519a2bcdb4b7946292a
* [worktrunk](https://github.com/max-sixty/worktrunk) - v0.29.4
<!-- pkgs end -->
