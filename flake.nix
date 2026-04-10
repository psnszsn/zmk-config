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
          board = "xiao_ble//zmk";
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

        flash-totem-left = let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3.withPackages (ps: [ ps.pyudev ]);
        in pkgs.writeShellScriptBin "flash-totem-left" ''
          doas env UF2="${totem}/zmk_left.uf2" ${python}/bin/python3 ${./flash.py}
        '';

        flash-totem-right = let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python3.withPackages (ps: [ ps.pyudev ]);
        in pkgs.writeShellScriptBin "flash-totem-right" ''
          doas env UF2="${totem}/zmk_right.uf2" ${python}/bin/python3 ${./flash.py}
        '';

        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          inputsFrom = [ zmk-nix.devShells.${system}.default ];
          packages = [
            (pkgs.python3.withPackages (ps: [ ps.pyudev ]))
          ];
        };
      });
    };
}
