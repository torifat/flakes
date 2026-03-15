{
  lib,
  stdenv,
  cpio,
  xar,
  undmg,
  mySource,
  ...
}:

stdenv.mkDerivation {
  inherit (mySource) pname version src;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    cpio
    xar
    undmg
  ];

  unpackPhase = ''
    undmg $src
    xar -xf SF\ Symbols.pkg
    cd SFSymbols.pkg
    zcat Payload | cpio -id
  '';

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Applications
    cp -R Applications/* $out/Applications/

    if [ -d "Resources" ]; then
      mkdir -p $out/Resources
      cp -R Resources/* $out/Resources/
    fi

    if [ -d "Library" ]; then
      mkdir -p $out/Library
      cp -R Library/* $out/Library/
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tool that provides consistent, highly configurable symbols for apps";
    homepage = "https://developer.apple.com/design/human-interface-guidelines/sf-symbols";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = platforms.darwin;
    license = licenses.mit;
  };
}
