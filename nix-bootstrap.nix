{ stdenv, fetchFromGitHub, nix, cacert }:

  stdenv.mkDerivation {
    name = "nix-bootstrap";

    src = fetchFromGitHub {
      owner = "matthewbauer";
      repo = "nix-bootstrap";
      rev = "47bc67bbc5cd71fba9c9b0d07f967023b94e8ffa";
      sha256 = "1jy52hhmbdn1hgc10x73kqx8dc38piz589mjbj07rp4vx0qc9alw";
    };

    propagatedBuildInputs = [ nix cacert ];

    installPhase = ''
      mkdir -p $out/
      substitute install-nix-from-closure.sh $out/install \
        --subst-var-by nix .${nix} \
        --subst-var-by cacert .${cacert}
      chmod +x $out/install
    '';
  }
