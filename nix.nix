with import ./top.nix;
with import ./default.nix {};

nix-bootstrap-path {
  run = "/bin/nix";
  target = nix.overrideAttrs (o: {
    buildInputs = [ curl openssl sqlite libseccomp ];
    doCheck = false;
    preConfigure = (o.preConfigure or "") + ''
      NIX_CFLAGS_COMPILE+=" -g0"
      configureFlagsArray+=(--with-sandbox-shell=${bash}/bin/bash)
    '';
    propagatedBuildInputs = [gnutar bzip2 xz gzip coreutils bash boehmgc];
  });
}
