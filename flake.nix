{
  description = "flake for the first NixOS machine";

  inputs = {
    browserPreviews = {
      url = "github:r-k-b/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable"; };
    nvimconf = {
      url = "github:r-k-b/nvimconf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs.lib) fileset hasSuffix;
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      nixFiles = fileset.toSource {
        root = ./.;
        fileset = fileset.fileFilter (file: hasSuffix ".nix" file.name) ./.;
      };
      checker = attrs: pkgs.callPackage ./check-files.nix (attrs // {inherit nixFiles;});
    in {
      checks.x86_64-linux = {
        deadnix = checker (with pkgs; { tool = deadnix; cmd = "deadnix --fail"; });
        nixfmt = checker (with pkgs; { tool = nixfmt; cmd = "nixfmt --check **/*.nix"; });
        statix = checker (with pkgs; { tool = statix; cmd = "statix check"; });
      };
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            { nix.registry.nixpkgs.flake = nixpkgs; }
            { nix.nixPath = [ "nixpkgs=flake:nixpkgs" ]; }
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}

