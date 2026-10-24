# yoru

夜, night. A Quickshell rice for [aro](https://github.com/simeulinuxkaliaiwr/aro),
[hyprland](https://github.com/hyprwm/hyprland) and [niri](https://github.com/niri-wm/niri). [Demonstration video](https://youtu.be/SwnPey0mfXo?si=V4ve6P0GJIUeT3nZ)

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ef23e842-9f62-47fb-a9f1-c01a59d6b3b9" />

| | |
|---|---|
| ![The control center](docs/island.png) | ![Storm](docs/storm.png) |
| ![Snow](docs/snow.png) | ![Aurora](docs/aurora.png) |

### The island

One dark shape at the top of the screen is the whole shell. At rest it shows
the workspaces, what's playing, the time and the status. It morphs into the
launcher, clipboard, control center, media player, calendar, wallpaper picker,
anime pictures and power menu. It also shows notification pop-ups, brightness and volume, and sings along with
what's playing. A little cat lives at its left end: it sleeps, wakes for notifications, bobs to
the music, curls up while you focus, and purrs when you click it.

The control center has pages behind its tiles: the **sound** (where it plays, the mic, and each
app's own volume), **Wi-Fi** and **Bluetooth** lists, and the **night light** (how warm, and
whether it comes on by itself from sunset to sunrise). The launcher finds apps (Enter on one
that's open goes to it, → shows its own actions), sums, emoji, the web, things yoru does
("restart", "next wallpaper") and any setting by name. The clipboard pastes straight into your
window and keeps pins. **Control center demonstration:**

![control center](docs/control_center.png)

### The phone (mod+y)

A phone that drops out of the island, holding your apps, quick settings, the day and the music
on pages you swipe (or Tab) between:

- **Home**: a clock in any of the desktop's styles, the weather, your apps and a dock. Type
  anywhere and it searches them; what isn't an app (maths, the web, emoji) goes on to the
  island's launcher.
- **Control**: your battery, Wi-Fi and Bluetooth (with lists to join networks and pair
  devices), tiles for night light, caffeine, do not disturb, focus, recording and more, what's
  playing, brightness and volume, and how busy the computer is.
- **Today**: the weather by the hour, the month, the focus timer and your notifications.
- **Music**: the cover, the controls, and the words as they're sung.

Under Settings → Phone, pick its body: a glass **slab** whose side buttons work, a **flip**
phone that swings open on its hinge (its keypad's 1–9 are shortcuts you choose), or the
**bare** screen. Also choose where it stands, how it comes, its screen, which pages and in what
order, which tiles, and more. It follows your colours and modes like the rest of yoru.

### The wallpaper

Drawn by the shell: it drifts with the workspaces (parallax, optional), plays videos
(paused while windows cover it, you can disable this).

Or let [skwd-wall v2](https://github.com/liixini/skwd-wall) draw it: pick "skwd-wall" under
Settings → Wallpaper → Drawn by (or run `yoru backend skwd`). Its daemon then shows the
wallpaper with its own transitions and players, and yoru keeps taking the colors, also from
whatever you pick in skwd's own picker (Wallpaper Engine scenes included). yoru's weather still
falls over it, and yoru pauses skwd's videos under your windows. The same settings page has
skwd's transitions (with its sand ones), video sound, battery saver and idle pause, whether
mod+w opens yoru's picker or skwd's, and buttons for skwd's picker, mixer and settings.
Needs `skwd-wall-v2-bin` and `skwd-deck-bin` (AUR); `yoru backend yoru` goes back.

### Colors from the wallpaper

When you set a wallpaper, yoru gets its colors and applies them to the shell and to your apps. When it's a video wallpaper, the colors change live (in the shell, not in GTK apps etc.).

### Wallpaper transitions

Currently, there are 8 wallpaper transition animations: ripple, fade, wipe, disc, stripes, zoom, honeycomb and pixelate (or a random
one each time), you can adjust its duration. **Stripe wallpaper transition animation demonstration:**

https://github.com/user-attachments/assets/59dd98a2-d774-49e4-9f99-9d3c45c83046

### Wallpapers by time of day!

Optional: your dark wallpapers are applied at night, your bright ones by day, and the softer ones by dawn/dusk! "How does yoru know if it's day or not?" Well, by your location! The default one uses your IP. You can choose a folder for each period of the day.

### Weather on the wallpaper

Snow, rain, fog or a storm falls over the picture when it does outside
(yoru uses [open-meteo api](https://open-meteo.com) to know the weather of where you live), and even an aurora when it's a clear night! Want to know what it looks like? Go see the [aurora](docs/aurora.png), the [snow](docs/snow.png) and the [storm](docs/storm.png)!

Shooting stars cross the aurora now and then, more often on a meteor shower's nights; the
aurora swells with your music; cloud shadows drift over the picture when it's overcast; and on
fair days the seasons come too: sakura in spring, leaves in autumn, fireflies on summer evenings
(by your hemisphere). While you focus, a soft rain falls.

### Your wallpapers

In the picker (mod+w), a heart makes one a favourite (the rotation can keep to those), the eye
hides one so it never comes up on its own, and `yoru wall back` brings back the one before.
Its Online tab searches Wallhaven, Konachan, MotionBgs (live wallpapers) and this season's osu!
backgrounds: Enter tries one, Keep (Ctrl+S) holds on to it, otherwise it goes when the next one
comes. Settings → Wallpaper → From the internet gets a random one the same way.

### Anime pictures (mod+u)

The island opens onto Danbooru, Safebooru, yande.re or Konachan (an idea from end-4's sidebar).
Type tags and it suggests the ones the board knows (Tab takes one); pictures come in masonry
columns, an even grid or one sideways strip. Enter opens one large beside who drew it, who's in
it and its tags (click a tag to search it); Ctrl+S saves it to ~/Pictures/Anime, Ctrl+B makes it
the wallpaper, Ctrl+P pins the search. It's safe for work unless you say otherwise in
Settings → Island, and then the rest stay blurred until you point at one.

### The desktop

Yoru has many widgets, a clock with several styles, a weather widget, a calendar widget, a system usage widget and more! See the edit mode "add" section to see all of them!
Among them: **Tonight** (the moon as it really is, sunset to sunrise, whether you'll see stars),
**Fetch** (your system as a fetch tool prints it, the distro's logo in your colors), **Focus
history** (a heatmap of your focus rounds, or your streak) and **Next up** (your calendar).
Right-click the bare desktop for a menu: a new wallpaper, a note right there, edit mode.
Text on a bright wallpaper gets a deeper shadow where it needs one.

### Edit mode (mod+e)

Yoru has an edit mode, HEAVILY inspired by [noctalia's](https://github.com/noctalia-dev/noctalia) edit mode. You can edit the widget's position, which widgets you want, which widgets you don't and their styles.

![edit mode](docs/edit_mode.png)

### Notifications

Yoru keeps your last notifications (100 by default), even when you restart your pc! You can find
them on the control center, click one to open it, or quiet an app with the bell by its name. Under
Settings → Notifications each app's can show, come quietly or never, with a sound if you like.
After you unlock, the island says what came while you were away.

### Your calendar

Add your calendars' .ics links (Google, Proton, Nextcloud, Outlook all have one) or files under
Settings → Calendar: their events show in the island's calendar, in the Next up widget, and the
island reminds you a few minutes before each.

### Your apps' colors

kitty, Alacritty, Ghostty, Yazi, tmux, Neovim and Spotify (spicetify) get themes from the
wallpaper too: Settings → App themes writes them and, with one click, points each app at its
theme (keeping a copy of its config). Any other app: put a template in `~/.config/yoru/templates`
with `{{primary}}` where each color goes and a first line `yoru: out ~/path/to/its/colors`.

### Your phone

With KDE Connect, your real phone shows on the yoru phone's control page: its battery, its
notifications, and buttons to ring it or send it your clipboard.

### Firefox theme

Yoru has a rounded firefox theme! Take a look at it:
![firefox theme](docs/firefox_theme_and_startpage.png)

### Config window

Yoru has a configuration window HEAVILY inspired by [end-4's](https://github.com/end-4/dots-hyprland), that's where you configure EVERYTHING: your wallpaper, the color palette, the widget's styles, the startpage, the weather and more.

![config_window](docs/config_window.png)

## Install

    git clone https://github.com/simeulinuxkaliaiwr/yoru ~/yoru
    ~/yoru/install.sh

The install script installs dependencies, and sets up yoru for the compositor that's running (aro, hyprland or niri), but you can choose it yourself by running `./install.sh aro/hyprland/niri`.

| | the line you must add to use yoru | what it does |
|---|---|---|
| Hyprland 0.56+ | `require("yoru")` in `hyprland.lua` | brings [config/hypr/yoru.lua](config/hypr/yoru.lua) |
| older Hyprland | `source = ~/.config/hypr/yoru.conf` | brings [config/hypr/yoru.conf](config/hypr/yoru.conf) |
| niri | `include "yoru.kdl"` in `config.kdl` | brings [config/niri/yoru.kdl](config/niri/yoru.kdl) |
| aro | yoru's whole aro config | [config/aro/config](config/aro/config) |

Why do you need to do that? So your compositor gets the border colors, and keybinds.

Dependencies: see [docs/dependencies.txt](docs/dependencies.txt)

You can start the shell by the command `yoru-shell`.

If you want to install firefox's theme and the startpage, run `sudo install -m644 config/firefox/mozilla.cfg /usr/lib/firefox/`

## Keybindings

| | |
|---|---|
| `mod+a` | Smart launcher with web search support, emoji and can run commands and search for applications. |
| `mod+v` | Clipboard history |
| `mod+x` | Control center |
| `mod+m` | Media player |
| `mod+w` | Wallpaper selector |
| `mod+u` | Anime pictures from image boards |
| `mod+shift+w` | Next wallpaper |
| `mod+shift+e` | Open the power menu |
| `mod+i` | Open config window |
| `mod+e` | Open edit mode |
| `mod+y` | Open the phone |
| `mod+Tab` | window picker (type to filter) |
| `mod+/` | Keybindings cheat-sheet |
| `mod+p` | 25m timer to focus |
| `mod+shift+c` | Color picker |
| `mod+shift+Print` | Record your screen |
| `mod+ctrl+Print` | Record only an area of your screen |
| `mod+escape` | Lock your screen |
| `mod+o` | Overview, only if you're on aro |
| `Print` | Screenshot your screen |
| `Super+Print` | Screenshot only an area of your screen |

## Yoru IPC commands

Run `yoru` to see available commands.
