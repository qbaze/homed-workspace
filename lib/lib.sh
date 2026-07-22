#!/usr/bin/env bash
# homed-workspace shared library — sourced by `runas` and `homed-workspace-notify`.
# Provides: is_client, current_ws, watch_ws. Backend-switched per window manager so
# adding a new WM means adding one branch here, not editing every tool.
[[ -n ${_HOMED_WORKSPACE_LIB:-} ]] && return 0
_HOMED_WORKSPACE_LIB=1

# --- is $1 a real client login? --------------------------------------------
# A homed user is the ground truth. Do NOT rely on the login shell: when the
# encrypted home is inactive, homed substitutes 'systemd-home-fallback-shell',
# so a bash/zsh/fish check would reject exactly the users we need to activate.
# Prefer asking homed directly; fall back to a uid-range + shell heuristic only
# if homectl is unavailable.
is_client() {
  local u=$1
  if command -v homectl >/dev/null 2>&1; then
    homectl list --no-legend 2>/dev/null | awk '{print $1}' | grep -qxF "$u" && return 0
    return 1
  fi
  # fallback (no homed tooling): uid in the homed range with a login-ish shell,
  # accepting the fallback shell too.
  local line uid shell
  line=$(getent passwd "$u") || return 1
  uid=$(cut -d: -f3 <<<"$line"); shell=$(cut -d: -f7 <<<"$line")
  [[ $uid -ge 1000 && $uid -lt 65536 && $shell =~ (bash|zsh|fish|systemd-home-fallback-shell)$ ]]
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
    wmctrl -d | awk -v i="$idx" '$1==i{name=$10;for(k=11;k<=NF;k++)name=name" "$k;print name}'
  else
    wmctrl -d | awk '$2=="*"{name=$10;for(k=11;k<=NF;k++)name=name" "$k;print name}'
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
