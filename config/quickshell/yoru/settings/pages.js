.pragma library
// the settings window's pages, in its order: id, icon, name, what it's for, group, words to find it
// by. The window and the launcher's settings results (SettingsIndex.qml) both read it; each id's
// file is settings/<Id>Page.qml
var list = [
    { id: "quick", icon: "tune", name: "Quick", about: "The wallpaper, its colours and how fast things move", group: "Look", words: "scheme colour palette accent vivid main music speed animation" },
    { id: "wallpaper", icon: "wallpaper", name: "Wallpaper", about: "Transitions, live wallpapers and where they come from", group: "Look", words: "transition fade wipe disc parallax video folders rotate shuffle backend skwd skwd-wall daemon" },
    { id: "clock", icon: "schedule", name: "Clock", about: "The clock on the desktop", group: "Look", words: "time style kanji serif analog position" },
    { id: "widgets", icon: "widgets", name: "Widgets", about: "Which widgets, what they sit on, and where", group: "Look", words: "weather calendar system media today arrangement column grid row free custom edit mode place move resize drag glass neon frosted blur gradient hud stack" },
    { id: "layouts", icon: "dashboard_customize", name: "Widget layouts", about: "How each widget lays itself out", group: "Look", words: "hero pill week date cover chips bars rings graph split dots vinyl record sun sunrise sunset" },
    { id: "visualizer", icon: "graphic_eq", name: "Visualizer", about: "The music, rising off the bottom of the screen", group: "Look", words: "cava bars wave mirror dots audio" },
    { id: "start", icon: "tab", name: "Start page", about: "Firefox's new tab page", group: "Look", words: "firefox new tab browser search engine links greeting address bar focus cursor keyboard" },
    { id: "island", icon: "toolbar", name: "Island", about: "The bar that becomes everything", group: "Shell", words: "clock 24 hour battery workspaces notifications" },
    { id: "phone", icon: "smartphone", name: "Phone", about: "Your apps, quick settings, the day and the music, in your hand", group: "Shell", words: "mobile slab flip keitai bare pages tiles quick settings dock keypad lyrics wifi bluetooth" },
    { id: "notifications", icon: "notifications", name: "Notifications", about: "What pops up, what's kept, and from which apps", group: "Shell", words: "notification pop-up toast sound history keep app mute quiet never block" },
    { id: "focus", icon: "timer", name: "Focus & quiet", about: "The focus timer and do not disturb", group: "Shell", words: "pomodoro break dnd quiet hours night" },
    { id: "lock", icon: "lock", name: "Lock screen", about: "What you see when you come back", group: "Shell", words: "blur dim idle password power characters shapes dots warn warning countdown" },
    { id: "screen", icon: "nightlight", name: "Night light", about: "A warmer screen at night, by hand or by itself", group: "Shell", words: "night light warm warmth kelvin temperature wlsunset sunset sunrise schedule hours blue" },
    { id: "weather", icon: "partly_cloudy_day", name: "Weather", about: "Where the forecast is for", group: "More", words: "city fahrenheit location" },
    { id: "about", icon: "info", name: "About", about: "yoru, its keys and its config", group: "More", words: "keys rice config" },
];
