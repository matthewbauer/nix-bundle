with import ./top.nix;
with import ./default.nix {};

nix-bootstrap-path {
  run = "/bin/nix";
  target = (nix.overrideAttrs (o: {
        buildInputs = [ curl openssl sqlite libseccomp libsodium ];
        doCheck = false;
        doInstallCheck = false;
        preConfigure = (o.preConfigure or "") + ''
          NIX_CFLAGS_COMPILE+=" -g0"
          configureFlagsArray+=(--with-sandbox-shell=${bash}/bin/bash)
        '';
        propagatedBuildInputs = [gnutar bzip2 xz gzip coreutils bash boehmgc];
  }));
  extraTargets = [coreutils bzip2 xz gzip gnutar bash];
}
