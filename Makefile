PREFIX ?= /usr

install: nix-bundle.sh nix-run.sh appdir.nix appimagetool.nix appimage.nix AppRun.c appimage-top.nix default.nix appdir.sh nix2appimage.sh nix-user-chroot/ top.nix
	mkdir -p ${PREFIX}/share/nix-bundle/
	cp -r $^ ${PREFIX}/share/nix-bundle/
