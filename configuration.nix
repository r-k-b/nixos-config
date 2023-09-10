# Edit this configuration file to define what should be installed on

# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true; # we're on an ssd, should be no downside?
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
      automatic = true;
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
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot = {
    extraModulePackages = [
      config.boot.kernelPackages.rtl88x2bu
      config.boot.kernelPackages.v4l2loopback.out
    ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking = {
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
  };

  # so we can use custom subdomains in development, and with traefik
  services.dnsmasq = {
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
        "/phdccfs01/10.20.60.12"
        "/phdcchippo/10.20.60.20"
        "/phdcchpdev/10.20.60.25"
        "/phdccrtdev/10.20.60.21"
        "/phdccwestdev/10.20.60.24"

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

        # PHD VPN
        "/phd.com.au/10.20.60.10"
        "/pacifichealthdynamics.com.au/10.20.60.10"

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

  # for the HAMBS VPN
  services.globalprotect = {
    enable = true;
    # if you need a Host Integrity Protection report
    # csdWrapper = "${pkgs.openconnect}/libexec/openconnect/hipreport.sh";
  };

  # browse samba shares in gui apps
  services.gvfs.enable = true;

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

  services.sysstat = {
    enable = true;
  };

  fileSystems."/mnt/blestion" = {
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

  fileSystems."/mnt/smiticia" = {
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
      mplus-outline-fonts.githubRelease
      dina-font
      open-dyslexic
      proggyfonts
      nerdfonts
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

  environment.pathsToLink = [ "/share/nix-direnv" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alloy # for finding bugs without running or looking at code
    anki
    ark
    autossh
    bat # for previews in fzf
    bind
    broot # for interactively exploring folder structures
    calibre
    cifs-utils # explore samba shares
    cntr # for debugging nix package builds
    diffoscope # for examining differences in files that should be the same
    direnv
    distrobox # easily install apps not already packaged for Nix (.deb, .rpm etc)
    docker
    dropbox # for keyring backups
    du-dust # to quickly see what's taking up space in a folder
    duf # a quick look at how much space & inodes are left
    entr # re-run command on file change
    feh # decent image viewer
    filelight # visualize disk usage (cf. du-dust)
    firefox
    flameshot # screenshots
    font-manager
    fzf
    git
    gimp # bitmap image editor
    globalprotect-openconnect # HAMBS vpn
    google-chrome
    google-chrome-dev
    gparted
    gping # a neat way to gauge connection health
    graphviz # includes tred
    helvum # a "patchbay" for connecting audio sink and source nodes; good for streaming audio
    htop
    hyx # a nice quick hex editor for the terminal
    icdiff
    inxi # for quick info about the system
    jetbrains.datagrip
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.rider
    jetbrains.webstorm
    jless # for quick exploration of large json
    jq
    plasma5Packages.kdeconnect-kde
    keepassxc
    kitty # avoids the "missing emoji" problem that konsole has
    libnotify # for showing alerts from scripts
    libreoffice
    linuxPackages.rtl88x2bu
    linuxPackages.v4l2loopback # for OBS Studio's Virtual Camera
    mosh
    msgviewer # for outlook .msg files
    nix-direnv # prevents gc of dev environments
    nix-du # for analyzing Store disk usage
    nix-tree # for examining the content of store paths
    nixfmt
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
    redshift
    remmina
    ripgrep
    scc # for quick line counts by language
    screen
    screenkey # for showing keys pressed in recordings
    silver-searcher # ag
    simplescreenrecorder
    slop # required by screenkey
    sox # for keeping the audio sink active, and things like `play -n synth brownnoise vol 0.6`
    sshfs
    stow
    sysstat # for finding why the system is slow
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
    wget
    wine
    xdg-utils # fix file associations?
    xdotool
    xsel # clipboard helper
    zgrviewer # for interactively visualizing .dot files; like `nix-du -s=500MB | tred > store.dot`
    zoom-us
    zoxide # quick access to files & folders
  ];

  # Autojump doesn't work out of the box, so this is needed?
  # https://github.com/NixOS/nixpkgs/pull/47334#issuecomment-439577344
  # also adds an fzf integration; use `j` with no args.
  programs.bash.interactiveShellInit = ''
    source ${pkgs.autojump}/share/autojump/autojump.bash
    j() {
        if [[ "$#" -ne 0 ]]; then
            cd $(autojump $@)
            return
        fi
        cd "$(autojump -s | sort -k1gr | awk '$1 ~ /[0-9]:/ && $2 ~ /^\// { for (i=2; i<=NF; i++) { print $(i) } }' |  fzf --height 40% --reverse --inline-info)"
    }
  '';

  programs.bash.promptInit = ''
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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    configure = {
      customRC = ''
        " show whitespace
        set list
        set listchars=tab:>-

        set relativenumber
        set number
      '';
      packages.myNeovimPackage = with pkgs.vimPlugins; {
        # loaded on launch
        start = [
          editorconfig-vim
          vim-airline
          vim-better-whitespace
          vim-gitgutter
          vim-nix
        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [ ];
      };
    };
  };

  # For easier running of unpatched binaries, like GlobalProtect VPN
  # https://nixos.wiki/wiki/Steam
  programs.steam = { enable = true; };

  # this might prove useful to debug nix package builds?
  programs.sysdig.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # https://github.com/Mic92/nix-ld#nix-ld
  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld.enable = true;

  # an alternative to ssh-agent. involves the pinentry program.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "qt";
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # Local dev (Hippo, etc)
  networking.firewall.allowedTCPPortRanges = [
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
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 1714;
      to = 1764;
    } # kdeconnect
    {
      from = 1900;
      to = 1900; # minidlna
    }
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  services.pipewire = {
    audio = { enable = true; };
    pulse = { enable = true; };
  };

  hardware.bluetooth.enable = true;

  services.blueman.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e,caps:super";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # https://superuser.com/questions/899363/install-and-configure-nvidia-video-driver-nixos
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.driSupport32Bit = true;

  # Start with NumLock on.
  services.xserver.displayManager.sddm.autoNumlock = true;

  # Allow Workrave to save config changes
  # https://github.com/NixOS/nixpkgs/issues/56077#issuecomment-666416779
  services.dbus.packages = [ pkgs.dconf ];
  programs.dconf.enable = true;

  # allow running Virtualbox VMs (like Windows)
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  users.extraGroups.vboxusers.members = [ "rkb" ];

  # Allow vms built with `nixos-build-vms` to use hardware acceleration? (not verified)
  virtualisation.libvirtd.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/47201#issuecomment-423798284
  virtualisation.docker = {
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

  users.groups.docker = { members = [ "traefik" ]; };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rkb = {
    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel" # Enable ‘sudo’ for the user.
      "libvirtd" # allow start/stop hardware-accelerated VMs on qemu? (not verified)
      "lxd"
    ];
  };

  security.pam.services.kwallet = {
    name = "kwallet";
    enableKwallet = true;
  };
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  # Looks like we need allowUnfree to use stuff like Google Chrome, Jetbrains, etc...
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.joypixels.acceptLicense = true;

  # enable nix-direnv to support Flakes
  nixpkgs.overlays = [
    (self: super: {
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
    })
  ];

  # let's keep Windows happy by not touching the system clock timezone...
  time.hardwareClockInLocalTime = true;

  # don't ask for the root pw so often
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=120
  '';

  # needed for Home Manager?
  nix.settings.trusted-users = [ "root" "rkb" ];
}

