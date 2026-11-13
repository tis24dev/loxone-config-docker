#!/bin/sh

export WINEDEBUG=-all

# The 32-bit installer puts the app into "Program Files (x86)" of the win64
# prefix; check "Program Files" as well in case a future installer changes that.
find_loxone() {
  for exe in \
    "/config/wine/drive_c/Program Files (x86)/Loxone/LoxoneConfig/LoxoneConfig.exe" \
    "/config/wine/drive_c/Program Files/Loxone/LoxoneConfig/LoxoneConfig.exe"; do
    if [ -f "$exe" ]; then echo "$exe"; return 0; fi
  done
  return 1
}

# A prefix created by the old 32-bit image cannot run Loxone Config 17+.
if [ -f /config/wine/system.reg ] && ! grep -q '^#arch=win64' /config/wine/system.reg; then
  xterm -hold -e sh -c '
    echo
    echo "  /config/wine is an old 32-bit Wine prefix from a previous image."
    echo "  Loxone Config 17+ needs a 64-bit prefix."
    echo
    echo "  Stop the container, delete ./config/wine (your projects in"
    echo "  ./config/Loxone are kept) and start it again."
  '
  exit 1
fi

if ! find_loxone > /dev/null; then
  # xterm -e does not pass on the script exit code, so re-check afterwards.
  xterm -e /init-install.sh
fi

LOXONE_EXE="$(find_loxone)"
if [ -z "$LOXONE_EXE" ]; then
  xterm -hold -e sh -c '
    echo
    echo "  Loxone Config is NOT installed: the installer did not complete."
    echo
    echo "  Restart the container to try again, or put LoxoneConfigSetup.exe"
    echo "  into ./config/ and restart."
  '
  exit 1
fi

setxkbmap "$XLANG"

# Work around the cut-off title bar of Loxone Config 17 (see fix-window.sh).
/fix-window.sh &

exec wine "$LOXONE_EXE"
