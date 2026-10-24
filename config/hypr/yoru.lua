-- yoru on Hyprland 0.56+ (Lua). install.sh links this beside your config;
-- add one line at the end of ~/.config/hypr/hyprland.lua:   require("yoru")
-- yoru's keys replace any of yours on the same keys (the stock config's
-- SUPER+M would otherwise quit Hyprland as the player opens); everything else
-- in your config stays yours. Older Hyprland: see yoru.conf.

-- the wallpaper's colours, rewritten by `yoru` on every wallpaper change
pcall(require, "yoru-colors")

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("yoru restore")
    hl.exec_cmd("yoru-shell")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("yoru-idle")
end)

-- the shell draws the wallpaper and the logo would only peek through
hl.config({ misc = { force_default_wallpaper = 0, disable_hyprland_logo = true } })

hl.window_rule({
    name  = "yoru-settings",
    match = { title = "^yoru.*settings$" },
    float = true,
    size  = "1100 740",
    center = true,
})

-- yoru's keys, each taking its key over from any bind already on it
local function bind(keys, dispatcher, opts)
    hl.unbind(keys)
    hl.bind(keys, dispatcher, opts)
end

-- the island and the rest of the shell
bind("SUPER + A",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle launcher"))
bind("SUPER + V",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle clip"))
bind("SUPER + X",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle control"))
bind("SUPER + M",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle media"))
bind("SUPER + W",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle walls"))
bind("SUPER + U",           hl.dsp.exec_cmd("qs -c yoru ipc call island toggle anime"))
bind("SUPER + Y",           hl.dsp.exec_cmd("qs -c yoru ipc call phone toggle"))
bind("SUPER + Tab",         hl.dsp.exec_cmd("qs -c yoru ipc call island toggle windows"))
bind("SUPER + slash",       hl.dsp.exec_cmd("qs -c yoru ipc call island toggle keys"))
bind("SUPER + SHIFT + E",   hl.dsp.exec_cmd("qs -c yoru ipc call island toggle power"))
bind("SUPER + SHIFT + W",   hl.dsp.exec_cmd("yoru wall next"))
bind("SUPER + I",           hl.dsp.exec_cmd("qs -n -p ~/.config/quickshell/yoru/settings.qml"))
bind("SUPER + E",           hl.dsp.exec_cmd("qs -c yoru ipc call desktop toggle"))
bind("SUPER + P",           hl.dsp.exec_cmd("qs -c yoru ipc call focus toggle"))
bind("SUPER + escape",      hl.dsp.exec_cmd("yoru-lock"))

-- capture
bind("Print",               hl.dsp.exec_cmd("yoru-shot full"))
bind("SUPER + Print",       hl.dsp.exec_cmd("yoru-shot area"))
bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("qs -c yoru ipc call record toggle"))
bind("SUPER + CTRL + Print",  hl.dsp.exec_cmd("qs -c yoru ipc call record area"))
bind("SUPER + SHIFT + C",   hl.dsp.exec_cmd("qs -c yoru ipc call picker pick"))

-- media keys, with the island's OSD
bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs -c yoru ipc call osd mic"), { locked = true })
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q set 5%+ && qs -c yoru ipc call osd brightness"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 5%- && qs -c yoru ipc call osd brightness"), { locked = true, repeating = true })
bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"), { locked = true })
