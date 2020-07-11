This NixOS code ensures that the system provide version-specific `$LOCALE_ARCHIVE`
environment variables to mitigate the effects of
https://github.com/NixOS/nixpkgs/issues/38991.

To deploy it, copy the file into your `/etc/nixos` folder using a file name
like `multi-glibc-locale-paths.nix`. Then edit your `configuration.nix` file to
contain the attribute:

    imports = [ ./multi-glibc-locale-paths.nix ];

If you are running Nix on a host system other than NixOS, you'll have to
configure those environment variables manually:

* Set `$LOCALE_ARCHIVE_2_27` to the path
  `"${glibcLocales}/lib/locale/locale-archive"`. You can find out what
  `glibcLocales` is by running:

        $ nix-build --no-out-link "<nixpkgs>" -A glibcLocales
        /nix/store/m53mq2077pfxhqf37gdbj7fkkdc1c8hc-glibc-locales-2.27

* Set `$LOCALE_ARCHIVE_2_11` to the path of your system's locale.
