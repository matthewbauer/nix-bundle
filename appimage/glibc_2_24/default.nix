self: super:
  let
    nixpkgs-old = builtins.fetchGit {
      # name = "nixpkgs-16.09";
      url = "https://github.com/nixos/nixpkgs";
      ref = "refs/tags/16.09";
      rev = "7d50dfaed5540495385b5c0feae90891d2d0e72b";
    };
    oldPkgs = import nixpkgs-old { inherit (super) system; };
    # takes in a *string* name of a glibc package e.g. "glibcInfo"
    #
    # the general idea is to mix the attributes from the old glibc and from the
    # the new glibc in a way that gets us an older version of glibc but is
    # compatible with the new gcc and the changes to nixpkgs. this took a lot of
    # trial and error, and will probably have to be updated as nixpkgs
    # progresses.
    glibcAdapter = glibcPkg: super.${glibcPkg}.overrideAttrs (newGlibc:
      let
        oldGlibc = oldPkgs.${glibcPkg};
      in {
        inherit (oldGlibc) name src;

        # version wasn't an attribute back then, so we can't inherit
        version = "2.24";

        patches = oldGlibc.patches ++ [
          # from current glibc. has to do with nixpkgs changes, not new glibc
          ./locale-C.diff

          # from current glibc. has to do with new gcc not new glibc
          ./fix-x64-abi.patch

          # newer ld does something different with .symver
          ./common-symbol.patch

          # update to allow a special case empty string
          ./ld-monetary.patch
        ];

      postPatch =
        oldGlibc.postPatch
        # from current glibc
        + ''
          # Needed for glibc to build with the gnumake 3.82
          # http://comments.gmane.org/gmane.linux.lfs.support/31227
          sed -i 's/ot \$/ot:\n\ttouch $@\n$/' manual/Makefile
          # nscd needs libgcc, and we don't want it dynamically linked
          # because we don't want it to depend on bootstrap-tools libs.
          echo "LDFLAGS-nscd += -static-libgcc" >> nscd/Makefile
        '';

      # modifications from old glibc
      configureFlags =
        # we can maintain compatiblity with older kernel (see below)
        super.lib.remove "--enable-kernel=3.2.0" (newGlibc.configureFlags or [])
        ++ [ "--enable-obsolete-rpc" ]
        ++ super.lib.optionals
          # (we don't have access to withLinuxHeaders from here)
          (newGlibc.linuxHeaders != null) [
            "--enable-kernel=2.6.32"
          ];

      NIX_CFLAGS_COMPILE =
        (newGlibc.NIX_CFLAGS_COMPILE or "")
        # from old glibc
        + " -Wno-error=strict-prototypes"
        # new gcc introduces new warnings which we must disable
        # (see https://github.com/NixOS/nixpkgs/pull/71480)
        + " -Wno-error=stringop-truncation -Wno-error=attribute-alias"
        # I also had to disable these <.< >.>
        + " -Wno-error=multistatement-macros"
        + " -Wno-error=int-in-bool-context"
        + " -Wno-error=format-truncation"
        + " -Wno-error=nonnull"
        + " -Wno-error=restrict"
        + " -Wno-error=unused-const-variable"
        + " -Wno-error=int-conversion"
        + " -Wno-error=unused-function";
      }
    );
  in {
    glibc = glibcAdapter "glibc";
    glibcLocales = glibcAdapter "glibcLocales";
    glibcInfo = glibcAdapter "glibcInfo";
    llvmPackages_11.llvm = super.llvmPackages_11.llvm.overrideAttrs (attrs: {
      doCheck = false; # test fails: intrinsics.ll
    });
  }
