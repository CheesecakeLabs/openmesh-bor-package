{ lib, stdenv, buildGoModule, fetchFromGitHub, libobjc, IOKit }:

buildGoModule rec {
  pname = "polygon-bor";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "maticnetwork";
    repo = "bor";
    rev = "v${version}";
    sha256 = "sha256-Ndttrar4sYiTKicvEUR1fUVTwveXA/qeTppEHNynYKc="; # retrieved using nix-prefetch-url
  };

  proxyVendor = true;
  vendorHash = "sha256-az/hDuhRU8NJ6ph9+KamfVGiaxPitOATXnxDIzHca20=";

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