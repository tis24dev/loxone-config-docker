#!/bin/sh
# First-run installer: downloads the latest Loxone Config release and installs
# it unattended into $WINEPREFIX (/config/wine).

FEED_URL="https://update.loxone.com/updatecheck.xml"
SETUP="/config/LoxoneConfigSetup.exe"

fail() {
  echo
  echo "ERROR: $*"
  echo
  echo "You can also download LoxoneConfigSetup.exe yourself, put it into"
  echo "the ./config/ folder and restart the container."
  exit 1
}

echo "Installing Loxone Config into /config/wine (first start only)."
echo

if [ ! -f "$SETUP" ]; then
  cd /config || fail "/config is not accessible"

  echo "Looking up the latest Loxone Config release in $FEED_URL .."
  # Feed line looks like:
  # <Release Version="17.3.11.12" Path="http://.../LoxoneConfigSetup_17031112.zip" crc32="cb99aed6" Filesize="670495691" ...
  RELEASE=$(wget -qO - "$FEED_URL" | tr '<' '\n' | grep -E '^Release .*LoxoneConfigSetup_[0-9]+\.zip' | head -1)
  [ -n "$RELEASE" ] || fail "could not read the Loxone update feed."

  attr() { echo "$RELEASE" | sed -n "s/.* $1=\"\([^\"]*\)\".*/\1/p"; }
  VERSION=$(attr Version)
  URL=$(attr Path | sed 's#^http://#https://#')
  CRC=$(attr crc32)
  SIZE=$(attr Filesize)

  echo "Latest release: $VERSION"
  echo "Downloading $URL ($((SIZE / 1048576)) MB) .."
  wget -q --show-progress -O i.zip "$URL" || { rm -f i.zip; fail "download failed."; }

  if [ -n "$CRC" ]; then
    GOT=$(LC_ALL=C crc32 i.zip 2>/dev/null)
    if [ "$GOT" != "$CRC" ]; then
      rm -f i.zip
      fail "checksum mismatch (expected crc32 $CRC, got $GOT)."
    fi
    echo "Checksum OK ($CRC)."
  fi

  unzip -o -q i.zip LoxoneConfigSetup.exe || { rm -f i.zip; fail "LoxoneConfigSetup.exe not found in the zip."; }
  rm -f i.zip
fi

echo "Creating the 64-bit Wine prefix .."
wineboot --init
wineserver -w

echo "Running the Loxone Config installer unattended (this takes a few minutes) .."
# InnoSetup re-launches itself as a child process and the outer process exits
# right away, so wait for wineserver to know when the install has finished.
wine "$SETUP" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL /SP-
wineserver -w

echo "Install finished."
exit 0
