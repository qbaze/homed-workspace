#!/usr/bin/env bash
# homed-workspace shared library — sourced by `runas` and `homed-workspace-notify`.
# Provides: is_client, current_ws, watch_ws. Backend-switched per window manager so
# adding a new WM means adding one branch here, not editing every tool.
[[ -n ${_HOMED_WORKSPACE_LIB:-} ]] && return 0
_HOMED_WORKSPACE_LIB=1

# --- is $1 a real client login (homed user with a login shell)? --------------
is_client() {
  local line uid shell
  line=$(getent passwd "$1") || return 1
  uid=$(cut -d: -f3 <<<"$line"); shell=$(cut -d: -f7 <<<"$line")
  [[ $uid -ge 1000 && $uid -lt 65000 && $shell =~ (bash|zsh|fish)$ ]]
}

# --- detect the active WM backend --------------------------------------------
_ws_backend() {
  if [[ -n ${SWAYSOCK:-} ]] && command -v swaymsg >/dev/null 2>&1; then echo sway; return; fi
  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null 2>&1; then echo hyprland; return; fi
  if [[ -n ${DISPLAY:-} ]] && command -v wmctrl >/dev/null 2>&1; then echo x11; return; fi
  echo unknown
}

# --- NAME of the currently active workspace ----------------------------------
_ws_x11() {
  local idx
  # index: prefer xdotool (robust), else the row marked active with '*'
  if command -v xdotool >/dev/null 2>&1; then idx=$(xdotool get_desktop 2>/dev/null); fi
  if [[ -n ${idx:-} ]]; then
    wmctrl -d | awk -v i="$idx" '$1==i{s="";for(k=10;k<=NF;k++)s=s(k>10?" ":"")$k;print s}'
  else
    wmctrl -d | awk '$2=="*"{s="";for(k=10;k<=NF;k++)s=s(k>10?" ":"")$k;print s}'
  fi
}
_ws_sway()     { swaymsg -t get_workspaces 2>/dev/null | grep -o '"name":"[^"]*","focused":true' | head -1 | sed 's/.*"name":"\([^"]*\)".*/\1/'; }
_ws_hyprland() { hyprctl activeworkspace -j 2>/dev/null | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' | head -1; }

current_ws() {
  case "$(_ws_backend)" in
    x11)      _ws_x11 ;;
    sway)     _ws_sway ;;
    hyprland) _ws_hyprland ;;
    *)        return 1 ;;
  esac
}

# --- WATCH: emit one line on every workspace change (event-driven if possible) -
# Consumers do:  watch_ws | while read -r _; do name=$(current_ws); ...; done
_watch_poll() {
  local last="" cur
  while :; do
    cur=$(current_ws 2>/dev/null || true)
    if [[ $cur != "$last" ]]; then last=$cur; echo tick; fi
    sleep 0.3
  done
}
_watch_x11() {
  # native X11 event source: root property _NET_CURRENT_DESKTOP changes on every
  # switch (keybind, pager, click). No polling. Falls back if xprop is missing.
  if command -v xprop >/dev/null 2>&1; then
    xprop -spy -root _NET_CURRENT_DESKTOP 2>/dev/null
  else
    _watch_poll
  fi
}
_watch_sway()     { swaymsg -t subscribe -m '["workspace"]' 2>/dev/null; }
_watch_hyprland() { _watch_poll; }   # TODO: native via socket2 + socat

watch_ws() {
  case "$(_ws_backend)" in
    x11)      _watch_x11 ;;
    sway)     _watch_sway ;;
    hyprland) _watch_hyprland ;;
    *)        _watch_poll ;;
  esac
}
