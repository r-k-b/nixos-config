# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
    autoOptimiseStore = true; # we're on an ssd, should be no downside?
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

      # PHD VPN
      server=/phd.com.au/10.20.60.12
      address=/phdccfs01/10.20.60.12
      address=/phdcchippo/10.20.60.20
      address=/phdcchpdev/10.20.60.25
      address=/phdccrtdev/10.20.60.21
      address=/phdccwestdev/10.20.60.24
    '';
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
    graphviz # includes tred
    htop
    icdiff
    keepassxc
    kdeconnect
    linuxPackages.rtl88x2bu
    linuxPackages.v4l2loopback # for OBS Studio's Virtual Camera
    mosh
    nix-du # for analyzing Store disk usage
    nixfmt
    nixpkgs-review
    ntfs3g
    obs-studio
    parted
    ripgrep
    screen
    sshfs
    stow
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
  programs.bash.interactiveShellInit =
    "source ${pkgs.autojump}/share/autojump/autojump.bash";

  # this might prove useful to debug nix package builds?
  programs.sysdig.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };

  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints.web = {
        address = ":7788";
        #http = ":7780";
      };
      group = "docker";
      api = {
        dashboard = true;
        insecure = true;
        debug = true;
      };
      providers.docker = true;
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
  services.dbus.packages = [ pkgs.gnome3.dconf ];

  # allow running Virtualbox VMs (like Windows)
  virtualisation.virtualbox.host.enable = true;
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
  nix.trustedUsers = [ "root" "rkb" ];
}

