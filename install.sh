#!/bin/sh
# yoru's installer. Links the shell and its scripts into place, fetches the fonts
# and the cursor, and hooks yoru into your compositor: aro, Hyprland or niri.
#
#   ./install.sh                 the compositor you're in (or every one installed)
#   ./install.sh hyprland niri   just those
#   ./install.sh --yes           add the one include line without asking
#
# Run it again any time: it only adds what's missing. Your own compositor
# config gets one line (backed up first); files yoru later writes over whole
# are kept as NAME.pre-yoru.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
bin=$HOME/.local/bin
fonts=$HOME/.local/share/fonts/yoru
icons=$HOME/.local/share/icons
stamp=$(date +%F)

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

yes=false
wms=""
for a in "$@"; do
	case $a in
	-y | --yes) yes=true ;;
	aro | hyprland | niri) wms="$wms $a" ;;
	-h | --help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	*) warn "unknown argument: $a"; exit 2 ;;
	esac
done
if [ -z "$wms" ]; then
	if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then wms=hyprland
	elif [ -n "${NIRI_SOCKET:-}" ]; then wms=niri
	elif [ -n "${ARO_SOCKET:-}" ]; then wms=aro
	else
		has aro && wms="$wms aro"
		has Hyprland && wms="$wms hyprland"
		has niri && wms="$wms niri"
	fi
fi
[ -n "$wms" ] || { warn "none of aro, Hyprland or niri is installed: yoru needs one of them"; exit 1; }

# what yoru needs
# the Arch package for a command, where its name differs
pkg() {
	case $1 in
	qs) echo quickshell ;; magick) echo imagemagick ;; wl-copy) echo wl-clipboard ;;
	wpctl) echo wireplumber ;; qalc) echo libqalculate ;; nmcli) echo networkmanager ;;
	inotifywait) echo inotify-tools ;; bsdtar) echo libarchive ;; notify-send) echo libnotify ;;
	fc-cache) echo fontconfig ;; python3) echo python ;; *) echo "$1" ;;
	esac
}
# what's only in the AUR: an AUR helper builds it, if there is one
aur() { case $1 in wl-screenrec) return 0 ;; *) return 1 ;; esac; }
needs="qs matugen magick jq curl python3 bsdtar fc-cache"
# and what only some features use: video wallpapers, the visualizer, clipboard history, copying,
# screenshots, recording, the colour picker, brightness, volume, media keys, sums in the launcher,
# Wi-Fi, night light, locking when idle, the fallback lock, the photo widget's picker,
# restarting after edits, fallback notices
wants="ffmpeg cava cliphist wl-copy grim slurp wl-screenrec hyprpicker brightnessctl wpctl playerctl qalc
	nmcli wlsunset swayidle swaylock zenity inotifywait notify-send"
repo="" fromaur=""
for c in $needs $wants; do
	has "$c" && continue
	if aur "$c"; then fromaur="$fromaur $(pkg "$c")"; else repo="$repo $(pkg "$c")"; fi
done
fc-list | grep -q "Noto Color Emoji" || repo="$repo noto-fonts-emoji"
opts=--needed; $yes && opts="$opts --noconfirm"
if has pacman; then
	if [ -n "$repo" ]; then
		say "running: sudo pacman -S $opts$repo"
		sudo pacman -S $opts $repo || warn "pacman didn't install everything"
	fi
	if [ -n "$fromaur" ]; then
		helper=""
		for h in paru yay; do has "$h" && { helper=$h; break; }; done
		if [ -n "$helper" ]; then
			say "running: $helper -S $opts$fromaur"
			$helper -S $opts $fromaur || warn "$helper didn't install$fromaur"
		else
			warn "from the AUR, if you'd like them:$fromaur"
		fi
	fi
elif [ -n "$repo$fromaur" ]; then
	warn "install these with your package manager (Arch's names):$repo$fromaur"
fi
missing=""
for c in $needs; do has "$c" || missing="$missing $c"; done
[ -z "$missing" ] || { warn "yoru can't run without:$missing"; exit 1; }

# the shell and the scripts
say "linking the shell and the scripts"
mkdir -p "$cfg/quickshell" "$bin" "$cfg/yoru"
ln -sfn "$here/config/quickshell/yoru" "$cfg/quickshell/yoru"
for f in yoru yoru-shell yoru-watch yoru-shot yoru-lock yoru-idle; do ln -sf "$here/bin/$f" "$bin/$f"; done
case :$PATH: in *":$bin:"*) ;; *) warn "$bin isn't on your PATH: the compositor's binds call yoru from there" ;; esac

