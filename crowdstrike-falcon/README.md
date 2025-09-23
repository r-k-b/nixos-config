# setup

## copy the Ubuntu (.deb) installer into this folder

eg:

```
mv ~/Downloads/falcon-sensor_7.29.0-18202_amd64.deb /etc/nixos/crowdstrike-falcon
```

NB: I'm not using the `/opt/crowdstrike` folder as in the base gist, as that
requires `--impure`.
Seems like the installer shouldn't be made public, either, so DO NOT commit it
to this repo's git history.


## install falcon-sensor derivation e.g. nixos-rebuild or flake

like `nh os switch /etc/nixos`


## activate your CID if needed

sudo falconctl -f -s --cid='YOUR_CID'


## restart service

```
sudo systemctl restart falcon-sensor
sudo systemctl status falcon-sensor # service should be active and running
```


# problems

## falconctl CLI does not run

```
$ falconctl

ERROR: unable to initialize simple store
```

check: is the `falcon-sensor.service` already running? what's in those logs?
