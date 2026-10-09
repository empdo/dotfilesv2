-- Hyprland config (Lua)
-- Converted from hyprland.conf. Wiki: https://wiki.hypr.land/Configuring/
--
-- Split into more files with require("name") -> ~/.config/hypr/name.lua
-- Editor autocompletion: point your Lua LSP at /usr/share/hypr/stubs


------------------
---- MONITORS ----
------------------

-- Fallback for any other monitor
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Main: 1440p @ 144 Hz
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Side: 1080p @ 60 Hz, to the right, rotated 270° (transform 3)
hl.monitor({ output = "HDMI-A-3", mode = "1920x1080@60", position = "2560x0", scale = 1, transform = 3 })


---------------------
---- MY PROGRAMS ----
--------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "qs ipc call launcher toggle"   -- Quickshell overlay; see ~/.config/quickshell/modules/launcher


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("SK_RENDERER=gl easyeffects --gapplication-service") -- background service
    hl.exec_cmd("quickshell")                                         -- bar
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("GTK_THEME", "Adwaita:dark")



-----------------------
----- PERMISSIONS -----
-----------------------

-- Changes here require a Hyprland restart
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 7,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = "rgba(1f1f1fff)",
            inactive_border = "rgba(1f1f1faf)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 5,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = false, -- animations are off; the curves below only matter if you turn this on
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true
    },
})

-- Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

-- Animations: { name, speed, curve, style }
local animations = {
    { "global",        10,   "default" },
    { "border",        5.39, "easeOutQuint" },
    { "windows",       0.1, "easeOutQuint" },
    { "windowsIn",     1.1,  "easeOutQuint", "popin 87%" },
    { "windowsOut",    1.49, "linear",       "popin 87%" },
    { "fadeIn",        1.73, "almostLinear" },
    { "fadeOut",       1.46, "almostLinear" },
    { "fade",          3.03, "quick" },
    { "layers",        3.81, "easeOutQuint" },
    { "layersIn",      4,    "easeOutQuint", "fade" },
    { "layersOut",     1.5,  "linear",       "fade" },
    { "fadeLayersIn",  1.79, "almostLinear" },
    { "fadeLayersOut", 1.39, "almostLinear" },
    { "workspaces",    1.94, "almostLinear", "fade" },
    { "workspacesIn",  1.21, "almostLinear", "fade" },
    { "workspacesOut", 1.94, "almostLinear", "fade" },
    { "zoomFactor",    7,    "quick" },
}
for _, a in ipairs(animations) do
    hl.animation({ leaf = a[1], enabled = true, speed = a[2], bezier = a[3], style = a[4] })
end


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "se",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        accel_profile  = "flat",
        force_no_accel = true,

        sensitivity = 1.0, -- was 2 in the old config, but the valid range is -1.0 to 1.0

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })


----------------------
---- WINDOW RULES ----
----------------------

-- Ignore maximize requests from apps. kitty remembers its last window state,
-- so once one got maximized every new kitty would open maximized over the tiles.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"
local function key(k) return mainMod .. " + " .. k end

-- Apps and window actions
hl.bind(key("RETURN"), hl.dsp.exec_cmd(terminal),    { desc = "Open terminal" })
hl.bind(key("Q"),      hl.dsp.window.close(),        { desc = "Close window" })
-- hl.bind(key("M"),   hl.dsp.exit())
hl.bind(key("E"),      hl.dsp.exec_cmd(fileManager), { desc = "Open file manager" })
hl.bind(key("V"),      hl.dsp.window.float(),        { desc = "Toggle floating" })
hl.bind(key("D"),      hl.dsp.exec_cmd(menu),        { desc = "App launcher" })
hl.bind(key("P"),      hl.dsp.window.pseudo(),       { desc = "Toggle pseudo-tiling" })     -- dwindle
hl.bind(key("F"),      hl.dsp.window.fullscreen(),   { desc = "Toggle fullscreen" })

-- Move focus / windows with vim keys
local dirs = { H = "left", J = "down", K = "up", L = "right" }
for k, dir in pairs(dirs) do
    hl.bind(key(k),               hl.dsp.focus({ direction = dir }),       { desc = "Focus window " .. dir })
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ direction = dir }), { desc = "Move window " .. dir })
end

-- Resize the active window with SUPER + CTRL + H/J/K/L (hold to keep resizing)
local step = 30
local resize = { H = { -step, 0, "left" }, L = { step, 0, "right" }, K = { 0, -step, "up" }, J = { 0, step, "down" } }
for k, d in pairs(resize) do
    hl.bind(key("CTRL + " .. k), hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }),
        { repeating = true, desc = "Resize window " .. d[3] })
end

