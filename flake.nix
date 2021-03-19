{
  description = "The purely functional package manager";

  inputs.nixpkgs.url = "nixpkgs/nixos-20.03-small";

  # appimagekit got updated recently
  # but we only want to pull what we need to reduce rebuilds
  inputs.nixpkgs-appimagekit.url = "nixpkgs/master";

  outputs = { self, nixpkgs, nixpkgs-appimagekit }: let
    systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    bundlers = {
      nix-bundle = { program, system }: let
        nixpkgs' = nixpkgs.legacyPackages.${system};
        nix-bundle = import self { nixpkgs = nixpkgs'; };
        script = nixpkgs'.writeScript "startup" ''
          #!/bin/sh
          .${nix-bundle.nix-user-chroot}/bin/nix-user-chroot -n ./nix -- ${program} "$@"
        '';
      in nix-bundle.makebootstrap {
        targets = [ script ];
        startup = ".${builtins.unsafeDiscardStringContext script} '\"$@\"'";
      };

      appimage = { system, ... }@args:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [(self: super: {
              inherit (nixpkgs-appimagekit.legacyPackages.${system}) appimagekit squashfsTools squashfuse;
            })];
          };
          nix-appimage = (pkgs.callPackage ./appimage { });
        in
          nix-appimage.appimage (builtins.removeAttrs args [ "system" ]);
    };
    overlays = {
      glibc_2_24 = import ./appimage/glibc_2_24;
    };

    defaultBundler = self.bundlers.nix-bundle;
  };
}
