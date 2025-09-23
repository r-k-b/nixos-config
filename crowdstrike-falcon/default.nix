# based on <https://gist.github.com/klDen/c90d9798828e31fecbb603f85e27f4f1>
{ autoPatchelfHook, buildFHSEnv, dpkg, lib, libnl, openssl, stdenv, zlib }:
let
  inherit (lib) fileset;
  pname = "falcon-sensor";
  version = "7.29.0-18202";
  arch = "amd64";
  src = fileset.toSource {
    root = ./.;
    fileset = fileset.unions [
      # grab installers from `\\HMB-FPS-001.internal.hambs.com.au\common\Installs\CrowdstrikeAV`
      ./falcon-sensor_7.29.0-18202_amd64.deb
    ];
  };
  falcon-sensor = stdenv.mkDerivation {
    inherit version arch src;
    name = pname;
    buildInputs = [ dpkg zlib autoPatchelfHook ];
    #sourceRoot = ".";
    unpackPhase = ''
      ls -la
      ls -la "$src"
      echo src="$src"
      dpkg-deb -x $src/${pname}_${version}_${arch}.deb .
    '';
    installPhase = ''
      cp -r . $out
    '';
    meta = with lib; {
      description = "Crowdstrike Falcon Sensor";
      homepage = "https://www.crowdstrike.com/";
      license = licenses.unfree;
      platforms = platforms.linux;
    };
  };
in buildFHSEnv {
  name = "falcon-sensor-bash";
  targetPkgs = _: [ libnl openssl zlib ];
  extraInstallCommands = ''
    ln -s "${falcon-sensor}"/* "$out"/
    mkdir -p "$out"/bin
    ln -s "${falcon-sensor}"/opt/CrowdStrike/falconctl "$out"/bin/falconctl
  '';
  runScript = "bash";
}
