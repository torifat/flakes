# macOS `.app` bundle example

Referenced from [`../SKILL.md`](../SKILL.md) → "Package types" table. Use for a prebuilt darwin GUI app (Swift/Electron/etc.) that ships an `.app` bundle inside a `.dmg` or `.zip`.

The package is a tiny `stdenv.mkDerivation` that just unpacks and copies the bundle into `$out/Applications` — see `packages/miaoyan`:

```nix
{ lib, stdenv, unzip, mySource }:
stdenv.mkDerivation {
  inherit (mySource) pname version src;
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [ unzip ];   # or `undmg` for a .dmg source
  sourceRoot = ".";
  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R *.app $out/Applications/
    runHook postInstall
  '';
  meta = with lib; {
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    # ... license, homepage, description, maintainers = [ torifat ]
  };
}
```

Lessons baked in above:
- **Prefer the `.zip` asset over the `.dmg`.** Many releases' `.dmg` files use a non-HFS format `undmg` can't read — the build fails at unpack. If the release also ships a `.zip` (it usually does), point `fetch.url` at it and use `unzip`. Only reach for `undmg` when there's no zip (as `awakened-poe-trade` does).
- **GUI apps: omit `meta.mainProgram`** (there's no `$out/bin` entrypoint) and add `sourceProvenance = [ binaryNativeCode ]`.
- **Verify the bundle, not a binary.** Confirm `result/Applications/<App>.app/Contents/MacOS/<App>` exists; check `Contents/Info.plist` `CFBundleShortVersionString` (via `/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString"`) and `file`/`lipo` the binary to confirm which arches (universal `x86_64 + arm64` justifies both darwin platforms).
- Tags like `V4.0.0` → `src.prefix = "V"` to clean the version, and re-add the prefix in the asset path: `fetch.url = ".../download/V$ver/<App>_V$ver.zip"`.
