{ stdenv, fetchurl, perl, pathsFromGraph }:

let
  AppRun = fetchurl {
    url = "https://github.com/probonopd/AppImageKit/releases/download/6/AppRun_6-x86_64";
    sha256 = "1i0hr4ag6jz3h27c80ir2rswq91khw0cq9fqylg23l6pmjgwbf98";
  };

in

  { target, name }: stdenv.mkDerivation {
    name = "${name}.AppDir";
    exportReferencesGraph = map (x: [("closure-" + baseNameOf x) x]) [ target ];
    nativeBuildInputs = [ perl ];
    buildCommand = ''
      # TODO use symlinks to shrink output size

      if [ ! -d ${target}/share/applications ]; then
        echo "--------------------------------------------------"
        echo "| /share/applications does not exist.            |"
        echo "| AppImage only works with 'applications'.       |"
        echo "| Try using nix-bundle.sh for command-line apps. |"
        echo "--------------------------------------------------"
        exit 1
      fi

      storePaths=$(${perl}/bin/perl ${pathsFromGraph} ./closure-*)

      mkdir -p $out/${name}.AppDir
      cd $out/${name}.AppDir

      mkdir -p nix/store
      cp -r $storePaths nix/store

      ln -s .${target} usr

      if [ -d ${target}/share/appdata ]; then
        chmod a+w usr/share
        mkdir -p usr/share/metainfo
        for f in ${target}/share/appdata/*.xml; do
          ln -s .$f usr/share/metainfo
        done
      fi

      # .desktop
      desktop=$(find ${target}/share/applications -name "*.desktop" | head -n1)
      if ! [ -z "$desktop" ]; then
        ln -s .$desktop
      fi

      # icons
      if [ -d ${target}/share/icons ]; then
        icon=$(find ${target}/share/icons -name "${name}.png" -or -name "*.png" | head -n1)
        if ! [ -z "$icon" ]; then
          ln -s .$icon
          ln -s .$icon .DirIcon
        else
          icon=$(find ${target}/share/icons -name "${name}.svg" -or -name "*.svg" | head -n1)
          if ! [ -z "$icon" ]; then
            ln -s .$icon
            ln -s .$icon .DirIcon
          fi
        fi
      fi

      cp ${AppRun} AppRun
      chmod a+x AppRun
    '';
  }
