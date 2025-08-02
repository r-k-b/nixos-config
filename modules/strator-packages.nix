{ pkgs, ... }:
let

  minidlna-rebuild = pkgs.writeShellScriptBin "minidlna-rebuild" ''
    doas -u minidlna ${pkgs.minidlna}/bin/minidlnad -R && sudo systemctl restart minidlna.service
  '';

in {
  environment.systemPackages = with pkgs;
    [
      minidlna-rebuild # to get new files to appear in VLC
    ];
  nix.settings = {
    substituters = [ "https://cache.nixos.org" "file://mnt/blestion/nix-store?trusted=1" ];
  };
}
