{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

rec {
  arx = { archive, startup}:
    stdenv.mkDerivation {
      name = "arx";
      buildCommand = ''
        ${haskellPackages.arx}/bin/arx tmpx ${archive} -rm! -o $out // ${startup}
        chmod +x $out
      '';
    };

  maketar = { targets }:
    stdenv.mkDerivation {
      name = "maketar";
      buildInputs = [gnutar perl bzip2];
      exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) targets;
      buildCommand = ''
        storePaths=$(perl ${pathsFromGraph} ./closure-*)

        tar cfj $out \
          --owner=0 --group=0 --mode=u+rw,uga+r \
          --hard-dereference \
          $storePaths
      '';
    };

  # TODO: eventually should this go in nixpkgs?
  nix-user-chroot = stdenv.lib.makeOverridable stdenv.mkDerivation {
    name = "nix-user-chroot-2b144e";
    src = fetchFromGitHub {
      owner = "matthewbauer";
      repo = "nix-user-chroot";
      rev = "2b144ee89568ba40b66317da261ce889fbda3674";
      sha256 = "16bmshhvk6941w04rx78i5a1305876qni2n2rvm7rkziz49j158n";
    };

    # hack to use when /nix/store is not available
    postFixup = ''
      exe=$out/bin/nix-user-chroot
      patchelf \
        --set-interpreter .$(patchelf --print-interpreter $exe) \
        --set-rpath $(patchelf --print-rpath $exe | sed 's|/nix/store/|./nix/store/|g') \
        $exe
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin/
      cp nix-user-chroot $out/bin/nix-user-chroot

      runHook postInstall
    '';
  };

  makebootstrap = { targets, startup }:
    arx {
      inherit startup;
      archive = maketar {
        inherit targets;
      };
    };

  nix-bootstrap = { target, extraTargets ? [], run, nix-user-chroot' ? nix-user-chroot }:
    makebootstrap {
      startup = ''.${nix-user-chroot'}/bin/nix-user-chroot ./nix ${target}${run} \$@'';
      targets = [ nix-user-chroot' target ] ++ extraTargets;
    };

  # special case handling because of impurities in nix bootstrap
  # anything that needs Nix will have to have these setup before they can be run
  nix-bootstrap-nix = let
    nix-user-chroot' = nix-user-chroot.override {
      buildInputs = [ cacert gnutar bzip2 gzip coreutils ];
      makeFlags = [
        ''NIX_SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"''
        ''NIX_PATH="nixpkgs=https://github.com/matthewbauer/nixpkgs/archive/nix-bundle.tar.gz"''
        ''ENV_PATH="${stdenv.lib.makeBinPath [ coreutils gnutar bzip2 gzip bash ]}"''
      ];
    }; in { target, extraTargets ? [], run }: nix-bootstrap { inherit target extraTargets run nix-user-chroot'; };

  # special case adding path to the environment before launch
  nix-bootstrap-path = let
    nix-user-chroot'' = targets: nix-user-chroot.override {
      buildInputs = targets;
      makeFlags = [
        ''ENV_PATH="${stdenv.lib.makeBinPath targets}"''
      ];
    }; in { target, extraTargets ? [], run }: nix-bootstrap {
      inherit target extraTargets run;
      nix-user-chroot' = nix-user-chroot'' extraTargets;
    };
}
