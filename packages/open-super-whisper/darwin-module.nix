{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.open-super-whisper;
in
{
  options.programs.open-super-whisper = {
    enable = lib.mkEnableOption "OpenSuperWhisper dictation app";

    enableAerospaceIntegration = lib.mkOption {
      type = lib.types.bool;
      default = config.services.aerospace.enable;
      defaultText = lib.literalExpression "config.services.aerospace.enable";
      description = ''
        Add an AeroSpace `on-window-detected` rule that keeps the
        OpenSuperWhisper window floating instead of tiled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.open-super-whisper ];

    services.aerospace.settings.on-window-detected = lib.mkIf cfg.enableAerospaceIntegration [
      {
        "if".app-id = "ru.starmel.OpenSuperWhisper";
        run = "layout floating";
        check-further-callbacks = true;
      }
    ];
  };
}
