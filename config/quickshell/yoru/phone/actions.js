.pragma library

// what the phone's tiles and keys can do, by name: [icon, label]. Phone.qml knows how to
// do each and whether it's on; the settings page only needs the names, so they live here
var all = {
    wifi: ["wifi", "Wi-Fi"],
    bluetooth: ["bluetooth", "Bluetooth"],
    night: ["nightlight", "Night light"],
    caffeine: ["coffee", "Caffeine"],
    dnd: ["do_not_disturb_on", "Do not disturb"],
    focus: ["timer", "Focus"],
    record: ["screen_record", "Record"],
    screenshot: ["screenshot_region", "Screenshot"],
    picker: ["colorize", "Pick a colour"],
    wallpaper: ["wallpaper", "Wallpapers"],
    next: ["wallpaper_slideshow", "Next wallpaper"],
    mic: ["mic", "Microphone"],
    music: ["play_pause", "Play / pause"],
    lock: ["lock", "Lock"],
    settings: ["settings", "Settings"],
    power: ["power_settings_new", "Power"]
};
var order = Object.keys(all);

// tiles two wide: they have a name to show (the network, the headphones) and a panel
var wide = ["wifi", "bluetooth"];

var pages = ["home", "control", "today", "music"];
var page = {
    home: ["home", "Home"],
    control: ["tune", "Control"],
    today: ["today", "Today"],
    music: ["music_note", "Music"]
};

function icon(id) { return (all[id] || ["help", ""])[0]; }
function label(id) { return (all[id] || ["", id])[1]; }
