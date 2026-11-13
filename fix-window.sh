#!/bin/sh
# Loxone Config 17 draws its own (Qt) title bar with the save button and
# project tabs. When Openbox maximizes the window, that bar ends up above the
# screen edge and is never shown (lian/docker-loxone-config#7).
#
# Keep the window un-maximized and 1px smaller than the screen on every side.
# Do NOT size it to the full screen or make it fullscreen: Wine then switches to
# _NET_WM_STATE_FULLSCREEN and Loxone Config hangs.
#
# Runs every 2s so it follows noVNC remote resizing.

while true; do
  sleep 2
  W=$(xdotool search --onlyvisible --name '^Loxone Config$' 2>/dev/null | head -1)
  [ -n "$W" ] || continue

  GEOM=$(xdotool getdisplaygeometry) || continue
  SW=${GEOM% *}
  SH=${GEOM#* }

  eval "$(xdotool getwindowgeometry --shell "$W" 2>/dev/null)" || continue
  if [ "$X" = 1 ] && [ "$Y" = 1 ] && [ "$WIDTH" = $((SW - 2)) ] && [ "$HEIGHT" = $((SH - 2)) ]; then
    continue
  fi

  wmctrl -ir "$W" -b remove,maximized_vert,maximized_horz 2>/dev/null
  xdotool windowsize "$W" $((SW - 2)) $((SH - 2))
  xdotool windowmove "$W" 1 1
done
