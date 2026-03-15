{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.worktrunk;
in
{
  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk";

    enableZshIntegration = lib.mkOption {
      type = lib.types.bool;
      default = config.programs.zsh.enable;
      defaultText = lib.literalExpression "config.programs.zsh.enable";
      description = ''
        Enable ZSH Shell integration for directory switching with `wt switch` 
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.worktrunk ];

    #ZSH Integration
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      # worktrunk shell integration
      eval "$(${lib.getExe pkgs.worktrunk} config shell init zsh)"
    '';
  };
}
