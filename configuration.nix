# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# Applies across all machines.
# For machine-specifics, look under `flags/`, and in `flake.nix` under
# `nixosConfigurations`.

{ config, flags, inputs, pkgs, ... }: {
  nix = {
    settings = {
      auto-optimise-store = true; # we're on an ssd, should be no downside?

      # https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md#tested-using-sandboxing
      sandbox = true;
    };
    package = pkgs.nixVersions.stable;
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

  # Include the results of the hardware scan.
  inherit (flags) imports;

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot = {
      enable = true;
      configurationLimit = 30;
    };
    loader.efi.canTouchEfiVariables = true;

    # Increase the amount of inotify watchers
    # Note that inotify watches consume 1kB on 64-bit machines.
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 1048576; # default:  8192
      "fs.inotify.max_user_instances" = 1024; # default:   128
      "fs.inotify.max_queued_events" = 32768; # default: 16384
    };
  } // (flags.boot config);

  powerManagement.cpuFreqGovernor = "performance";

  services = {
    # so we can use custom subdomains in development, and with traefik
    ${if flags.use_dnsmasq then "dnsmasq" else null} = {
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
  } // {
    ${if flags.hosts_promgraf then "grafana" else null} = {
      enable = true;
      #domain = "grafana.pele";
      settings.server = {
        port = 2342;
        addr = "127.0.0.1";
      };
    };
  } // {
    ${if flags.hosts_github_runner then "github-runners" else null} = {
      phdsys-webapp = {
        enable = true;
        url = "https://github.com/Pacific-Health-Dynamics/PHDSys-webapp";
        # tip: the tokens generated through the "Create self-hosted runner" web UI
        # expire ludicrously fast; if you get a 404, try getting a fresh token.
        tokenFile = "/home/rkb/.github-runner/tokens/phdsys-webapp";
        extraLabels = [ "nix" ];
        extraPackages = with pkgs; [ acl curl docker gawk openssh which ];
        # don't forget to add the use for this runner to `users.groups.docker.members`, down below.
        # (the username comes from the name of the runner, like `github-runners-phdsys-webapp`)
        # Also, you may need to restart the `docker.service` and the `github-runner-phdsys-webapp.service`
        # before the group change takes effect.
      };
    };
  } // {
    # Enable the KDE Desktop Environment.
    ${if flags.headless then null else "displayManager"}.sddm.enable = true;
  } // {

    # browse samba shares in gui apps
    gvfs.enable = true;

    # extend the life of SSDs?
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    prometheus = {
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

    sysstat = { enable = true; };

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    lorri.enable = true;

    # Enable CUPS to print documents.
    # printing.enable = true;
    printing.cups-pdf.enable = true;

    ${if flags.mute then null else "pipewire"} = {
      audio = { enable = true; };
      pulse = { enable = true; };
      wireplumber = { enable = true; };
    };

    blueman.enable = true;

    # Enable the X11 windowing system.
    ${if flags.headless then null else "xserver"} = {
      enable = true;
      xkb = {
        layout = "au";
        options = "eurosign:e,caps:super";
      };
      desktopManager.plasma5.enable = true;
      videoDrivers = [ "nvidia" ];
    };

    # Enable touchpad support.
    # xserver.libinput.enable = true;

    # Start with NumLock on.
    displayManager.sddm.autoNumlock = true;

    # Allow Workrave to save config changes
    # https://github.com/NixOS/nixpkgs/issues/56077#issuecomment-666416779
    dbus.packages = [ pkgs.dconf ];

    gnome.gnome-keyring.enable = !flags.headless;
  } // flags.services;

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

  inherit (flags) fileSystems;

  ${if flags.hosts_torrents then "nixarr" else null} = {
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

  fonts = if flags.headless then
    { }
  else {
    enableDefaultPackages = true;
    packages = with pkgs; [
      iosevka
      gyre-fonts
      noto-fonts
      noto-fonts-cjk-sans
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
      autossh
      bat # for colorized previews in fzf
      bind
      broot # for interactively exploring folder structures
      btop # perf mon, shows cpu temps & network usage too
      cifs-utils # explore samba shares
      curl
      deadnix # Find and remove unused code in .nix source files
      difftastic # for easy to read git diffs
      direnv
      du-dust # to quickly see what's taking up space in a folder
      duf # a quick look at how much space & inodes are left
      entr # file watcher; re-run command on file change
      fzf
      git
      htop
      hyperfine # for getting benchmarking stats on terminal commands
      hyx # a nice quick hex editor for the terminal
      icdiff
      inputs.nvimconf.packages.x86_64-linux.default
      inxi # for quick info about the system
      jless # for quick exploration of large json
      jq
      just # for self-explaining dev shells
      mosh
      nix-direnv # prevents gc of dev environments
      nix-du # for analyzing Store disk usage
      nix-output-monitor # for fancier build progress
      nix-tree # for examining the content of store paths
      nixfmt-classic
      nushell # a nicer shell than bash?
      ripgrep
      sshfs
      statix # Lints & suggestions for .nix files
      stow
      sysstat # for finding why the system is slow
      systemctl-tui # for easily finding & following journalctl logs
      tldr # quick examples for commands
      tmux
      tree
      up # Ultimate Plumber, for quickly iterating on shell commands
      watchexec # file watcher; for doing things repeatedly on file change
      wget
      zoxide # quick access to files & folders
    ];
  };

  programs = {
    #    # Autojump doesn't work out of the box, so this is needed?
    #    # https://github.com/NixOS/nixpkgs/pull/47334#issuecomment-439577344
    #    # also adds an fzf integration; use `j` with no args.
    #    bash.interactiveShellInit = ''
    #      source ${pkgs.autojump}/share/autojump/autojump.bash
    #      j() {
    #          if [[ "$#" -ne 0 ]]; then
    #              cd $(autojump $@)
    #              return
    #          fi
    #          cd "$(autojump -s | sort -k1gr | awk '$1 ~ /[0-9]:/ && $2 ~ /^\// { for (i=2; i<=NF; i++) { print $(i) } }' |  fzf --height 40% --reverse --inline-info)"
    #      }
    #    '';
    #
    #    bash.promptInit = ''
    #      function extraDollars {
    #        # show an extra $ in the prompt for every SHLVL-deep we are.
    #        if [[ $SHLVL != 1 ]]; then
    #            printf '$%.0s' $(seq 1 $(($SHLVL - 1)));
    #        fi;
    #      };
    #
    #      # Provide a nice prompt if the terminal supports it.
    #      if [ "$TERM" != "dumb" ] || [ -n "$INSIDE_EMACS" ]; then
    #        PROMPT_COLOR="1;31m"
    #        ((UID)) && PROMPT_COLOR="1;32m"
    #        if [ -n "$INSIDE_EMACS" ] || [ "$TERM" = "eterm" ] || [ "$TERM" = "eterm-color" ]; then
    #          # Emacs term mode doesn't support xterm title escape sequence (\e]0;)
    #          PS1="\n\[\033[$PROMPT_COLOR\][\u@\h:\w]\\$\$(extraDollars)\[\033[0m\] "
    #        else
    #          PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\$(extraDollars)\[\033[0m\] "
    #        fi
    #        if test "$TERM" = "xterm"; then
    #          PS1="\[\033]2;\h:\u:\w\007\]$PS1"
    #        fi
    #      fi
    #    '';

    # For easier running of unpatched binaries, like GlobalProtect VPN
    # https://nixos.wiki/wiki/Steam
    ${if flags.headless then null else "steam"} = {
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
    nix-ld.enable = !flags.headless;

    # an alternative to ssh-agent. involves the pinentry program.
    gnupg.${if flags.headless then null else "agent"} = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # List services that you want to enable:

  programs.mosh.enable = true;

  inherit (flags) networking;

  ${if flags.headless then null else "hardware"} = {
    bluetooth.enable = true;

    # https://superuser.com/questions/899363/install-and-configure-nvidia-video-driver-nixos
    graphics.enable32Bit = true;

    # keep the displays working, by avoiding the 555 drivers and sticking with the 550 drivers
    # (see logs in the `display-manager` service)
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.production;

    # https://opentabletdriver.net/
    opentabletdriver.enable = true;
  };
  # Allow Workrave to save config changes
  # https://github.com/NixOS/nixpkgs/issues/56077#issuecomment-666416779
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
    groups.docker = {
      members = [ "traefik" ] ++ (if flags.hosts_github_runner then
        [ "github-runner-phdsys-webapp" ]
      else
        [ ]);
    };

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
      initialPassword = "hunter2";
    };
  };

  security = {
    # helps with getting minidlna to rescan the drives
    doas.enable = true;

    rtkit.enable = !flags.mute;
    ${if flags.headless then null else "pam"}.services = {
      kwallet = {
        name = "kwallet";
        enableKwallet = true;
      };
      sddm.enableGnomeKeyring = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  nixpkgs.config = {
    permittedInsecurePackages = if flags.hosts_github_runner then
      [
        "nodejs-16.20.1" # for github-runners; see https://github.com/orgs/community/discussions/53217
      ]
    else
      [ ];

    joypixels.acceptLicense = true;
  };

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
