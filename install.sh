#!/bin/sh
# yoru: link the rice into place. Changes nothing you see until `rice yoru`.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
bin=$HOME/.local/bin
fonts=$HOME/.local/share/fonts/yoru
icons=$HOME/.local/share/icons

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

need=""
for c in qs aro aroctl matugen magick ffmpeg cava cliphist wl-copy grim slurp jq brightnessctl wpctl qalc nmcli wlsunset swaylock; do
	command -v "$c" >/dev/null || need="$need $c"
done
[ -z "$need" ] || say "missing (some features won't work):$need"

say "linking the shell and the scripts"
mkdir -p "$cfg/quickshell" "$bin" "$cfg/yoru"
ln -sfn "$here/config/quickshell/yoru" "$cfg/quickshell/yoru"
for f in yoru yoru-shell yoru-shot yoru-lock yoru-idle rice; do ln -sf "$here/bin/$f" "$bin/$f"; done
cp "$here/config/aro/config" "$cfg/yoru/aro.config"

if ! fc-list | grep -q "Material Symbols Rounded" || ! fc-list | grep -q "Geist:"; then
	say "fonts: Geist and Material Symbols Rounded"
	tmp=$(mktemp -d)
	mkdir -p "$fonts"
	curl -fsSL -o "$fonts/MaterialSymbolsRounded.ttf" \
		"https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
	curl -fsSL -o "$tmp/geist.zip" https://github.com/vercel/geist-font/releases/download/v1.7.2/geist-font-v1.7.2.zip
	bsdtar -xf "$tmp/geist.zip" -C "$tmp"
	cp "$tmp"/geist-font/Geist/ttf/*.ttf "$tmp"/geist-font/GeistMono/ttf/*.ttf "$fonts/"
	fc-cache -f "$fonts"
	rm -rf "$tmp"
fi

# the kanji clock and the serif clock
gf=https://github.com/google/fonts/raw/main/ofl
[ -f "$fonts/NotoSansJP.ttf" ] || { mkdir -p "$fonts"; curl -fsSL -o "$fonts/NotoSansJP.ttf" "$gf/notosansjp/NotoSansJP%5Bwght%5D.ttf"; }
[ -f "$fonts/InstrumentSerif-Regular.ttf" ] || {
	curl -fsSL -o "$fonts/InstrumentSerif-Regular.ttf" "$gf/instrumentserif/InstrumentSerif-Regular.ttf"
	curl -fsSL -o "$fonts/InstrumentSerif-Italic.ttf" "$gf/instrumentserif/InstrumentSerif-Italic.ttf"
	fc-cache -f "$fonts"
}

if [ ! -d "$icons/Bibata-Modern-Ice" ]; then
	say "cursor: Bibata Modern Ice"
	mkdir -p "$icons"
	curl -fsSL https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz | tar -xJ -C "$icons"
fi

# kon's aro config gets the key back to yoru
if [ -f "$cfg/aro/config" ] && ! grep -q "rice toggle" "$cfg/aro/config"; then
	cp "$cfg/aro/config" "$cfg/aro/config.bak-$(date +%F)-yoru"
	printf '\n# switch rices: kon <-> yoru (see ~/Projects/yoru)\nbind = mod+ctrl+r, spawn, rice toggle\n' >> "$cfg/aro/config"
	aroctl reload >/dev/null 2>&1 || true
fi

say "palette and wallpaper thumbnails"
"$bin/yoru" apply
"$bin/yoru" walls >/dev/null &

say "done: press mod+ctrl+r (or run \`rice yoru\`) to switch"
