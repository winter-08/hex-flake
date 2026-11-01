{
  description = "Hex local voice dictation for nix-darwin";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      updateSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages.aarch64-darwin =
        let
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          hex = pkgs.callPackage ./package.nix { };
        in
        {
          inherit hex;
          default = hex;
        };

      overlays.default = final: _prev: {
        hex = final.callPackage ./package.nix { };
      };

      darwinModules.hex =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.hex;
          json = pkgs.formats.json { };

          inherit (lib.lists) singleton;
          inherit (lib.meta) getExe;
          inherit (lib.modules) mkIf;
          inherit (lib.options) mkEnableOption mkOption;
          inherit (lib.types) package;
        in
        {
          options.programs.hex = {
            enable = mkEnableOption "Hex local voice dictation";

            package = mkOption {
              type = package;
              default = self.packages.aarch64-darwin.hex;
              description = "Hex package to install.";
            };

            autostart = mkEnableOption "starting Hex at login";

            settings = mkOption {
              type = json.type;
              default = { };
              example = {
                dictation_hotkey = "option+space";
                shortcut_mode = "toggle";
              };
              description = ''
                Settings merged into Hex on activation, keyed as `hex settings list`
                prints them. Keys left out keep the value set in the app.
              '';
            };
          };

          config = mkIf cfg.enable {
            environment.systemPackages = singleton cfg.package;

            # The store is read-only, so updates come from this flake.
            system.defaults.CustomUserPreferences."anomaly.hex".DisableUpdates = true;

            # Hex's own login item would pin a store path that changes per version.
            launchd.user.agents.hex.serviceConfig = mkIf cfg.autostart {
              ProgramArguments = [
                "${cfg.package}/Applications/Hex.app/Contents/MacOS/hex"
                "start"
              ];
              RunAtLoad = true;
            };

            system.activationScripts.postActivation.text = mkIf (cfg.settings != { }) /* bash */ ''
              if ! /usr/bin/sudo --user=${config.system.primaryUser} --set-home \
                ${getExe cfg.package} settings apply ${json.generate "hex-settings.json" cfg.settings}; then
                echo "warning: Hex didn't apply programs.hex.settings" >&2
              fi
            '';
          };
        };
      darwinModules.default = self.darwinModules.hex;

      apps = lib.genAttrs updateSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          update = pkgs.writeShellApplication {
            name = "update-hex";
            runtimeInputs = [
              pkgs.curl
              pkgs.jq
              pkgs.nix
            ];
            text = builtins.readFile ./scripts/update.sh;
          };
        in
        {
          update = {
            type = "app";
            program = lib.getExe update;
            meta.description = "Pin the newest Hex release in version.json";
          };
        }
      );

      formatter = lib.genAttrs updateSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
