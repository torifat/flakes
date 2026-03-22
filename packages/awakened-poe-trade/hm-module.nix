{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.awakened-poe-trade;
in
{
  options.programs.awakened-poe-trade = {
    enable = lib.mkEnableOption "awakened-poe-trade";

    enableHyprlandIntegration = lib.mkOption {
      type = lib.types.bool;
      default = config.wayland.windowManager.hyprland.enable;
      defaultText = lib.literalExpression "config.wayland.windowManager.hyprland.enable";
      description = ''
        Enable Hyprland window rules and keybind pass-throughs for the overlay.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Force XWayland mode — overlay doesn't work under native Wayland
      (pkgs.symlinkJoin {
        name = "awakened-poe-trade-x11";
        paths = [ pkgs.awakened-poe-trade ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/awakened-poe-trade \
            --set NIXOS_OZONE_WL "" \
            --add-flags "--ozone-platform=x11"
        '';
      })
    ];

    wayland.windowManager.hyprland.settings = lib.mkIf cfg.enableHyprlandIntegration {
      windowrule = [
        # Based on working config from github.com/SnosMe/awakened-poe-trade/issues/1752
        "tag +apt, match:class ^(awakened-poe-trade|Awakened-poe-trade)$"
        "float on, match:tag apt"
        "no_blur on, match:tag apt"
        "no_anim on, match:tag apt"
        "no_shadow on, match:tag apt"
        "border_size 0, match:tag apt"
        "no_follow_mouse on, match:tag apt"
        "workspace 4, match:tag apt"
      ];

      bindn = [
        "SHIFT, SPACE, sendshortcut, SHIFT, SPACE, class:^(awakened-poe-trade)$"
        "CTRL, D, sendshortcut, CTRL, D, class:^(awakened-poe-trade)$"
        "CTRL ALT, D, sendshortcut, CTRL ALT, D, class:^(awakened-poe-trade)$"
        "CTRL, F, sendshortcut, CTRL, F, class:^(awakened-poe-trade)$"
      ];
    };
  };
}
