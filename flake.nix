{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # pas de follows ici : le cache kopuz.cachix.org ne contient que les binaires
    # construits avec leur nixpkgs. suivre le notre = tout recompiler en local
    kopuz.url = "github:Kopuz-org/kopuz";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    fsa = {
      url = "github:ehmvi/fsa";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      hjem,
      nix-darwin,
      nix-homebrew,
      fsa,
      treefmt-nix,
      sops-nix,
      ...
    }:
    let
      theme = import ./theme.nix;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
      # specialArgs, sops-nix et hjem sont communs aux 3 hosts. le module nixos ou
      # darwin est choisi ici ; la config age est dans modules/shared/sops.nix.
      # les autres modules restent passes par l appelant.
      mkHost =
        {
          builder,
          modules,
          username, # compte principal du host, passe aux modules via specialArgs
          darwin ? false,
        }:
        builder {
          specialArgs = {
            inherit inputs theme username;
          };
          modules = [
            (if darwin then sops-nix.darwinModules.sops else sops-nix.nixosModules.sops)
            ./modules/shared/sops.nix
            (if darwin then hjem.darwinModules.default else hjem.nixosModules.default)
          ]
          ++ modules;
        };
    in
    {
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "nixos-config";
            packages = with pkgs; [
              nixd
              nixfmt
              statix
              deadnix
              just
              sops
              age
            ];
          };
        }
      );

      nixosConfigurations = {
        navi = mkHost {
          builder = nixpkgs.lib.nixosSystem;
          username = "paul";
          modules = [ ./hosts/navi/default.nix ];
        };
        games = mkHost {
          builder = nixpkgs.lib.nixosSystem;
          username = "paul";
          modules = [ ./hosts/games/default.nix ];
        };
      };

      darwinConfigurations.sommei = mkHost {
        builder = nix-darwin.lib.darwinSystem;
        darwin = true;
        username = "user";
        modules = [
          ./hosts/sommei/default.nix
          nix-homebrew.darwinModules.nix-homebrew
          fsa.darwinModules.default
        ];
      };

    };
}
