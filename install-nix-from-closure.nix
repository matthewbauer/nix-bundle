{ stdenv, fetchFromGitHub, nix, cacert }:

  stdenv.mkDerivation {
    name = "nix-bootstrap";

    src = fetchFromGitHub {
      owner = "matthewbauer";
      repo = "nix-bootstrap";
      rev = "cc882b2cb92d8de87dad9cb890ad1745b06a9787";
      sha256 = "05w6xjg0cgz6a4szc7jd7v53bmy4zjrgph5xkgyj73g62jyq7ajf";
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
