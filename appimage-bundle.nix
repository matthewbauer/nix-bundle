# use like this:
# nix-build appimage-bundle.nix --argstr package hello --argstr exec hello

{nixpkgs ? import <nixpkgs>{}, 
package,
exec,
... }:
let
  appimage_src = drv : exec : with nixpkgs;
    self.stdenv.mkDerivation rec {
      name = drv.name + "-appdir";
      env = buildEnv {
        inherit name;
        paths = buildInputs;
      };
      src = env;
      inherit exec;
      buildInputs = [ drv nixpkgs.coreutils nixpkgs.gnutar nixpkgs.xz ];
      usr_fonts = buildEnv {
        name = "fonts";
        paths = [noto-fonts];
      };
      buildCommand = ''
        source $stdenv/setup
        mkdir -p $out/bin
        cp -rL ${env}/* $out/
        chmod +w -R $out/

        mkdir -p $out/share/fonts
        cp ${usr_fonts}/share/fonts/* $out/share/fonts -R

        mkdir -p $out/share/icons
        mkdir -p $out/share/icons/hicolor/256x256/apps
        touch $out/share/icons/hicolor/256x256/apps/${drv.name}.png
        touch $out/share/icons/${drv.name}.png

        mkdir -p $out/share/applications
        cat <<EOF > $out/share/applications/${drv.name}.desktop
        [Desktop Entry]
        Type=Application
        Version=1.0
        Name=${drv.name}
        Path=${env}
        Icon=${drv.name}
        Exec=$exec
        Terminal=true
        EOF
        '';
        system = builtins.currentSystem;
  };

in
  with (import (./appimage-top.nix){nixpkgs' = nixpkgs.path;});
    (appimage (appdir {
      name = package;
      target = appimage_src nixpkgs."${package}" "${exec}";
    })).overrideAttrs (old: {name = package;})
