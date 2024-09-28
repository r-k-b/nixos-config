# Edit this configuration file to define what should be installed on

# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, inputs, pkgs, ... }:
let
  riderByBranch = branch:
    pkgs.writeShellScriptBin ("riderPHD-" + branch) ''
      #!{pkgs.sh}/bin/sh
      NIXPKGS_ALLOW_INSECURE=1 nix develop 'git+ssh://git@ssh.dev.azure.com/v3/HAMBS-AU/Sydney/PHDSys-net?ref=${branch}' -L --impure --command rider &
    '';
in {
  nix = {
    settings = {
      auto-optimise-store = true; # we're on an ssd, should be no downside?

      # https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md#tested-using-sandboxing
      sandbox = true;
    };
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      netrc-file = /etc/nixos/netrc

      # for nix-direnv
      keep-outputs = true
      keep-derivations = true
    '';
    gc = {
      automatic = false;
      dates = "monthly";
      persistent = true;
      options = "--delete-older-than 60d";
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      dates = "weekly";
      persistent = true;
    };
  };

  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 30;
    };
    loader.efi.canTouchEfiVariables = true;

    extraModulePackages = [
      config.boot.kernelPackages.rtl88x2bu
      config.boot.kernelPackages.v4l2loopback.out
    ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
  };

  powerManagement.cpuFreqGovernor = "performance";

  services = {
    # so we can use custom subdomains in development, and with traefik
    dnsmasq = {
      enable = true;
      settings = {
        # watch what queries dnsmasq sends and receives; helps with debugging
        log-queries = true;
        log-debug = true;

        # which of these do we actually need?
        no-resolv =
          true; # = ignore resolvers added by the vpn to /etc/resolv.conf

        clear-on-reload =
          true; # = whenever resolv.conf is updated, clear the cache

        no-negcache = true; # = don't keep lookup failures in cache

        # use the last servers listed here, first. (saves having to restart
        # the dnsmasq.service after connecting the hambs vpn)
        strict-order = true;

        address = [
          "/localhost/127.0.0.1"
          "/nixos/192.168.1.103"
          "/strator/192.168.1.98"
          "/nixos-strator/192.168.1.98"

          # p21 weirdness?
          "/SPS-D-P21APP02.hambs.com.au/10.1.24.3"
          "/SPS-D-P21APP02.internal.hambs.com.au/10.1.24.3"
          #"/SPS-D-P21APP02.hambs.com.au/52.128.23.153"
          #"/SPS-D-P21APP02.internal.hambs.com.au/52.128.23.153"
          "/WFD-D-P21APP02.hambs.com.au/10.1.21.3"
          "/WFD-D-P21APP02.internal.hambs.com.au/10.1.21.3"
        ];

        server = [
          "8.8.4.4"
          "1.1.1.1"
          "8.8.8.8"

          # WF VPN
          # The first NS listed in their vpn config, 10.10.100.40, consistently times out...
          "/westfund.com.au/10.10.10.50"
          "/vpn.westfund.com.au/8.8.4.4"

          # HAMBS VPN
          "/vpnportal.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          "/vpnportal2.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          "/vpngateway1.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          "/vpngateway2.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          "/vpngateway3.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          "/vpngateway4.hambs.com.au/8.8.4.4" # needs to be called from outside the vpn
          # (.228 is a fallback server, but it gives different answers to .8 ...)
          "/hambs.com.au/192.168.229.228"
          "/hambs.com.au/192.168.229.8"
          "/hambs.internal/192.168.229.228"
          "/hambs.internal/192.168.229.8"
          "/hambs.io/192.168.229.8"
          "/hambs.io/192.168.229.8"
          # try this nameserver before the previous PHD nameserver
          "/phd.com.au/192.168.229.8"
        ];

      };
    };

    # browse samba shares in gui apps
    gvfs.enable = true;
  };

  # extend the life of SSDs?
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      # For dates formatted like ISO8601
      # https://serverfault.com/a/17184/276263
      LC_TIME = "en_DK.UTF-8";
    };
    supportedLocales = [ "all" ];
  };

  services.grafana = {
    enable = true;
    #domain = "grafana.pele";
    settings.server = {
      port = 2342;
      addr = "127.0.0.1";
    };
  };

  services.prometheus = {
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

  services.sysstat = { enable = true; };

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

  nixarr = {
    enable = true;
    # These two values are also the default, but you can set them to whatever
    # else you want
    mediaDir = "/data/media";
    stateDir = "/data/media/.state";

    transmission = { enable = true; }; # port 9091
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      iosevka
      gyre-fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      joypixels
      monaspace # "texture healing"?
      mplus-outline-fonts.githubRelease
      noto-fonts-color-emoji # a good fallback font
      dina-font
      open-dyslexic
      proggyfonts
      twemoji-color-font
      twitter-color-emoji
      unifont
      unifont_upper
      vollkorn
    ];
    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = true;
      defaultFonts = {
        monospace = [ "DejaVu Sans Mono" "Noto Mono" ];
        serif = [ "Vollkorn" "Noto Serif" "Times New Roman" ];
        sansSerif = [ "Open Sans" "Noto Sans" ];
        emoji = [
          "Noto Color Emoji"
          "NotoEmoji Nerd Font Mono"
          "Twitter Color Emoji"
          "JoyPixels"
          "Unifont"
          "Unifont Upper"
        ];
      };
      localConf = ''
        <!-- use a less horrible font substition for pdfs such as https://www.bkent.net/Doc/mdarchiv.pdf -->
        <match target="pattern">
          <test qual="any" name="family"><string>NewCenturySchlbk</string></test>
          <edit name="family" mode="assign" binding="same"><string>TeX Gyre Schola</string></edit>
        </match>
      '';
    };
  };

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  environment = {
    pathsToLink = [ "/share/nix-direnv" ];

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    systemPackages = with pkgs; [
      alloy # for finding bugs without running or looking at code
      anki
      ark
      autossh
      bat # for previews in fzf
      bind
      broot # for interactively exploring folder structures
      btop # perf mon, shows cpu temps & network usage too
      calibre
      cifs-utils # explore samba shares
      cntr # for debugging nix package builds; for usage, see https://discourse.nixos.org/t/debug-a-failed-derivation-with-breakpointhook-and-cntr/8669?u=r-k-b
      deadnix # Find and remove unused code in .nix source files
      difftastic # for easy to read git diffs
      direnv
      distrobox # easily install apps not already packaged for Nix (.deb, .rpm etc)
      dive # for exploring docker images
      docker
      du-dust # to quickly see what's taking up space in a folder
      duf # a quick look at how much space & inodes are left
      easyeffects # convert a dodgy stereo mic into a good mono mic
      entr # file watcher; re-run command on file change
      feh # decent image viewer
      filelight # visualize disk usage (cf. du-dust)
      firefox
      flameshot # screenshots
      font-manager
      fzf
      git
      gimp # bitmap image editor
      gparted
      gpclient # HAMBS vpn
      gping # a neat way to gauge connection health
      graphviz # includes tred
      gromit-mpx # draw on the screen; like KDE Plasma's Mouse Mark effect
      kubernetes-helm # for doing ...something... to k8s
      helvum # a "patchbay" for connecting audio sink and source nodes; good for streaming audio (vs qpwgraph?)
      htop
      hyperfine # for getting benchmarking stats on terminal commands
      hyx # a nice quick hex editor for the terminal
      icdiff
      inputs.nvimconf.packages.x86_64-linux.default
      inputs.browserPreviews.packages.x86_64-linux.google-chrome
      inputs.browserPreviews.packages.x86_64-linux.google-chrome-dev
      inxi # for quick info about the system
      jetbrains.idea-ultimate
      jetbrains.rider
      (riderByBranch "main")
      (riderByBranch "integration")
      jless # for quick exploration of large json
      jq
      just # for self-explaining dev shells
      plasma5Packages.kdeconnect-kde
      k9s # for exploring kubernetes clusters
      kdenlive # for video editing
      keepassxc
      kitty # avoids the "missing emoji" problem that konsole has
      kubectl # control k8s, needed for shells in k9s
      libnotify # for showing alerts from scripts
      libreoffice
      linuxPackages.rtl88x2bu
      linuxPackages.v4l2loopback # for OBS Studio's Virtual Camera
      mosh
      msgviewer # for outlook .msg files
      nix-direnv # prevents gc of dev environments
      nix-du # for analyzing Store disk usage
      nix-output-monitor # for fancier build progress
      nix-tree # for examining the content of store paths
      nixfmt-classic
      nixpkgs-review
      notepadqq
      ntfs3g
      nushell # a nicer shell than bash?
      obs-studio
      okteta # a powerful hex editor for the gui
      okular
      openconnect # work VPNs
      parted
      pavucontrol # Can pavucontrol bring back the system sounds? https://www.reddit.com/r/kde/comments/6838fr/system_sounds_keep_breaking/
      qpwgraph # a "patchbay" for connecting audio sink and source nodes; good for streaming audio
      quickemu # handles the annoying bits of finding OS ISOs
      redshift
      remmina
      ripgrep
      rssguard # for getting alerts from rss/atom feeds (eg, new redmine issues)
      scc # for quick line counts by language (loc)
      screen
      screenkey # for showing keys pressed in recordings
      signal-desktop # for chat
      silver-searcher # ag
      simplescreenrecorder
      slop # required by screenkey
      sox # for keeping the audio sink active, and things like `play -n synth brownnoise vol 0.6`
      spice # for nicer vm guest⇆host sharing
      sshfs
      starsector # 2D space shooter
      statix # Lints & suggestions for .nix files
      stern # for tailing all the logs from a kubernetes cluster
      stow
      sysstat # for finding why the system is slow
      systemctl-tui # for easily finding & following journalctl logs
      tdesktop # avoid censorship of chat
      tlaplusToolbox # formal methods tool
      tldr # quick examples for commands
      tmux
      tor-browser-bundle-bin # avoid censorship of websites
      tree
      unclutter-xfixes # hide the cursor on inactivity
      unipicker # quick search for unicode characters
      up # Ultimate Plumber, for quickly iterating on shell commands
      vlc
      vpn-slice # for keeping non-HAMBS traffic out of the HAMBS vpn
      watchexec # file watcher; for doing things repeatedly on file change
      wget
      xdg-utils # fix file associations?
      xdotool
      xsel # clipboard helper
      zgrviewer # for interactively visualizing .dot files; like `nix-du -s=500MB | tred > store.dot`
      zoom-us
      zoxide # quick access to files & folders
    ];
  };

  programs = {
    # Autojump doesn't work out of the box, so this is needed?
    # https://github.com/NixOS/nixpkgs/pull/47334#issuecomment-439577344
    # also adds an fzf integration; use `j` with no args.
    bash.interactiveShellInit = ''
      source ${pkgs.autojump}/share/autojump/autojump.bash
      j() {
          if [[ "$#" -ne 0 ]]; then
              cd $(autojump $@)
              return
          fi
          cd "$(autojump -s | sort -k1gr | awk '$1 ~ /[0-9]:/ && $2 ~ /^\// { for (i=2; i<=NF; i++) { print $(i) } }' |  fzf --height 40% --reverse --inline-info)"
      }
    '';

    bash.promptInit = ''
      function extraDollars {
        # show an extra $ in the prompt for every SHLVL-deep we are.
        if [[ $SHLVL != 1 ]]; then
            printf '$%.0s' $(seq 1 $(($SHLVL - 1)));
        fi;
      };

      # Provide a nice prompt if the terminal supports it.
      if [ "$TERM" != "dumb" ] || [ -n "$INSIDE_EMACS" ]; then
        PROMPT_COLOR="1;31m"
        ((UID)) && PROMPT_COLOR="1;32m"
        if [ -n "$INSIDE_EMACS" ] || [ "$TERM" = "eterm" ] || [ "$TERM" = "eterm-color" ]; then
          # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
          PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\$(extraDollars)\[\033[0m\] "
        else
          PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\$(extraDollars)\[\033[0m\] "
        fi
        if test "$TERM" = "xterm"; then
          PS1="\[\033]2;\h:\u:\w\007\]$PS1"
        fi
      fi
    '';

    # For easier running of unpatched binaries, like GlobalProtect VPN
    # https://nixos.wiki/wiki/Steam
    steam = {
      enable = true;

      # https://github.com/FAForever/faf-linux/issues/38
      package =
        pkgs.steam.override { extraPkgs = p: with p; [ jq cabextract wget ]; };
    };

    # this might prove useful to debug nix package builds?
    # currently broken? may be fixed by https://github.com/NixOS/nixpkgs/pull/326600
    #sysdig.enable = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    mtr.enable = true;

    # https://github.com/Mic92/nix-ld#nix-ld
    # Run unpatched dynamic binaries on NixOS.
    nix-ld.enable = true;

    # an alternative to ssh-agent. involves the pinentry program.
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      log = { level = "DEBUG"; };
      # traefik implicitly listens on 8080?
      # see <http://nixos:8080/dashboard/>...
      entryPoints = {
        traefik = { address = ":7789"; };
        web = {
          address = ":7788";
          #http = {
          #  redirections = {
          #    entryPoint = {
          #      to = "web_https";
          #      scheme = "https";
          #    };
          #  };
          #};
        };
        web_https = { address = ":7787"; };
      };
      group = "docker";
      api = {
        dashboard = true;
        insecure = true;
        debug = true;
      };
      providers.docker = true;
    };
    dynamicConfigOptions = {
      tls = {
        certificates = [{
          certFile =
            "/var/lib/traefik/certbot/config/live/nixos.berals.wtf/fullchain.pem";
          keyFile =
            "/var/lib/traefik/certbot/config/live/nixos.berals.wtf/privkey.pem";
        }];
      };
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.lorri.enable = true;

  networking = {
    hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    interfaces.enp0s31f6.useDHCP = true;
    nameservers = [
      "8.8.4.4"
      "8.8.8.8"
      "192.168.1.1" # home net
    ];
    networkmanager.enable = true;
    #wireless = {
    #  enable = true;
    #  userControlled.enable = true;
    #};

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # Local dev (Hippo, etc)
    firewall.allowedTCPPortRanges = [
      {
        from = 8000;
        to = 8099;
      }
      {
        from = 5000;
        to = 5099;
      }
      {
        from = 1714;
        to = 1764;
      } # kdeconnect
      {
        from = 4200;
        to = 4200;
      } # hambs dev
      {
        from = 8080;
        to = 8080; # traefik dash
      }
      {
        from = 7788;
        to = 7788; # traefik routers
      }
      {
        from = 8200;
        to = 8200; # minidlna???
      }
      {
        from = 9100;
        to = 9100; # node exporter for prometheus
      }
    ];
    firewall.allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # kdeconnect
      {
        from = 1900;
        to = 1900; # minidlna
      }
    ];
    # firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    # firewall.enable = false;
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;
  services.printing.cups-pdf.enable = true;

  services.pipewire = {
    audio = { enable = true; };
    pulse = { enable = true; };
    wireplumber = { enable = true; };
  };

  services.blueman.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "au";
    options = "eurosign:e,caps:super";
  };

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    bluetooth.enable = true;

    # https://superuser.com/questions/899363/install-and-configure-nvidia-video-driver-nixos
    graphics.enable32Bit = true;

    # keep the displays working, by avoiding the 555 drivers and sticking with the 550 drivers
    # (see logs in the `display-manager` service)
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;

    # https://opentabletdriver.net/
    opentabletdriver.enable = true;
  };

  # Start with NumLock on.
  services.displayManager.sddm.autoNumlock = true;

  # Allow Workrave to save config changes
  # https://github.com/NixOS/nixpkgs/issues/56077#issuecomment-666416779
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable = true;

  # allow running Virtualbox VMs (like Windows)
  virtualisation = {
    # Allow vms built with `nixos-build-vms` to use hardware acceleration? (not verified)
    libvirtd.enable = true;

    podman.enable = true;

    # https://github.com/NixOS/nixpkgs/issues/47201#issuecomment-423798284
    docker = {
      enable = true;
      daemon.settings = {
        ipv6 = true;
        # fc00::/7 is for private subnets, this particular private subnet was
        # randomly generated at <https://simpledns.plus/private-ipv6>
        "fixed-cidr-v6" = "fd1a:2d1a:1955:7c04::/64";

        # try to avoid routing conflicts with the hambs vpn
        # (they have stuff running under 172.17, one of Docker's default pools)
        #
        # tip: if you were using 172.17.0.1 to get to the host through Docker's
        # default bridge IP, you may want to use the domain `host.docker.internal` instead.
        # (getting 'host not found'? try <https://stackoverflow.com/q/70725881/2014893>)
        bip = "10.41.0.5/16";
        default-address-pools = [
          # What do the '/16' in 'base' and '24' in 'size' mean? See:
          # https://stackoverflow.com/a/62176334/2014893
          {
            base = "10.42.0.0/16";
            size = 24;
          }
          {
            base = "10.43.0.0/16";
            size = 24;
          }
          {
            base = "10.44.0.0/16";
            size = 24;
          }
          {
            base = "10.45.0.0/16";
            size = 24;
          }
          {
            base = "10.46.0.0/16";
            size = 24;
          }
          {
            base = "10.47.0.0/16";
            size = 24;
          }
        ];
      };
    };
  };

  users = {
    extraGroups.vboxusers.members = [ "rkb" ];
    groups.docker = { members = [ "traefik" ]; };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.rkb = {
      isNormalUser = true;
      extraGroups = [
        "docker"
        "wheel" # Enable ‘sudo’ for the user.
        "libvirtd" # allow start/stop hardware-accelerated VMs on qemu? (not verified)
        "lxd"
      ];
      shell = pkgs.nushell;
    };
  };

  security = {
    rtkit.enable = true;
    pam.services = {
      kwallet = {
        name = "kwallet";
        enableKwallet = true;
      };
      sddm.enableGnomeKeyring = true;
    };
  };
  services.gnome.gnome-keyring.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # Looks like we need allowUnfree to use stuff like Google Chrome, Jetbrains, etc...
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.joypixels.acceptLicense = true;

  # enable nix-direnv to support Flakes
  programs.direnv.enable = true;

  # let's keep Windows happy by not touching the system clock timezone...
  time.hardwareClockInLocalTime = true;

  # don't ask for the root pw so often
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=120
  '';

  # needed for Home Manager?
  nix.settings.trusted-users = [ "root" "rkb" ];
}

