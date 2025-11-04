let
	nixpkgs = fetchTarball {
		url = "https://github.com/NixOS/nixpkgs/archive/78e34d1667d32d8a0ffc3eba4591ff256e80576e.tar.gz";
	};
	pkgs = import nixpkgs {};

    # Build MLKit package using the fetched source
	mlkitPinned = pkgs.stdenv.mkDerivation rec {
	  name = "mlkit-pinned";
	  version = "git-4858b8b";

	# Fetch MLKit from GitHub at specific commit
	  src = pkgs.fetchFromGitHub {
		owner = "melsman";
		repo = "mlkit";
		rev = "4858b8b68ac1a97377f419889410f91ea738d5be";
		sha256 = "1d2s0cxrbivqfv7av73cypq7m26sh20v63qxdikq61yyzq0qbb3a";
	  };
	  
	  nativeBuildInputs = [
		pkgs.mlton
		pkgs.autoreconfHook
	  ];

	  buildFlags = [
		"mlkit"
		"mlkit_libs"
	  ];

	  doCheck = true;

	  # MLKit intentionally has some of these in its test suite.
	  # Since the test suite is available in `$out/share/mlkit/test`, we must disable this check.
	  dontCheckForBrokenSymlinks = true;

	  # checkPhase = ''
	  # 	runHook preCheck
	  # 	echo ==== Running MLKit test suite: test ====
	  # 	make -C test_dev test
	  # 	echo ==== Running MLKit test suite: test_prof ====
	  # 	make -C test_dev test_prof
	  # 	runHook postCheck
	  # '';
	};
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
			  mlkitPinned
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
