{ config, lib, ... }:

let
  cfg = config.programs.chromium;
in
{
  config = lib.mkIf cfg.enable {
    environment.etc = {
      # Brave managed policies (locked settings)
      "brave/policies/managed/extra.json" =
        lib.mkIf (cfg.extraOpts != { }) {
          text = builtins.toJSON cfg.extraOpts;
        };

      # Brave recommended policies (user-overridable defaults)
      "brave/policies/recommended/extra.json" =
        lib.mkIf (cfg.extraOptsRecommended != { }) {
          text = builtins.toJSON cfg.extraOptsRecommended;
        };
    };
  };
}
