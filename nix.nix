with import ./top.nix;
with import ./default.nix {};

nix-bootstrap-path {
  run = "/bin/nix";
  target = buildEnv {
    name = "nix-bundle";
    paths = [
    coreutils bzip2 xz gnutar coreutils bash
    (nix.overrideAttrs (o: {
      buildInputs = [ curl openssl sqlite libseccomp ];
      doCheck = false;
      preConfigure = (o.preConfigure or "") + ''
        NIX_CFLAGS_COMPILE+=" -g0"
        configureFlagsArray+=(--with-sandbox-shell=${bash}/bin/bash)
      '';
      propagatedBuildInputs = [gnutar bzip2 xz gzip coreutils bash boehmgc];
    }))
    ];
  };
}
