{ config, inputs, lib, pkgs, ... }: {
  nixpkgs.config = {
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "starsector" "starsector-0.97a-RC11" ];
  };

  environment.systemPackages = with pkgs; [
    alloy # for finding bugs without running or looking at code
    anki
    calibre
    cntr # for stepping into broken nix builds, at the point they failed
    config.boot.kernelPackages.perf # https://www.brendangregg.com/blog/2017-05-09/cpu-utilization-is-wrong.html
    distrobox # easily install apps not already packaged for Nix (.deb, .rpm etc)
    dive # for exploring docker images
    docker
    easyeffects # convert a dodgy stereo mic into a good mono mic
    espeak # say text out loud
    feh # decent image viewer
    firefox
    flameshot # screenshots
    font-manager
    gimp # bitmap image editor
    gparted
    gpclient # HAMBS vpn
    gping # a neat way to gauge connection health
    graphviz # includes tred
    gromit-mpx # draw on the screen; like KDE Plasma's Mouse Mark effect
    kubernetes-helm # for doing ...something... to k8s
    helvum # a "patchbay" for connecting audio sink and source nodes; good for streaming audio (vs qpwgraph?)
    inputs.browserPreviews.packages.x86_64-linux.google-chrome
    inputs.browserPreviews.packages.x86_64-linux.google-chrome-dev
    plasma5Packages.kdeconnect-kde
    k9s # for exploring kubernetes clusters
    kdePackages.ark
    kdePackages.filelight # visualize disk usage (cf. du-dust)
    kdePackages.kdenlive # for video editing
    kdePackages.okular
    keepassxc
    kitty # avoids the "missing emoji" problem that konsole has
    kubectl # control k8s, needed for shells in k9s
    libnotify # for showing alerts from scripts
    libreoffice
    linuxPackages.rtl88x2bu
    linuxPackages.v4l2loopback # for OBS Studio's Virtual Camera
    msgviewer # for outlook .msg files
    nixos-generators # turn a NixOS config into an iso/vm/container image/etc
    nixpkgs-review # for reviewing nixpkgs PRs
    notepadqq
    ntfs3g
    obs-studio
    okteta # a powerful hex editor for the gui
    openconnect # work VPNs
    parted
    pavucontrol # Can pavucontrol bring back the system sounds? https://www.reddit.com/r/kde/comments/6838fr/system_sounds_keep_breaking/
    qpwgraph # a "patchbay" for connecting audio sink and source nodes; good for streaming audio
    quickemu # handles the annoying bits of finding OS ISOs
    redshift
    remmina
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
    starsector # 2D space shooter
    stern # for tailing all the logs from a kubernetes cluster
    tlaplusToolbox # formal methods tool
    tor-browser-bundle-bin # avoid censorship of websites
    unclutter-xfixes # hide the cursor on inactivity
    unipicker # quick search for unicode characters
    vlc
    vpn-slice # for keeping non-HAMBS traffic out of the HAMBS vpn
    xdg-utils # fix file associations?
    xdotool
    xsel # clipboard helper
    zgrviewer # for interactively visualizing .dot files; like `nix-du -s=500MB | tred > store.dot`
  ];
}
