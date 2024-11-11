{ lib, stdenv, buildGoModule, fetchFromGitHub, libobjc, IOKit }:

let

in buildGoModule rec {
  pname = "bor";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "maticnetwork";
    repo = "bor";
    rev = "v${version}";
    sha256 = "0kb15711szsk1mq651j4gra8xvqsm3g0bpggzc95mnazkw9m0749"; # retrieved using nix-prefetch-url
  };

  proxyVendor = true;
  vendorHash = "sha256-yp/sGhbqMYFtShH32YMViOZCoBP1O0ck/jqwwg3fcfY=";

  doCheck = false;

  outputs = [ "out" ];

  # Build using the new command
  buildPhase = ''
    mkdir -p $GOPATH/bin
    go build -o $GOPATH/bin/bor ./cmd/cli
  '';

  # Copy the built binary to the output directory
  installPhase = ''
    mkdir -p $out/bin
    cp $GOPATH/bin/bor $out/bin/bor
  '';

  # Fix for usb-related segmentation faults on darwin
  propagatedBuildInputs =
    lib.optionals stdenv.isDarwin [ libobjc IOKit ];

  meta = with lib; {
    mainProgram = "bor";
    description = "Bor is an Ethereum-compatible sidechain for the Polygon network";
    homepage = "https://github.com/maticnetwork/bor";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ "brunonascdev" ];
  };
}