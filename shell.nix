let
	nixpkgs = fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/78e34d1667d32d8a0ffc3eba4591ff256e80576e.tar.gz";
	};
	pkgs = import nixpkgs {};
in
	pkgs.stdenv.mkDerivation {
		name = "specialeMikkel";
		buildInputs =
			with pkgs;
			[ cacert
			  curl
			  futhark
			  gcc9
			  ghostscript
			  git
			  gnumake42
			  lima
			  mlkit
			  mlton
			  nettools
			  smlpkg
			  tshark
			  tunctl
			  unzip
			  xen
			];
		shellHook = ''
		  	export NIX_ENFORCE_PURITY=0

			export CC=${pkgs.gcc9}/bin/gcc
			export CXX=${pkgs.gcc9}/bin/g++
			export PATH=${pkgs.gcc9}/bin:$PATH

			fish
		'';
	}
