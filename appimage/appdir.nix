{ stdenv
, lib
, fetchurl
, closureInfo
, coreutils
, bash
, appimagekit
, perl
, runCommand
, glibc
, binutils
}:

{ target
, name ? target.pname
, extraTargets ? [ coreutils bash ]

# Specify which executable to run (relative to ${target} directory).
# Only needed if you have multiple binaries and no .desktop file.
, exec ? ""

# Packages and individual shared libraries to exclude from the output path. This
# can reduce appimage size, but you have to know they are either not needed at
# runtime or host will have a copy accessible. For some libraries you must
# depend on the host's copy for things to work.
, excludePkgs ? []
, excludeLibs ? import ./excludelist.nix
}:
let closure = closureInfo { rootPaths = [ target ] ++ extraTargets; };
in stdenv.mkDerivation {
  name = "${name}.AppDir";
  nativeBuildInputs = [ perl ];
  exclude_pkgs = with builtins; concatStringsSep " "
    (concatMap (pkg: map (out: lib.getOutput out pkg) pkg.outputs) excludePkgs);
  exclude_libs = with builtins; concatStringsSep " " excludeLibs;
  buildCommand = ''
    mkdir -p $out/${name}.AppDir
    cd $out/${name}.AppDir

    # copy the nix store closure into the AppDir
    mkdir -p nix/store
    cat ${closure}/store-paths | while read pkg; do
      # ...except the packages explicilty excluded
      # TODO: ideally, we would remove any dependencies that are only needed by
      #       the excluded packages, but I'm not sure how to actually do that.
      if ! [[ " $exclude_pkgs " =~ " $pkg " ]]; then
        cp -r $pkg nix/store
      fi
    done

    chmod -R +w nix/store

    # remove excluded libs so that our versions aren't found in the search path
    find nix/store | while read f; do
      real=$(realpath $f 2>/dev/null) \
        || continue # some symlinks are broken

      if [[ " $exclude_libs " =~ " ''${real##*/} " ]] || [[ " $exclude_libs " =~ " ''${f##*/} " ]]; then
        rm $f
      fi
    done

    # make symlinks relative
    find nix/store -type l | while read l; do
      # only change absolute links into the nix store
      if [[ $(readlink $l) =~ ^/nix/store ]]; then
        source=$(dirname "$(realpath -s "$l")")
        target="$(realpath "$l")"
        unlink $l
        ln -s "$(realpath --relative-to="$source" ".$target")" "$l" \
          || continue # some targets may have been excluded (or just broken)
      fi
    done

    ln -s .${target} usr

    # make rpaths relative
    function fix_rpaths_rec() {
      rpath=$(patchelf --print-rpath $1 2>/dev/null) && [ "$rpath" != "" ] \
        || return 0 # it's not an ELF file or the rpath is empty

      # current directory is ./usr which is a symlink to /nix/store/.../ so we need three .. to get back
      patchelf --set-rpath $(echo $rpath | perl -072 -pe 's/^(\/nix\/store.*)/..\/..\/..\1/') $1

      # recurse
      for l in $(echo $rpath | perl -072 -l40 -ne 's/^(\/nix\/store.*)/.\1\/*/ && print'); do
        fix_rpaths_rec $l
      done
    }

    echo "fixing linker and rpaths for executables and libraries (this may take a while)"
    for b in $(find usr/bin -executable -xtype f); do
      patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 $b 2>/dev/null \
        || continue # maybe it's not an elf executable
      fix_rpaths_rec $b
    done

    # make sure peripherals are set up

    # metainfo
    if [ -d ${target}/share/appdata ]; then
      mkdir -p usr/share/metainfo
      for f in ${target}/share/appdata/*.xml; do
        ln -s ../appdata/$(basename $f) usr/share/metainfo/$(basename $f)
      done
    fi

    # icon
    mkdir -p .${target}/share/icons/hicolor/256x256/apps
    icon=$(find .${target}/share/icons -name "${name}*.png" -o -name "${name}*.svg" | head -n1)
    if [ -z "$icon" ]; then
      icon=.${target}/share/icons/hicolor/256x256/apps/${name}.png
      touch $icon
    fi
    ln -s $(realpath -s --relative-to="." $icon) ./${name}.png
    ln -s $(realpath -s --relative-to="." $icon) .DirIcon

    # .desktop
    mkdir -p .${target}/share/applications
    desktop=$(find .${target}/share/applications -name "*.desktop" | head -n1)

    # user didn't supply a desktop file. we'll make one
    if [ -z "$desktop" ]; then
      desktop=.${target}/share/applications/${name}.desktop

      exec=${exec}
      # user didn't supply an executable. we'll look for one
      if [ -z "$exec" ]; then
        exec=$(find usr/bin -executable -xtype f)

        if [ -z "$exec" ]; then
          echo "Cannot build AppDir: no executable found in ${target}/bin/"
        fi

        if [ $(echo -n "$exec" | grep -c '^') -gt 1 ]; then
          echo "Cannot build AppDir: with more than one executable, you must specify 'exec'"
        fi
      fi
      exec=$(realpath --relative-to="usr" $exec)
      cat <<EOF > $desktop
[Desktop Entry]
Type=Application
Terminal=true
Version=1.0
Name=${name}
Icon=${name}
Exec=$exec
Categories=Utility;
EOF
    fi
    cp $desktop .

    cp ${appimagekit}/bin/AppRun AppRun
    chmod +w AppRun
    patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 AppRun
    # NOTE: haven't fixed the rpath of AppRun, since we don't know what
    #       directory it will be called from. I'm not sure if that'll be an
    #       issue. If it is, we can go back to compiling statically with musl
  '';
}
