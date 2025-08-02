let
  hostName = "molochar";

  flags = {
    headless = false;

    usesNvidia = false;

    # no speakers?
    mute = false;

    use_dnsmasq = true;

    hosts_github_runner = false;

    # Perf monitoring tools like Prometheus & Grafana
    hosts_promgraf = true;

    hosts_torrents = false;

    services = {
      # let me open individual GUI apps over SSH
      openssh = {
        enable = true;
        settings.X11Forwarding = true;
      };
    };

    imports = [ ../hardware-configurations/molochar.nix ];

    boot = config: {
      extraModulePackages = with config.boot.kernelPackages; [
        rtl88x2bu
        v4l2loopback.out
      ];
      kernelModules = [ "v4l2loopback" ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1
      '';
    };

    fileSystems = { };

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
      #      interfaces.enp0s31f6.useDHCP = true;
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
