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
  nix-user-chroot = stdenv.mkDerivation {
    name = "nix-user-chroot-2b144e";
    src = fetchFromGitHub {
      owner = "matthewbauer";
      repo = "nix-user-chroot";
      rev = "2b144ee89568ba40b66317da261ce889fbda3674";
      sha256 = "16bmshhvk6941w04rx78i5a1305876qni2n2rvm7rkziz49j158n";
    };

    postFixup = ''
      exe=$out/bin/nix-user-chroot
      patchelf \
        --set-interpreter .$(patchelf --print-interpreter $exe) \
        --set-rpath $(patchelf --print-rpath $exe | sed 's|/nix/store/|./nix/store/|g') \
        $exe
    '';

    installPhase = ''
      mkdir -p $out/bin/
      cp nix-user-chroot $out/bin/nix-user-chroot
    '';
  };

  makebootstrap = { targets, startup }:
    arx {
      inherit startup;
      archive = maketar {
        inherit targets;
      };
    };

  nix-bootstrap = { target, run }:
    makebootstrap {
      startup = ''.${nix-user-chroot}/bin/nix-user-chroot ./nix ${target}${run} \$@'';
      targets = [ nix-user-chroot target ];
    };
}
