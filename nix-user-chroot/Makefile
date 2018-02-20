NIX_PATH ?= "nixpkgs=https://github.com/NixOS/nixpkgs/archive/master.tar.gz"
NIX_SSL_CERT_FILE ?= "/homeless-shelter"
ENV_PATH ?= ""

nix-user-chroot: main.cpp
	g++ -o nix-user-chroot -DNIX_PATH='$(NIX_PATH)' -DNIX_SSL_CERT_FILE='$(NIX_SSL_CERT_FILE)' -DENV_HOME='$(ENV_HOME)' -DENV_PATH='$(ENV_PATH)' main.cpp