-- Workspaces 1-10: SUPER + [0-9] to switch, SUPER + SHIFT + [0-9] to move a window there (without following it)
for i = 1, 10 do
    local k = tostring(i % 10) -- workspace 10 is key 0
    hl.bind(key(k),               hl.dsp.focus({ workspace = i }),                      { desc = "Go to workspace " .. i })
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i, follow = false }), { desc = "Send window to workspace " .. i })
end

-- Screenshots
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region --freeze"),
    { desc = "Screenshot region" })                                                      -- region, copy + save
hl.bind("SUPER + CTRL + S",  hl.dsp.exec_cmd("hyprshot -m region --freeze --raw | satty --filename - --copy-command wl-copy --early-exit"),
    { desc = "Screenshot region and annotate" })
hl.bind("Print",             hl.dsp.exec_cmd("hyprshot -m output"), { desc = "Screenshot monitor" })
hl.bind("ALT + Print",       hl.dsp.exec_cmd("hyprshot -m window"), { desc = "Screenshot active window" })

local bigGaps = {}
hl.bind(key("G"), function()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local sel = ws.id > 0 and tostring(ws.id) or ("name:" .. ws.name)
    bigGaps[sel] = not bigGaps[sel]
    hl.workspace_rule({ workspace = sel, gaps_in = 7, gaps_out = bigGaps[sel] and 100 or 20 })
end, { desc = "Toggle wide gaps on this workspace" })

-- Keybind cheatsheet (Quickshell overlay; see ~/.config/quickshell/modules/cheatsheet)
-- On a Swedish layout "/" is Shift+7, so SUPER + SLASH would collide with
-- SUPER + SHIFT + 7. Letter keys carry no such baggage.
hl.bind(key("ALT + K"), hl.dsp.exec_cmd("qs ipc call cheatsheet toggle"), { desc = "Show keybind cheatsheet" })

-- Notifications (Quickshell; see ~/.config/quickshell/modules/notifications).
-- The history lives behind the bell in the bar, so these are only the two
-- things worth reaching for without the mouse: shutting the current batch up,
-- and silencing everything before a call or a screen share.
hl.bind(key("N"),         hl.dsp.exec_cmd("qs ipc call notifications dismiss"),
    { desc = "Dismiss notifications on screen" })
hl.bind(key("SHIFT + N"), hl.dsp.exec_cmd("qs ipc call notifications dnd"),
    { desc = "Toggle do not disturb" })

-- Clipboard history (Quickshell; see ~/.config/quickshell/modules/clipboard).
-- SUPER + V is already taken by floating, so the history sits on shift.
hl.bind(key("SHIFT + V"), hl.dsp.exec_cmd("qs ipc call clipboard menu"),
    { desc = "Clipboard history" })

-- Scroll through existing workspaces
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })

-- Move/resize windows with SUPER + left/right mouse drag
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true, desc = "Drag window" })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true, desc = "Drag to resize window" })

-- Volume and brightness keys (work on lock screen, repeat when held)
local media = {
    { "XF86AudioRaiseVolume",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Volume up" },
    { "XF86AudioLowerVolume",  "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      "Volume down" },
    { "XF86AudioMute",         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     "Mute output" },
    { "XF86AudioMicMute",      "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   "Mute microphone" },
    { "XF86MonBrightnessUp",   "brightnessctl -e4 -n2 set 5%+",                  "Brightness up" },
    { "XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-",                  "Brightness down" },
}
for _, m in ipairs(media) do
    hl.bind(m[1], hl.dsp.exec_cmd(m[2]), { locked = true, repeating = true, desc = m[3] })
end

-- Media player keys (requires playerctl)
local player = {
    { "XF86AudioNext",  "playerctl next",       "Next track" },
    { "XF86AudioPause", "playerctl play-pause", "Play / pause" },
    { "XF86AudioPlay",  "playerctl play-pause", "Play / pause" },
    { "XF86AudioPrev",  "playerctl previous",   "Previous track" },
}
for _, m in ipairs(player) do
    hl.bind(m[1], hl.dsp.exec_cmd(m[2]), { locked = true, desc = m[3] })
end


-------------------------
---- CHEATSHEET DATA ----
-------------------------

-- Rebuild ~/.cache/cheatsheet/binds.json whenever the binds above change, so the
-- overlay always reflects the config that is actually loaded. The overlay watches
-- the file, so an open sheet updates itself.
local function rebuildCheatsheet()
    hl.exec_cmd("python3 " .. os.getenv("HOME") .. "/.config/quickshell/modules/cheatsheet/collect.py")
end

hl.on("hyprland.start", rebuildCheatsheet)
hl.on("config.reloaded", rebuildCheatsheet)   -- so hyprctl reload refreshes it too
