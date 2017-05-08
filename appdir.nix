{ stdenv, fetchurl, perl, pathsFromGraph, fetchFromGitHub, musl }:

let
  AppRun = stdenv.mkDerivation {
    name = "AppRun";

    phases = [ "buildPhase" "installPhase" "fixupPhase" ];

    buildPhase = ''
      CC="${musl}/bin/musl-gcc -O2 -Wall -Wno-deprecated-declarations -Wno-unused-result -static"
      $CC ${./AppRun.c} -o AppRun
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp AppRun $out/bin/AppRun
    '';
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
          ln -s ../appdata/$(basename $f) usr/share/metainfo/$(basename $f)
        done
      fi

      # .desktop
      desktop=$(find ${target}/share/applications -name "*.desktop" | head -n1)
      if ! [ -z "$desktop" ]; then
        cp .$desktop .
      fi


      # icons
      if [ -d ${target}/share/icons ]; then
        icon=$(find ${target}/share/icons -name "${name}.png" | head -n1)
        if ! [ -z "$icon" ]; then
          ln -s .$icon
          ln -s .$icon .DirIcon
        else
          icon=$(find ${target}/share/icons -name "${name}.svg" | head -n1)
          if ! [ -z "$icon" ]; then
            ln -s .$icon
            ln -s .$icon .DirIcon
          fi
        fi
      fi

      cp ${AppRun}/bin/AppRun AppRun
    '';
  }
