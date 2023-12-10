#!/usr/bin/env nu

watch . --glob=**/*.nix {|| clear; do -i { nixfmt -c **/*.nix }; do -i { statix check }; deadnix; }

