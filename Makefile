PREFIX ?= /usr

install: nix-bundle.sh appdir.nix appimagetool.nix appimage.nix AppRun.c appimage-top.nix default.nix appdir.sh nix2appimage.sh
	mkdir -p ${PREFIX}/share/nix-bundle/
	install $^ ${PREFIX}/share/nix-bundle/
