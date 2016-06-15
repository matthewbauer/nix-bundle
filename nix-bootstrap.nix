{ stdenv, writeText, nix-user-chroot, nix, cacert, coreutils, bash }:

{ name, stage3 }:

let
  stage1 = writeText "stage1.sh" ''
    ./${nix-user-chroot}/bin/nix-user-chroot ./nix ./${bash}/bin/sh -c $(dirname $0)/stage2.sh
  '';

  stage2 = writeText "stage2.sh" ''
    unset NIX_REMOTE NIX_PROFILES NIX_USER_PROFILE_DIR NIX_OTHER_STORES NIX_PATH
    export NIX_CONF_DIR=/nix/etc/nix/
    export NIX_PROFILE=/nix/var/nix/profiles/default
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    export PATH="${coreutils}/bin:${bash}/bin:${nix.out}/bin"

    chmod -R a-w /nix/
    chmod u+w /nix/ /nix/store/
    mkdir -p /nix/etc/nix/ /nix/var/nix/profiles $HOME /bin/
    ln -s ${bash}/bin/sh /bin/sh

    nix-store --init
    nix-store --load-db < ./.reginfo

    . ${nix.out}/etc/profile.d/nix.sh

    nix-channel --add https://nixos.org/channels/nixpkgs-unstable
    nix-channel --update nixpkgs

    nix-shell --pure -p ${nix.out} --run "${stage3}"
  '';

in

  stdenv.mkDerivation {
    inherit name;
    buildInputs = [ nix-user-chroot nix cacert ];
    buildCommand = ''
      mkdir -p $out
      install -m 755 ${stage1} $out/stage1.sh
      install -m 755 ${stage2} $out/stage2.sh
    '';
  }
