-- ╔══════════════════════════════════════════════════════════════════════════════╗
-- ║                  GHOSTEDLAND COMPOSITOR CONFIGURATION (LUA)                  ║
-- ║                                                                            ║
-- ║  Unified GhostedLand desktop platform configuration incorporating          ║
-- ║  user custom decorations, controller/inputs, keybindings, animations,     ║
-- ║  and window rules.                                                         ║
-- ╚══════════════════════════════════════════════════════════════════════════════╝

local HOME = os.getenv("HOME") or "/home/bibek"

------------------
---- MONITORS ----
------------------
-- Catch-all rule: every display uses its native (preferred) mode and an
-- automatic scale, so a fresh install works on any panel. Ghosted Settings adds
-- per-output rules below when you pick a specific resolution or refresh rate.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,
        border_size = 3,

        col = {
            active_border   = { colors = {"rgba(c6a0f6ee)", "rgba(8aadf4ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 0.95,
        inactive_opacity = 0.8,
        fullscreen_opacity = 1.0,

        blur = {
            enabled   = true,
            size      = 6,
            passes    = 1,
            popups    = true,
            special   = true,
            ignore_opacity = true,
            xray      = false,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        disable_hyprland_logo           = true,
        force_default_wallpaper         = 0,
        disable_xdg_env_checks          = true,
        disable_watchdog_warning        = true,
        disable_hyprland_guiutils_check = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

--------------------
---- ANIMATIONS ----
--------------------
hl.curve("myBezier",       { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05}  } })
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4.0,  bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-------------------------------
---- CONTROLLER / INPUTS ------
-------------------------------
hl.config({
    input = {
        kb_layout   = "us",
        follow_mouse = 1,
        sensitivity = 0.4,
        scroll_factor = 4,
        touchpad = {
            natural_scroll = true,
            drag_lock = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Core Application Launchers (User bindings)
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout -b 2 --protocol layer-shell"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme " .. HOME .. "/.config/rofi/config.rasi --layer = overlay"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))

-- User Apps
hl.bind("SUPER + B", hl.dsp.exec_cmd("brave"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("google-chrome-stable"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("gedit"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("subl"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen())

-- GhostedLand Platform Launchers
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("ghosted-settings"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("ghosted-control-center"))

-- Native GhostedLand IPC Session Exit
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("ghostedctl session exit"))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("ghostedctl session exit"))

-- Hardware Media Keys
-- Bound by XKB keycode on purpose. This compositor matches modifier-less
-- keysym binds (e.g. "XF86AudioMute") against the wrong code space, so the
-- arrow keys fired them: Left = mute, Right = volume down, End = volume up.
-- Keycodes (evdev code + 8) match exactly one physical key. Bind each key
-- once; a keysym + keycode pair for the same key fires twice.
--   121 Mute  122 Vol-  123 Vol+  232 Bright-  233 Bright+  256 MicMute  255 Airplane
-- Some laptops send alternates instead: 198 (MicMute via F20), 246 (WLAN key).
local media = { locked = true, repeating = true }
local toggle = { locked = true }
hl.bind("code:123", hl.dsp.exec_cmd("ghosted-control-center --volume +5"), media)
hl.bind("code:122", hl.dsp.exec_cmd("ghosted-control-center --volume -5"), media)
hl.bind("code:233", hl.dsp.exec_cmd("ghosted-control-center --brightness +5"), media)
hl.bind("code:232", hl.dsp.exec_cmd("ghosted-control-center --brightness -5"), media)
hl.bind("code:121", hl.dsp.exec_cmd("ghosted-control-center --mute-toggle"), toggle)
hl.bind("code:256", hl.dsp.exec_cmd("ghosted-control-center --mic-mute-toggle"), toggle)
hl.bind("code:255", hl.dsp.exec_cmd("ghosted-control-center --airplane-key"), toggle)
hl.bind("code:198", hl.dsp.exec_cmd("ghosted-control-center --mic-mute-toggle"), toggle)
hl.bind("code:246", hl.dsp.exec_cmd("ghosted-control-center --airplane-key"), toggle)

-- Focus navigation
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Mouse window controls
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------
---- WINDOW & LAYER RULES ------
--------------------------------
-- kitty asks to be maximized as it opens, which makes the new window cover the
-- workspace (and SUPER + arrow focus then has nowhere to go). Ignore that request
-- for kitty only: it has no maximize button, so nothing is lost. Do NOT widen
-- this to all classes — that disables every app's maximize button.
hl.window_rule({ name = "no-client-maximize", match = { class = "^(kitty)$" }, suppress_event = "maximize" })
hl.window_rule({ name = "float-sublime", match = { class = "sublime_text" }, float = true })
hl.window_rule({ name = "float-subl", match = { class = "subl" }, float = true, center = true })
hl.window_rule({ name = "float-blueman", match = { class = "blueman-manager" }, float = true, center = true })
hl.window_rule({ name = "float-gedit", match = { class = "org.gnome.gedit" }, float = true, center = true })
hl.window_rule({ name = "float-dialogs", match = { title = "Open Files|Open|Save|Save As|Export|Import|Choose File|Rename" }, float = true, center = true })
hl.window_rule({ name = "opacity-kitty", match = { class = "kitty" }, opacity = 0.8 })
hl.window_rule({ name = "opacity-thunar", match = { class = "thunar" }, opacity = 0.8 })
hl.window_rule({ name = "opacity-code", match = { class = "Code" }, opacity = 0.8 })
hl.window_rule({ name = "opacity-rofi", match = { class = "rofi" }, opacity = 0.94 })
hl.window_rule({ name = "opacity-logout", match = { class = "logout_dialog" }, opacity = 0.94 })

-- GhostedLand Platform Window Rules
hl.window_rule({ name = "ghosted-settings", match = { class = "org.ghosted.settings" }, float = true, center = true, animation = "popin" })
hl.window_rule({ name = "ghosted-control-center", match = { class = "org.ghosted.control-center" }, float = true, no_anim = true })

-- Layer Rules (Rofi, Wofi, Logout Dialog)
hl.layer_rule({ name = "blur-rofi", match = { namespace = "rofi" }, blur = true, animation = "popin" })
hl.layer_rule({ name = "blur-logout", match = { namespace = "logout_dialog" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "dim-wofi", match = { namespace = "wofi" }, dim_around = true })

-------------------
---- AUTOSTART ----
-------------------
local function on_startup()
    -- Ghosted Wallpaper & Ghosted Bar
    hl.exec_cmd("ghosted-wallpaper &")
    hl.exec_cmd("ghosted-bar &")

    -- GhostedLand Platform Daemon
    hl.exec_cmd("ghostedctl daemon &")

    -- D-Bus & Portals
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &")

    -- Polkit & Notifications
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")
    hl.exec_cmd("mako &")

    -- Clipboard History
    hl.exec_cmd("wl-paste --type text --watch cliphist store &")
    hl.exec_cmd("wl-paste --type image --watch cliphist store &")
end

hl.on("hyprland.start", on_startup)

