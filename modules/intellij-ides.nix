{ pkgs, ... }:
let
  riderByBranch = branch:
    pkgs.writeShellScriptBin ("riderPHD-" + branch) ''
      #!{pkgs.sh}/bin/sh
      NIXPKGS_ALLOW_INSECURE=1 nix develop 'git+ssh://git@ssh.dev.azure.com/v3/HAMBS-AU/Sydney/PHDSys-net?ref=${branch}' -L --impure --command rider &
    '';

in {
  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      jetbrains.idea
      jetbrains.rider
      (riderByBranch "main")
      (riderByBranch "integration")
    ];
  };
}
