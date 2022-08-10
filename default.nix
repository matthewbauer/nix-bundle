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
  toStorePath = target:
    # If a store path has been given but is not a derivation, add the missing context
    # to it so it will be propagated properly as a build input.
    if !(lib.isDerivation target) && lib.isStorePath target then
      let path = toString target; in
      builtins.appendContext path { "${path}" = { path = true; }; }
    # Otherwise, add to the store. This takes care of appending the store path
    # in the context automatically.
    else "${target}";

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
          $storePaths | bzip2 -z > $out
      '';
    };

  # TODO: eventually should this go in nixpkgs?
  nix-user-chroot = lib.makeOverridable stdenv.mkDerivation {
    name = "nix-user-chroot-2c52b5f";
    src = ./nix-user-chroot;

    makeFlags = [];

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

    meta.platforms = lib.platforms.linux;
  };

  makebootstrap = { targets, startup }:
    arx {
      inherit startup;
      archive = maketar {
        inherit targets;
      };
    };

  makeStartup = { target, nixUserChrootFlags, nix-user-chroot', run, initScript }:
  let
    # Avoid re-adding a store path into the store
    path = toStorePath target;
  in
  writeScript "startup" ''
    #!/bin/sh
    ${initScript}
    .${nix-user-chroot'}/bin/nix-user-chroot -n ./nix ${nixUserChrootFlags} -- ${path}${run} "$@"
  '';

  nix-bootstrap = { target, extraTargets ? [], run, nix-user-chroot' ? nix-user-chroot, nixUserChrootFlags ? "", initScript ? "" }:
    let
      script = makeStartup { inherit target nixUserChrootFlags nix-user-chroot' run initScript; };
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
    nix-user-chroot'' = targets: nix-user-chroot.overrideDerivation (o: {
      buildInputs = o.buildInputs ++ targets;
      makeFlags = o.makeFlags ++ [
        ''ENV_PATH="${lib.makeBinPath targets}"''
      ];
    }); in { target, extraTargets ? [], run, initScript ? "" }: nix-bootstrap {
      inherit target extraTargets run initScript;
      nix-user-chroot' = nix-user-chroot'' extraTargets;
    };
}
