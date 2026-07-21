{ lib, stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "catnap";
  version = "2.1.1";

  src = fetchurl {
    url = "https://github.com/iinsertNameHere/catnap/releases/download/v2.1.1/catnap-v2.1.1-x86_64";
    hash = "sha256-5Fq3nek9DBdk7sj7RW67nWdcDGXUE/WDBqxbja0S1wM=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/catnap
    chmod +x $out/bin/catnap
  '';

  meta = with lib; {
    description = "A small systemfetch written in nim";
    homepage = "https://github.com/iinsertNameHere/catnap";
    license = licenses.mit;
    mainProgram = "catnap";
  };
}
