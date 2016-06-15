{ stdenv, fetchFromGitHub, writeText, nix, cacert }:

let

  run-from-closure = writeText "run-from-closure" (builtins.readFile ./run-from-closure.sh);

in

  stdenv.mkDerivation {
    name = "nix-bootstrap";

    propagatedBuildInputs = [ nix cacert ];

    buildCommand = ''
      mkdir -p $out/bin/
      substitute ${run-from-closure} $out/bin/run-from-closure \
        --subst-var-by nix ${nix.out} \
        --subst-var-by cacert ${cacert}
      chmod +x $out/bin/run-from-closure
    '';
  }
