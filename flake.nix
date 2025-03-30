{
  description = "flake for the NixOS machines";

  inputs = {
    browserPreviews = {
      url = "github:r-k-b/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable-small"; };
    nvimconf = {
      url = "github:r-k-b/nvimconf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # fixme: find something less bloaty
    #nixarr = {
    #  url = "github:rasmus-kirk/nixarr";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) fileset hasSuffix;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      nixFiles = fileset.toSource {
        root = ./.;
        fileset = fileset.unions [
          (fileset.fileFilter (file: hasSuffix ".nix" file.name) ./.)
          ./statix.toml
        ];
      };
      checker = attrs:
        pkgs.callPackage ./check-files.nix (attrs // { inherit nixFiles; });
    in {
      checks.x86_64-linux = {
        # 🛈  there's a more convenient 'watch mode' version of these, in ./watch-file-checkers.nu
        deadnix = checker (with pkgs; {
          tool = deadnix;
          cmd = "deadnix --fail";
        });
        nixfmt = checker (with pkgs; {
          tool = nixfmt-classic;
          cmd = "nixfmt --check **/*.nix";
        });
        statix = checker (with pkgs; {
          tool = statix;
          cmd = "statix check";
        });
      };
      nixosConfigurations = {
        tioneshe = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            #            (import ./overlays/curl-hotfix.nix)
            ./configuration.nix
            ./modules/intellij-ides.nix
            ./modules/tioneshe-packages.nix
            { nix.registry.nixpkgs.flake = nixpkgs; }
            {
              nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
            }
            #inputs.nixarr.nixosModules.default
          ];
          specialArgs = {
            inherit inputs;
            flags = import ./flags/tioneshe.nix;
          };
        };

        molochar = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./modules/intellij-ides.nix
            ./modules/molochar-packages.nix
            { nix.registry.nixpkgs.flake = nixpkgs; }
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
          ];
          specialArgs = {
            inherit inputs;
            flags = import ./flags/molochar.nix;
          };
        };

        "nixos-strator" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ./modules/strator-packages.nix
            { nix.registry.nixpkgs.flake = nixpkgs; }
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
          ];
          specialArgs = {
            inherit inputs;
            flags = import ./flags/strator.nix;
          };
        };
      };
    };
}