# fonts and the cursor
if ! fc-list | grep -q "Material Symbols Rounded" || ! fc-list | grep -q "Geist:"; then
	say "fonts: Geist and Material Symbols Rounded"
	tmp=$(mktemp -d)
	mkdir -p "$fonts"
	curl -fsSL -o "$fonts/MaterialSymbolsRounded.ttf" \
		"https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
	curl -fsSL -o "$tmp/geist.zip" https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip
	bsdtar -xf "$tmp/geist.zip" -C "$tmp"
	cp "$tmp"/geist-font/Geist/ttf/*.ttf "$tmp"/geist-font/GeistMono/ttf/*.ttf "$fonts/"
	rm -rf "$tmp"
fi
# the kanji clock and the serif clock
gf=https://github.com/google/fonts/raw/main/ofl
mkdir -p "$fonts"
[ -f "$fonts/NotoSansJP.ttf" ] || curl -fsSL -o "$fonts/NotoSansJP.ttf" "$gf/notosansjp/NotoSansJP%5Bwght%5D.ttf"
[ -f "$fonts/InstrumentSerif-Regular.ttf" ] || {
	curl -fsSL -o "$fonts/InstrumentSerif-Regular.ttf" "$gf/instrumentserif/InstrumentSerif-Regular.ttf"
	curl -fsSL -o "$fonts/InstrumentSerif-Italic.ttf" "$gf/instrumentserif/InstrumentSerif-Italic.ttf"
}
fc-cache -f "$fonts" >/dev/null
if [ ! -d "$icons/Bibata-Modern-Ice" ]; then
	say "cursor: Bibata Modern Ice"
	mkdir -p "$icons"
	curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz | tar -xJ -C "$icons"
fi

# the compositors
# adds LINE to the end of FILE once, after a backup, asking first unless --yes
hook() {
	file=$1 line=$2
	grep -qxF "$line" "$file" 2>/dev/null && { say "$file already has: $line"; return; }
	if ! $yes; then
		if [ -t 0 ]; then
			printf '\033[1;34m::\033[0m add "%s" to the end of %s? [Y/n] ' "$line" "$file"
			read -r ok
			case $ok in [nN]*) say "skipped: add it yourself when you like"; return ;; esac
		else
			say "add this line to the end of $file:  $line"
			return
		fi
	fi
	[ -f "$file" ] && cp "$file" "$file.bak-$stamp-yoru"
	case $file in *.lua) mark=-- ;; *.kdl) mark=// ;; *) mark='#' ;; esac
	printf '\n%s yoru (%s)\n%s\n' "$mark" "$here" "$line" >> "$file"
	say "added to $file (the old one is $file.bak-$stamp-yoru)"
}

for wm in $wms; do
	case $wm in
	aro)
		say "aro"
		cp "$here/config/aro/config" "$cfg/yoru/aro.config"
		if [ -f "$cfg/aro/config" ] && ! grep -q "yoru-shell" "$cfg/aro/config"; then
			say "yoru's aro config is ~/.config/yoru/aro.config; to use it:"
			say "  cp ~/.config/aro/config ~/.config/aro/config.mine && cp ~/.config/yoru/aro.config ~/.config/aro/config"
		elif [ ! -f "$cfg/aro/config" ]; then
			mkdir -p "$cfg/aro"
			cp "$here/config/aro/config" "$cfg/aro/config"
			say "aro had no config: yoru's is now ~/.config/aro/config"
		fi ;;
	hyprland)
		say "Hyprland"
		mkdir -p "$cfg/hypr"
		ln -sf "$here/config/hypr/yoru.lua" "$cfg/hypr/yoru.lua"
		ln -sf "$here/config/hypr/yoru.conf" "$cfg/hypr/yoru.conf"
		# 0.56 reads hyprland.lua; older ones hyprland.conf
		if [ -f "$cfg/hypr/hyprland.lua" ] || { [ ! -f "$cfg/hypr/hyprland.conf" ] && [ -f /usr/share/hypr/hyprland.lua ]; }; then
			[ -f "$cfg/hypr/hyprland.lua" ] || cp /usr/share/hypr/hyprland.lua "$cfg/hypr/hyprland.lua"
			hook "$cfg/hypr/hyprland.lua" 'require("yoru")'
		else
			hook "$cfg/hypr/hyprland.conf" "source = ~/.config/hypr/yoru.conf"
			warn "Hyprland runs every bind on a key: unbind your own on yoru's keys (see yoru.conf)"
		fi ;;
	niri)
		say "niri"
		mkdir -p "$cfg/niri"
		ln -sf "$here/config/niri/yoru.kdl" "$cfg/niri/yoru.kdl"
		if [ ! -f "$cfg/niri/config.kdl" ]; then
			for d in /usr/share/doc/niri/default-config.kdl /usr/local/share/doc/niri/default-config.kdl; do
				[ -f "$d" ] && cp "$d" "$cfg/niri/config.kdl" && break
			done
		fi
		hook "$cfg/niri/config.kdl" 'include "yoru.kdl"'
		if has niri && ! niri validate -c "$cfg/niri/config.kdl" >/dev/null 2>&1; then
			warn "niri validate doesn't like $cfg/niri/config.kdl: check it"
		fi ;;
	esac
done

say "palette, app colours and wallpaper thumbnails"
"$bin/yoru" apply
"$bin/yoru" walls >/dev/null 2>&1 &

read -p "Installation finished! Do you want to install firefox's theme? (recommended) (y/n): " fox

if [[ -z "$fox" ]]; then
	warn "Empty field, ignoring..."
elif [[ "$fox" =~ ^[Yy]$ ]]; then
	say "Ok, running sudo install -m644 config/firefox/mozilla.cfg /usr/lib/firefox ..."
	sudo install -m644 config/firefox/mozilla.cfg /usr/lib/firefox
	EXIT_CODE="$?"
	if [[ EXIT_CODE -ne 0 ]]; then
		warn "Something went wrong, exit code: $EXIT_CODE"
	else
		say "Installed firefox theme successfully!"
	fi
else
	say "Ok, not installing it."
fi

case $wms in
*aro*) say "done" ;;
*) say "done: log in to your compositor again (or run yoru-shell) to start yoru" ;;
esac
