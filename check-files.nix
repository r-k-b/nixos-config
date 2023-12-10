{ tool, cmd, nixFiles, pkgs, stdenv }:
stdenv.mkDerivation {
  name = "check-${tool.pname}";
  src = nixFiles;
  buildPhase = ''
    set -eou pipefail
    ${tool}/bin/${cmd} | tee $out
  '';
}
