#!/bin/sh
# prints the compositor's config for the keys view: the file's path on the first
# line, then it and the files it pulls in (niri's include, Hyprland's require or source =)
conf=${XDG_CONFIG_HOME:-$HOME/.config}
home() { case $1 in "~"/*) echo "$HOME/${1#"~/"}" ;; /*) echo "$1" ;; *) echo "$2/$1" ;; esac; }
case $1 in
aro)
	f=$conf/aro/config; echo "$f"; cat "$f" ;;
niri)
	f=$conf/niri/config.kdl; echo "$f"; cat "$f"
	sed -n 's/^[[:space:]]*include[[:space:]]*"\(.*\)".*/\1/p' "$f" | while read -r g; do cat "$(home "$g" "$conf/niri")"; done ;;
hyprland)
	d=$conf/hypr
	if [ -f "$d/hyprland.lua" ]; then
		f=$d/hyprland.lua; echo "$f"; cat "$f"
		# require("colors") / require "colors.dark" → colors.lua / colors/dark.lua
		sed -n "s/.*require[[:space:]]*(\{0,1\}[[:space:]]*[\"']\([^\"']*\)[\"'].*/\1/p" "$f" | while read -r g; do
			cat "$d/$(echo "$g" | tr . /).lua"; done
	else
		f=$d/hyprland.conf; echo "$f"; cat "$f"
		sed -n 's/^[[:space:]]*source[[:space:]]*=[[:space:]]*//p' "$f" | while read -r g; do cat "$(home "$g" "$d")"; done
	fi ;;
esac 2>/dev/null
