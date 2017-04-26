PREFIX ?= /usr

install: nix-bundle.sh default.nix
	mkdir -p ${PREFIX}/share/nix-bundle/
	install $^ ${PREFIX}/share/nix-bundle/
