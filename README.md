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
- **Live wallpapers that colour the shell.** A video's palette comes from
  frames across its whole loop, and the island and widgets drift with its
  scenes as it plays (worked out once, in the background, then cached).
  Videos can keep playing under windows, or pause to save battery.
- **Colours from the wallpaper.** Material 3 roles from matugen, faded across
  the shell and pushed into aro's borders, foot (and open terminals), GTK,
  fuzzel, swaylock, btop, cava, starship and fastfetch.
- **Wallpaper transitions.** Ripple, fade, wipe, disc, stripes, zoom,
  honeycomb and pixelate (or a random one each time), with adjustable length
  and edge softness. aropaper doesn't run under yoru: the shell draws it all.
- **The desktop.** A clock in ten styles (thin, bold, stacked, outline, mono,
  split, words, kanji, serif, analog), widgets (today, weather, calendar,
  system, now playing), each with its own layouts (weather: card, hero, pill,
  a 24-hour graph, split; calendar: month, week, a tear-off date, dots;
  system: rings, bars, chips, a history graph; now playing: card, cover,
  pill, a turning record; today: bars, rings, the sun's arc), in a column, a
  grid, a row under the island, or placed by hand. They sit on ten looks
  (glass, frosted, solid, tonal, gradient, stack, outline, neon, HUD,
  minimal), and a visualizer rises while music plays (bars, mirror, wave or dots).
- **Edit mode (mod+e).** The desktop's widgets, live, over everything: drag
  them where you like (they snap to a grid, the screen's middle and edges,
  and each other), pull a corner to resize, give each its own layout, look
  and size, pick several (Ctrl+click, a lasso, Ctrl+A) to move them together,
  drag them onto another monitor, undo anything. Add more from a palette of
  live previews, as many as you like, including eleven that only live here:
  a clock in any style or a Material cookie, world clocks, synced lyrics
  (from lrclib.net, stretched to fit nightcore and slowed uploads), a photo
  or a folder slideshow cut to a shape, notes, a to-do list you tick off on
  the desktop, focus/stopwatch/countdown timers, a quote of the day, a user
  card, app shortcuts, and a countdown to a date.
- **A lock screen.** The wallpaper blurred, a big clock, your picture
  (`~/.face`), a password pill whose characters pop in as Material shapes
  (or dots) and that shakes at a wrong password, the music and power buttons. If the
  shell ever dies while locked, aro stays locked: from a TTY,
  `WAYLAND_DISPLAY=wayland-0 aro-lock` takes over and unlocks normally.
- **Live activities.** A focus timer (with a break, and notifications held
  while you work), screen recording, a colour picker and quiet hours, all
  shown in the island. While a track with cover art plays, the shell takes
  its colours from the cover.
- **Firefox.** Pill tabs, a rounded address bar and the page as a floating
  card, coloured live from the wallpaper through Pywalfox, and a yoru start
  page with its own settings: three layouts, your links, the greeting, the
  search engine, and new tabs that type straight into its search. kon's own Firefox CSS is kept as `chrome/kon.css` and comes back with
  `rice kon` (shapes change on Firefox's next start, colours at once).
- **Settings (mod+i).** A window in the style of end-4's, with search and live
  previews: Quick, Wallpaper, Clock, Widgets, Widget layouts, Visualizer,
  Start page, Island, Focus & quiet, Lock screen, Weather, About. It writes
  `~/.config/yoru/config.json`, which the shell follows live.

## Install

    ./install.sh        # links things into place; nothing visible changes
    rice yoru           # or mod+ctrl+r, in either rice

Needs: quickshell, aro, matugen, imagemagick, ffmpeg, cava, cliphist, grim,
slurp, jq, brightnessctl, wireplumber, qalculate, networkmanager, wlsunset,
swaylock, zenity (the photo widget's picker). The installer fetches the Geist,
Material Symbols, Noto Sans JP and Instrument Serif fonts and the Bibata cursor.

aro starts the shell with `yoru-shell`, which raises its open-file limit and,
on a machine with NVIDIA's driver installed but no NVIDIA card, keeps that
driver out.

Firefox's start page and its empty, ready-to-type new tabs need a small
loader installed once, as root (the start page's settings show this too):

    sudo install -m644 config/firefox/mozilla.cfg /usr/lib/firefox/

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
| `mod+v` | clipboard, with previews of images and whole texts |
| `mod+x` | control centre |
| `mod+m` | player |
| `mod+w` / `mod+shift+w` | wallpaper picker / next wallpaper |
| `mod+shift+e` | power |
| `mod+i` | settings |
| `mod+e` | edit the desktop's widgets |
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
