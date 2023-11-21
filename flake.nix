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

  outputs = inputs@{ self, browserPreviews, nixpkgs, nvimconf }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [ ./configuration.nix { nix.registry.nixpkgs.flake = nixpkgs; } ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}

