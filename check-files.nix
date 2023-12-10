{ tool, cmd, nixFiles, stdenv }:
stdenv.mkDerivation {
  name = "check-${tool.pname}";
  src = nixFiles;
  buildPhase = ''
    set -eou pipefail
    shopt -s globstar
    ${tool}/bin/${cmd} | tee $out
  '';
}
