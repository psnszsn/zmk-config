{
  description = "ZMK config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix.url = "github:lilyinstarlight/zmk-nix";
    zmk-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, zmk-nix }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
      srcFiles = nixpkgs.lib.sourceFilesBySuffices self [
        ".c" ".h" ".conf" ".keymap" ".overlay" ".dtsi" ".dts"
        ".yml" ".board" ".cmake" ".defconfig" ".shield"
      ];
    in
    {
      packages = forAllSystems (system: rec {
        default = totem;

        totem = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "totem";
          src = srcFiles;
          board = "xiao_ble";
          shield = "totem_%PART%";
          zephyrDepsHash = "sha256-JgUJP/Aa3WCeTz9mgR+oJakFWcnxyg9xkjOuYzry3PY=";
        };

        klor = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "klor";
          src = srcFiles;
          board = "nice_nano";
          shield = "klor_%PART%";
          zephyrDepsHash = "sha256-JgUJP/Aa3WCeTz9mgR+oJakFWcnxyg9xkjOuYzry3PY=";
        };

        klor-wired = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "klor-wired";
          src = srcFiles;
          board = "nice_nano";
          shield = "klor_wired_%PART%";
          zephyrDepsHash = "sha256-JgUJP/Aa3WCeTz9mgR+oJakFWcnxyg9xkjOuYzry3PY=";
        };

        flash = zmk-nix.packages.${system}.flash.override { firmware = default; };
        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
