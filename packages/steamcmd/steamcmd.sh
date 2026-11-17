#!@runtimeShell@ -e
# steamcmd self-updates in place, so it must run from a writable copy rather
# than the Nix store. Seed the Steam root from the store on first use.

STEAMROOT="${STEAMCMD_ROOT:-@steamRoot@}"

PATH=$PATH${PATH:+:}@coreutils@/bin

# The Valve tarball is x86_64-only; on Apple silicon it needs Rosetta 2.
if [ "$(uname -m)" = "arm64" ] && ! /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
  echo "steamcmd: Rosetta 2 is required. Install it with: softwareupdate --install-rosetta" >&2
  exit 1
fi

if [ ! -e "$STEAMROOT/steamcmd.sh" ]; then
  mkdir -p "$STEAMROOT"
  cp -R "@out@/share/steamcmd/." "$STEAMROOT/"
  chmod -R u+w "$STEAMROOT"
fi

exec "$STEAMROOT/steamcmd.sh" "$@"
