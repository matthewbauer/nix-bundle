{nixpkgs ? import <nixpkgs> {}}:

with nixpkgs;

let
  arx' = haskellPackages.arx.overrideAttrs (o: {
    patchPhase = (o.patchPhase or "") + ''
      substituteInPlace model-scripts/tmpx.sh \
        --replace /tmp/ \$HOME/.cache/
    '';
  });
in rec {
  arx = { archive, startup}:
    stdenv.mkDerivation {
      name = "arx";
      buildCommand = ''
        ${arx'}/bin/arx tmpx --shared -rm! ${archive} -o $out // ${startup}
        chmod +x $out
      '';
    };

  maketar = { targets }:
    stdenv.mkDerivation {
      name = "maketar";
      buildInputs = [ perl ];
      exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) targets;
      buildCommand = ''
        storePaths=$(perl ${pathsFromGraph} ./closure-*)

        tar -cf - \
          --owner=0 --group=0 --mode=u+rw,uga+r \
          --hard-dereference \
          $storePaths | xz -1 -T $(nproc) > $out
      '';
    };

  proot' = proot.overrideAttrs (_: {
    # hack to use when /nix/store is not available
    postFixup = ''
      exe=$out/bin/proot
      patchelf \
        --set-interpreter .$(patchelf --print-interpreter $exe) \
        --set-rpath $(patchelf --print-rpath $exe | sed 's|/nix/store/|./nix/store/|g') \
        $exe
    '';
  });

  makebootstrap = { targets, startup }:
    arx {
      inherit startup;
      archive = maketar {
        inherit targets;
      };
    };

  makeStartup = { target, nixUserChrootFlags, proot, run }:
    writeScript "startup" ''
      #!/bin/sh
      .${proot}/bin/proot -b ./nix:/nix ${target}${run} $@
    '';

  nix-bootstrap = { target, extraTargets ? [], run, proot ? proot', nixUserChrootFlags ? "" }:
    let
      script = makeStartup { inherit target nixUserChrootFlags proot run; };
    in makebootstrap {
      startup = ".${script} '\"$@\"'";
      targets = [ "${script}" ] ++ extraTargets;
    };

  nix-bootstrap-nix = {target, run, extraTargets ? []}:
    nix-bootstrap-path {
      inherit target run;
      extraTargets = [ gnutar bzip2 xz gzip coreutils bash ];
    };

  # special case adding path to the environment before launch
  nix-bootstrap-path = let
    proot'' = targets: proot'.overrideDerivation (o: {
      # TODO: not sure yet what we need to do here
    }); in { target, extraTargets ? [], run }: nix-bootstrap {
      inherit target extraTargets run;
      proot = proot'' extraTargets;
    };
}
