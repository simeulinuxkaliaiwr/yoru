# yoru

夜, night. A rice for [aro](https://github.com/simeulinuxkaliaiwr/aro), built to sit
beside [kon](https://github.com/simeulinuxkaliaiwr/kon): one key swaps between them.

Dark, with colours taken from the wallpaper and motion everywhere.

- **The island.** One dark shape at the top of the screen is the whole shell. At
  rest it shows the workspaces, what's playing, the time and the status. It
  morphs into the launcher, clipboard, control centre, media player, calendar,
  wallpaper picker and power menu, and briefly into volume, brightness and
  notification popups.
- **A living wallpaper.** Drawn by the shell: it drifts with the workspaces
  (parallax), plays videos (paused while windows cover it), and a new one
  ripples out of the island through a GPU shader.
- **Colours from the wallpaper.** Material 3 roles from matugen, faded across
  the shell and pushed into aro's borders, foot (and open terminals), GTK,
  fuzzel, swaylock, btop, cava, starship and fastfetch.
- **Wallpaper transitions.** Ripple, fade, wipe, disc, stripes, zoom,
  honeycomb and pixelate (or a random one each time), with adjustable length
  and edge softness. aropaper doesn't run under yoru: the shell draws it all.
- **The desktop.** A clock in ten styles (thin, bold, stacked, outline, mono,
  split, words, kanji, serif, analog; bottom left, centre or top left),
  widgets (today, weather, calendar, system rings, now playing) in six looks
  (glass, solid, tonal, outline, neon, minimal), and a visualizer while music
  plays (bars, mirror, wave or dots).
- **A lock screen.** The wallpaper blurred, a big clock, an animated password
  pill that shakes at a wrong password, the music and power buttons. If the
  shell ever dies while locked, aro stays locked: from a TTY,
  `WAYLAND_DISPLAY=wayland-0 aro-lock` takes over and unlocks normally.
- **Live activities.** A focus timer (with a break, and notifications held
  while you work), screen recording, a colour picker and quiet hours, all
  shown in the island. While a track with cover art plays, the shell takes
  its colours from the cover.
- **Firefox.** Pill tabs, a rounded address bar and the page as a floating
  card, coloured live from the wallpaper through Pywalfox, and a yoru start
  page. kon's own Firefox CSS is kept as `chrome/kon.css` and comes back with
  `rice kon` (shapes change on Firefox's next start, colours at once).
- **Settings (mod+i).** A window in the style of end-4's: Quick, Wallpaper,
  Desktop, Island, Lock, Weather, About. It writes
  `~/.config/yoru/config.json`, which the shell follows live.

## Install

    ./install.sh        # links things into place; nothing visible changes
    rice yoru           # or mod+ctrl+r, in either rice

Needs: quickshell, aro, matugen, imagemagick, ffmpeg, cava, cliphist, grim,
slurp, jq, brightnessctl, wireplumber, qalculate, networkmanager, wlsunset,
swaylock. The installer fetches the Geist and Material Symbols fonts and the
Bibata cursor.

## Switching

`rice` keeps one aro config per rice. The live `~/.config/aro/config` belongs
to the rice that is on; the other waits as `config.kon` or `config.yoru`.
Edits to the live one follow it when you switch. The very first switch keeps
`config.bak-before-rice`.

    rice                which is on
    rice toggle         the other one   (mod+ctrl+r)

## Keys

| | |
|---|---|
| `mod+a` | launcher (apps, `=` maths) |
| `mod+v` | clipboard |
| `mod+x` | control centre |
| `mod+m` | player |
| `mod+w` / `mod+shift+w` | wallpaper picker / next wallpaper |
| `mod+shift+e` | power |
| `mod+i` | settings |
| `mod+Tab` | window picker (type to filter) |
| `mod+/` | every key, from your aro config |
| `mod+p` | focus timer |
| `mod+shift+c` | pick a colour |
| `mod+shift+Print`, `mod+ctrl+Print` | record the screen, an area |
| `mod+escape` | lock |
| `mod+o`, `mod+Tab` | aro's overview |
| `Print`, `mod+Print` | screenshot, area |
| `mod+ctrl+r` | back to kon |

The rest are kon's: `mod+hjkl`, workspaces, scratchpad, groups.

## Wallpapers

    yoru wall FILE      an image or a video
    yoru wall next
    yoru walls          what the picker lists (~/.config/yoru/yoru.json: "dirs")
