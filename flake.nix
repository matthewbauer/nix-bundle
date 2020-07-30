{
  description = "The purely functional package manager";

  inputs.nixpkgs.url = "nixpkgs/nixos-20.03-small";

  outputs = { self, nixpkgs }: let
    systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
  in {
    exporters = forAllSystems (system: let
      nixpkgs' = nixpkgs.legacyPackages.${system};
      nix-bundle = import self { nixpkgs = nixpkgs'; };
    in {
      nix-bundle = { program }: let
        script = nixpkgs'.writeScript "startup" ''
        #!/bin/sh
        .${nix-bundle.nix-user-chroot}/bin/nix-user-chroot -n ./nix -- ${program} $@
        '';
      in nix-bundle.makebootstrap {
        targets = [ script ];
        startup = ".${builtins.unsafeDiscardStringContext script} '\"$@\"'";
      };
    });

    defaultExporter = forAllSystems (system: self.exporters.${system}.nix-bundle);
  };
}
