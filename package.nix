{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
}:
let
  inherit (lib.importJSON ./version.json) version asset hash;
in
stdenvNoCC.mkDerivation {
  pname = "hex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/hex/releases/download/v${version}/${asset}";
    inherit hash;
  };

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  sourceRoot = ".";

  # Hex.app must stay byte-identical: its Developer ID signature is what keeps
  # Microphone and Accessibility grants across updates.
  dontFixup = true;

  installPhase = /* bash */ ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Hex.app "$out/Applications/"

    makeWrapper "$out/Applications/Hex.app/Contents/MacOS/hex" "$out/bin/hex"

    runHook postInstall
  '';

  meta = {
    description = "Local-first voice dictation";
    homepage = "https://github.com/anomalyco/hex";
    changelog = "https://github.com/anomalyco/hex/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "hex";
  };
}
