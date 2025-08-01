let
  hostName = "tioneshe";

  flags = {
    headless = false;

    usesNvidia = true;

    # no speakers?
    mute = false;

    use_dnsmasq = true;

    hosts_github_runner = false;

    # Perf monitoring tools like Prometheus & Grafana
    hosts_promgraf = true;

    hosts_torrents = false;

    services = {
      transmission = {
        enable = true;
        openFirewall = false;
        settings = {
          #download-dir = "/mnt/blestion/transmission/Downloads";
          #incomplete-dir = "/mnt/blestion/transmission/.incomplete";
          incomplete-dir-enabled = true;
          message-level = 1;
          peer-port = 51413;
          peer-port-random-high = 65535;
          peer-port-random-low = 49152;
          peer-port-random-on-start = false;
          rpc-bind-address = "0.0.0.0";
          rpc-port = 9091;
          rpc-whitelist = "127.0.0.1,192.168.*.*";
          script-torrent-done-enabled = false;
          umask = 2;
          utp-enabled = true;
          #watch-dir = "/mnt/blestion/transmission/watchdir";
          watch-dir-enabled = true;
        };
      };
    };

    imports = [ ../hardware-configurations/tioneshe.nix ];

    boot = config: {
      extraModulePackages = with config.boot.kernelPackages; [
        rtl88x2bu
        v4l2loopback.out
      ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1
      '';
      binfmt.emulatedSystems = [ "aarch64-linux" ];
    };

    fileSystems = {
      "/mnt/maganedette" = {
        device = "/dev/disk/by-uuid/a9445e33-8ecc-474a-aa5e-00d0d8c3a711";
        fsType = "ext4";
      };
      "/mnt/maganed" = {
        device = "/dev/disk/by-uuid/9C62DA8A62DA6912";
        fsType = "ntfs";
        options = [
          "uid=1000" # rkb
          "gid=100" # users
        ];
      };
      "/mnt/blestion" = {
        device = "//192.168.1.98/blestion";
        fsType = "cifs";
        options = let
          # this line prevents hanging on network split
          automount_opts =
            "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s"
            + ",uid=rkb,gid=users";

          /* ./smb-secrets should look like:
             ```
             username=rkb
             domain=workgroup
             password=YOURPASSWORDHERE
             ```
          */
        in [ "${automount_opts},credentials=/etc/nixos/smb-secrets" ];
      };
      "/mnt/smiticia" = {
        device = "//192.168.1.98/smiticia";
        fsType = "cifs";
        options = let
          # this line prevents hanging on network split
          automount_opts =
            "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

          /* ./smb-secrets should look like:
             ```
             username=rkb
             domain=workgroup
             password=YOURPASSWORDHERE
             ```
          */
        in [ "${automount_opts},credentials=/etc/nixos/smb-secrets" ];
      };
    };

    networking = {
      inherit hostName; # Define your hostname.
      # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

      # The global useDHCP flag is deprecated, therefore explicitly set to false here.
      # Per-interface useDHCP will be mandatory in the future, so this generated config
      # replicates the default behaviour.
      useDHCP = false;
      nameservers = [
        "8.8.4.4"
        "8.8.8.8"
        "192.168.1.1" # home net
      ];
      interfaces.enp0s31f6.useDHCP = true;
      networkmanager = {
        enable = true;
        #        unmanaged = [
        #          "interface-name:br-*"
        #          "interface-name:veth*"
        #          "interface-name:docker0"
        #        ];
      };

      #wireless = {
      #  enable = true;
      #  userControlled.enable = true;
      #};

      # Open ports in the firewall.
      # networking.firewall.allowedTCPPorts = [ ... ];
      # Local dev (Hippo, etc)
      firewall = {
        allowedTCPPortRanges = [
          {
            # kdeconnect
            from = 1714;
            to = 1764;
          }
          {
            # local hippo dev
            from = 5080;
            to = 5089;
          }
          {
            # minidlna???
            from = 8200;
            to = 8200;
          }
          {
            # node exporter for prometheus
            from = 9100;
            to = 9100;
          }
        ];
        allowedUDPPortRanges = [
          {
            # kdeconnect
            from = 1714;
            to = 1764;
          }
          {
            # minidlna
            from = 1900;
            to = 1900;
          }
        ];
        #        extraInputRules = ''
        #          iifname { "br-*" } accept comment "Docker containers to host"
        #        '';
        #        interfaces."br-*".allowedTCPPortRanges =
        #          # needed for docker containers to access `host.docker.internal`
        #          [
        #            {
        #              from = 8000;
        #              to = 8099;
        #            }
        #            { # hippo local backend dev
        #              from = 5000;
        #              to = 5099;
        #            }
        #            { # tcm local backend dev
        #              from = 7000;
        #              to = 7099;
        #            }
        #          ];
      };
      # firewall.allowedUDPPorts = [ ... ];
      # Or disable the firewall altogether.
      # firewall.enable = false;
    };
  };
in flags
