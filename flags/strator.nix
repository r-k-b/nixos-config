let
  hostName = "nixos-strator";

  flags = {
    headless = true;

    usesNvidia = false;

    # no speakers?
    mute = true;

    use_dnsmasq = false;

    hosts_github_runner = true;

    hosts_promgraf = false;

    hosts_torrents = false;

    services = {
      calibre-web = {
        enable = true;
        openFirewall = true;
        listen = { ip = "0.0.0.0"; };
        options = {
          # calibreLibrary = "/var/lib/calibre-web";
          enableBookUploading = true;
        };
      };

      # so we can use custom subdomains in development
      dnsmasq = {
        enable = true;
        settings = {
          address = [
            "/localhost/127.0.0.1"
            "/nixos/192.168.1.103"
            "/strator/192.168.1.98"
          ];
          server = [
            "/phd.com.au/10.20.60.10" # PHD VPN
          ];
        };
      };

      samba = {
        enable = true;
        settings = {
          "global" = {
            "workgroup" = "WORKGROUP";
            "security" = "user";
            "server string" = "smbnix";
            "netbios name" = "smbnix";
            "use sendfile" = "yes";
            "min protocol" = "smb2";
            "max protocol" = "smb2";
            #"hosts allow" = "192.168.0  localhost";
            #"hosts deny" = "0.0.0.0/0";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
          blestion = {
            path = "/mnt/blestion";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            #"create mask" = "0644";
            #"directory mask" = "0755";
            #"force user" = "username";
            #"force group" = "groupname";
          };
          smiticia = {
            path = "/mnt/smiticia";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            #"create mask" = "0644";
            #"directory mask" = "0755";
            #"force user" = "username";
            #"force group" = "groupname";
          };
          #private = {
          #  path = "/mnt/Shares/Private";
          #  browseable = "yes";
          #  "read only" = "no";
          #  "guest ok" = "no";
          #  #"create mask" = "0644";
          #  #"directory mask" = "0755";
          #  #"force user" = "username";
          #  #"force group" = "groupname";
          #};
        };
      };

      minidlna = {
        enable = true;
        settings = {
          media_dir = [ "/mnt/blestion/transmission/Downloads" ];
          friendly_name = "strator_dlna";
          notify_interval = 10; # in seconds; default is 15*60
        };
      };

      # Enable the OpenSSH daemon.
      openssh.enable = true;

      prometheus = {
        enable = true;
        port = prometheusPort;
        scrapeConfigs = [
          {
            job_name = "hippo_backends";
            metrics_path = "/api/metrics";
            static_configs = [{
              targets = [
                "phdcchippo.phd.com.au:5080"
                "phdcchpdev.phd.com.au:5080"
                "phdccrtdev.phd.com.au:5080"
                "phdccwestdev.phd.com.au:5080"
                "nixos:5081" # rt
                "nixos:5084" # wf
                "nixos:5085" # hp
              ];
            }];
          }
          {
            job_name = "prometheus";
            static_configs =
              [{ targets = [ "localhost:${toString prometheusPort}" ]; }];
          }
          {
            job_name = "nodes";
            static_configs = [{ targets = [ "localhost:9100" "nixos:9100" ]; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [
              "conntrack"
              "diskstats"
              "entropy"
              "filefd"
              "filesystem"
              "loadavg"
              "mdadm"
              "meminfo"
              "netdev"
              "netstat"
              "stat"
              "time"
              "vmstat"
              "systemd"
              "logind"
              "interrupts"
              "ksmd"
            ];
          };
        };
      };
    };

    imports = [ ../hardware-configurations/strator.nix ];

    boot =
      _: { # the default (2gb?) frequently hits "no space left on device" issues on the tmpfs
        runSize = "3g";
      };

    fileSystems = {
      "/mnt/blestion" = {
        device = "/dev/disk/by-label/blestion";
        fsType = "ext4";
      };

      "/mnt/smiticia" = {
        device = "/dev/disk/by-label/smiticia";
        fsType = "ext4";
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
      interfaces = {
        enp0s31f6 = {
          ipv4 = {
            addresses = [{
              address = "192.168.1.98";
              prefixLength = 16;
            }];
          };
          useDHCP = true;
        };
        enp3s0.useDHCP = true;
        wlp4s0.useDHCP = true;
      };
      firewall = {
        allowedTCPPorts = [
          139
          445
          8200 # minidlna
          prometheusPort
          9091 # 9091 is Transmission's Web interface
        ];
        allowedUDPPorts = [
          137
          138
          1900 # minidlna
        ];
        allowPing = true;
      };
    };
  };

  prometheusPort = 9090;
in flags
