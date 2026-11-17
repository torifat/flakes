{
  stdenv,
  lib,
  makeWrapper,
  fetchzip,
  unzip,
  ffmpeg,
  mkvtoolnix,
  tesseract,
  handbrake,
  mySource,
}:
stdenv.mkDerivation (finalAttrs: {
  inherit (mySource) pname version src;

  buildInputs = [
  ];

  nativeBuildInputs = [
    unzip
    makeWrapper
  ];

  sourceRoot = ".";

  # unpackPhase = ''
  #   unzip $src
  # '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r ./ $out
    mkdir $out/bin
    makeWrapper $out/${finalAttrs.meta.mainProgram} $out/bin/${finalAttrs.meta.mainProgram} \
      --set ffmpegPath ${ffmpeg}/bin/ffmpeg \
      --set handbrakePath ${handbrake}/bin/HandBrakeCLI \
      --set mkvpropeditPath ${mkvtoolnix}/bin/mkvpropedit \
      --set ffprobePath ${ffmpeg}/bin/ffprobe \
      --run 'export rootDataPath="''${XDG_STATE_HOME:-$HOME/.local/state}/tdarr"'
  '';

  meta = with lib; {
    mainProgram = "Tdarr_Node";
    description = "Distributed transcode automation";
    homepage = "https://tdarr.io";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    # maintainers = with maintainers; [ ];
  };
})
