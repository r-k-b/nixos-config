# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
    settings = {
      auto-optimise-store = true; # we're on an ssd, should be no downside?
    };
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
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
    extraConfig = ''
      address=/localhost/127.0.0.1
      address=/nixos/192.168.1.103
      address=/strator/192.168.1.98
      address=/nixos-strator/192.168.1.98

      # PHD VPN
      server=/phd.com.au/10.20.60.10
      server=/pacifichealthdynamics.com.au/10.20.60.10
      address=/phdccfs01/10.20.60.12
      address=/phdcchippo/10.20.60.20
      address=/phdcchpdev/10.20.60.25
      address=/phdccrtdev/10.20.60.21
      address=/phdccwestdev/10.20.60.24
    '';
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
      # For dates formatted like ISO8601
      # https://serverfault.com/a/17184/276263
      LC_TIME = "en_DK.UTF-8";
    };
    supportedLocales = [ "all" ];
  };

  services.grafana = {
    enable = true;
    #domain = "grafana.pele";
    port = 2342;
    addr = "127.0.0.1";
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

  fileSystems."/mnt/blestion" = {
    device = "//192.168.1.98/blestion";
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
    enableDefaultFonts = true;
    fonts = with pkgs; [
      gyre-fonts
      #noto-coloremoji-fonts # no such thing in nixpkgs? would like the Emoji Selector to work...
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      mplus-outline-fonts
      dina-font
      open-dyslexic
      proggyfonts
      nerdfonts
    ];
    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = true;
      #defaultFonts = {
      #  monospace = [ "DejaVu Sans Mono" "Noto Mono" ];
      #  serif = [ "Vollkorn" "Noto Serif" "Times New Roman" ];
      #  sansSerif = [ "Open Sans" "Noto Sans" ];
      #  emoji = [ "Noto Color Emoji" "Twitter Color Emoji" "JoyPixels" "Unifont" "Unifont Upper" ];
      #};
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alloy # for finding bugs without running or looking at code
    autojump
    bind
    broot # for interactively exploring folder structures
    cntr # for debugging nix package builds
    direnv
    docker
    firefox
    git
    glibcLocales
    google-chrome
    gparted
    gping # a neat way to gauge connection health
    graphviz # includes tred
    htop
    hyx # a nice quick hex editor for the terminal
    icdiff
    keepassxc
    kdeconnect
    linuxPackages.rtl88x2bu
    linuxPackages.v4l2loopback # for OBS Studio's Virtual Camera
    mosh
    nix-du # for analyzing Store disk usage
    nix-tree # for examining the content of store paths
    nixfmt
    nixpkgs-review
    ntfs3g
    obs-studio
    okteta # a powerful hex editor for the gui
    parted
    ripgrep
    screen
    screenkey # for showing keys pressed in recordings
    slop # required by screenkey
    sshfs
    stow
    tlaplusToolbox # formal methods tool
    tmux
    tree
    up # Ultimate Plumber, for quickly iterating on shell commands
    vim
    wget
    xdotool
    zgrviewer # for interactively visualizing .dot files; like `nix-du -s=500MB | tred > store.dot`
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

  # this might prove useful to debug nix package builds?
  programs.sysdig.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;

  # https://github.com/Mic92/nix-ld#nix-ld
  # Run unpatched dynamic binaries on NixOS.
  programs.nix-ld.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
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
    {from=8200; to=8200;} # to access minidlna servers???
    {
      from = 9100;
      to = 9100; # node exporter for prometheus
    }
  ];
  networking.firewall.allowedUDPPortRanges = [{
    from = 1714;
    to = 1764;
  } # kdeconnect
    ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.bluetooth.enable = true;

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

  # allow running Virtualbox VMs (like Windows)
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  users.extraGroups.vboxusers.members = [ "rkb" ];

  # Allow vms built with `nixos-build-vms` to use hardware acceleration? (not verified)
  virtualisation.libvirtd.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/47201#issuecomment-423798284
  virtualisation.docker.enable = true;

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

  # let's keep Windows happy by not touching the system clock timezone...
  time.hardwareClockInLocalTime = true;

  # don't ask for the root pw so often
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=120
  '';

  # needed for Home Manager?
  nix.settings.trusted-users = [ "root" "rkb" ];
}

