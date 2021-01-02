# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;

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

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set your time zone.
  time.timeZone = "Australia/Sydney";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    autojump
    bind
    direnv
    docker
    firefox
    git
    glibcLocales
    google-chrome
    gparted
    htop
    icdiff
    keepassxc
    mosh
    nixfmt
    ntfs3g
    parted
    screen
    sshfs
    stow
    tmux
    vim
    wget
    xdotool
  ];

  # Autojump doesn't work out of the box, so this is needed?
  # https://github.com/NixOS/nixpkgs/pull/47334#issuecomment-439577344
  programs.bash.interactiveShellInit =
    "source ${pkgs.autojump}/share/autojump/autojump.bash";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # Local dev (Hippo, etc)
  networking.firewall.allowedTCPPortRanges = [
    { from = 8000; to = 8099; }
    { from = 5000; to = 5099; }
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
  services.xserver.xkbOptions = "eurosign:e";

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

  # Allow vms built with `nixos-build-vms` to use hardware acceleration? (not verified)
  virtualisation.libvirtd.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/47201#issuecomment-423798284
  virtualisation.docker.enable = true;

  users.groups.docker = {};

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
  services.gnome3.gnome-keyring.enable = true;
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

