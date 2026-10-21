-- détecte la machine via /etc/hostname pour les réglages per-host
local hostname = io.open("/etc/hostname"):read("*l")
-- bordures : couleurs extraites du fond d ecran par matugen (config/matugen/), sinon theme.nix
local ok, wallTheme = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/matugen-colors.lua")
local theme = ok and wallTheme or require("hypr-theme")

-- scale moniteur : adapté à l'écran de chaque machine
local monitorScale = hostname == "games" and 1.0 or 1.8
local monitorMode = hostname == "games" and "2560x1440@360" or "preferred"

-- this section tells hyprland how to set up your displays.
-- "preferred" mode uses the native resolution, and "auto" position lets hyprland arrange monitors automatically.
------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = monitorMode,
    position = "auto",
    scale    = monitorScale,
})


-- these variables store the names of your default applications.
-- hyprland uses them in keybindings so you only need to change the program name in one place.
---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "wezterm"
local fileManager = "dolphin"
local menu        = "rofi -show drun"


-- commands listed here run automatically when hyprland starts.
-- useful for launching background services like a notification daemon or a status bar.
-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function ()
    hl.exec_cmd("wayle panel start")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("systemctl --user start hypridle")
    -- terminal du workspace 3 : fastfetch, puis un nushell interactif.
    -- la classe ws3-term ne touche pas un wezterm normal, et
    -- --always-new-process evite de rejoindre une instance deja ouverte.
    hl.exec_cmd("wezterm start --always-new-process --class ws3-term -- nu -e fastfetch")
end)


-- environment variables set here are passed to all processes launched by hyprland.
-- xcursor_size and hyprcursor_size control the mouse cursor size in wayland and hyprland's own cursor engine.
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
-- le wrapper nixos donne cap_sys_nice a hyprland : la glibc passe en mode securise
-- et retire TZDIR des variables. on le remet pour que les applis trouvent le fuseau.
hl.env("TZDIR", "/etc/zoneinfo")


-- this section controls which programs are allowed to perform sensitive operations like screen capture or plugin loading.
-- changes here require a full hyprland restart to take effect.
-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons


-- this section controls the visual appearance of windows, borders, shadows, and blur.
-- gaps, rounding, and colors are set here to customize how the desktop looks.
-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = {theme.active_border}, angle = 45 },
            inactive_border = theme.inactive_border,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 0,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 2,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 4,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- animations define how windows, workspaces, and layers move on screen.
-- bezier curves and springs control the easing and feel of each transition.
-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("snap",           { type = "bezier", points = { {0.5, 0},     {0.5, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = false, speed = 1,    bezier = "snap",         style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = false, speed = 1,    bezier = "snap",         style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 1,    bezier = "snap",         style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

-- miscellaneous hyprland options that don't fit elsewhere.
-- here you can disable the default hyprland anime mascot wallpaper shown on an empty desktop.
----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


-- this section configures keyboard layout, mouse sensitivity, and touchpad behavior.
-- the gesture entry below sets up a 3-finger swipe to switch workspaces.
---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = hostname == "games" and "fr,us" or "us,fr", -- games : azerty + qwerty, alt+shift pour basculer
        kb_variant = "",
        kb_model   = "",
        kb_options = hostname == "games" and "caps:super,grp:alt_shift_toggle" or "grp:alt_shift_toggle", -- alt+shift bascule la disposition partout, games : caps lock devient super en plus (clavier 60%)
        kb_rules   = "",
        numlock_by_default = true, -- verr num actif au demarrage de la session
        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


if hostname == "games" then
    hl.config({
        input = {
            accel_profile = "flat",
        },
    })
end

-- keybindings map key combinations to actions like launching apps, closing windows, or switching workspaces.
-- mainmod is set to super (the windows key) and used as the prefix for most shortcuts.
---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + C", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = "code:" .. (i + 9) -- keycodes 10-19 = rangée 1..0, marche en azerty comme en qwerty
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind("Print",                          hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + P",       hl.dsp.exec_cmd("hyprshot -m region"))
-- home sans modificateur : meme capture de zone que print.
-- sans non_consuming, hyprland garde la touche et les applis ne la voient pas.
hl.bind("Home",                          hl.dsp.exec_cmd("hyprshot -m region"))


-- window rules apply specific behaviors to windows matching certain criteria (class, title, float state, etc.).
-- workspace rules control how workspaces behave, such as removing gaps when only one window is open.
--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name      = "assign-brave-workspace",
    match     = { class = "^(brave-browser)$" },
    workspace = "2 silent",
})

hl.window_rule({
    name      = "assign-vesktop-workspace",
    match     = { class = "^(vesktop)$" },
    workspace = "3 silent",
})

-- terminal lance au demarrage. seule la classe ws3-term est visee.
hl.window_rule({
    name      = "assign-ws3-term-workspace",
    match     = { class = "^(ws3-term)$" },
    workspace = "3 silent",
})

hl.window_rule({
    name      = "assign-gajim-workspace",
    match     = { class = "^(org.gajim.Gajim)$" },
    workspace = "3 silent",
})

-- gajim flotte au-dessus de la grille du workspace 3 au lieu d y prendre une case
hl.window_rule({
    name   = "float-gajim",
    match  = { class = "^(org.gajim.Gajim)$" },
    float  = true,
    size   = "monitor_w*0.4 monitor_h*0.6",
    center = true,
})

hl.window_rule({
    name      = "assign-fsa-workspace",
    match     = { class = "^(fsa)$" },
    workspace = "3 silent",
})

-- steam et lutris ouvrent sur le workspace 5, sans prendre le focus.
-- steam ou Steam seulement : pas les jeux (steam_app_*).
hl.window_rule({
    name      = "assign-steam-workspace",
    match     = { class = "^([Ss]team)$" },
    workspace = "5 silent",
})

hl.window_rule({
    name      = "assign-lutris-workspace",
    match     = { class = "^(net.lutris.Lutris|[Ll]utris)$" },
    workspace = "5 silent",
})

-- workspace 3 : vesktop occupe toute la moitie gauche (l'ancienne case de
-- signal en plus du haut gauche). le terminal ws3-term est en haut a
-- droite, fsa en bas a droite. equibop n'a plus de regle. la zone depend
-- de la classe, pas de l'ordre d'ouverture. une zone dont l'appli est
-- fermee reste vide, sauf pour une fenetre inconnue qui prend une zone
-- libre. au-dela, grille generique.
local chatGridRoles = {
    vesktop      = "left",
    ["ws3-term"] = "top-right",
    fsa          = "bottom-right",
}

local chatGridRoleOrder = { "left", "top-right", "bottom-right" }

local function chatGridBox(ctx, role)
    if role == "left" then
        return ctx:column(1, 2)
    elseif role == "top-right" then
        return ctx:grid_cell(2, 2, 2)
    else
        return ctx:grid_cell(4, 2, 2)
    end
end

hl.layout.register("chat-grid", {
    recalculate = function(ctx)
        local placed, extras = {}, {}
        for _, target in ipairs(ctx.targets) do
            local window = target.window
            local role = window and chatGridRoles[string.lower(window.class or "")]
            if role and not placed[role] then
                placed[role] = target
            else
                table.insert(extras, target)
            end
        end

        -- fenetre inconnue ou deuxieme fenetre d'une appli : zone libre s'il en reste
        local free = {}
        for _, role in ipairs(chatGridRoleOrder) do
            if not placed[role] then
                table.insert(free, role)
            end
        end

        if #extras <= #free then
            for i, target in ipairs(extras) do
                placed[free[i]] = target
            end
            for role, target in pairs(placed) do
                target:place(chatGridBox(ctx, role))
            end
            return
        end

        -- plus de fenetres tuilees que de zones : grille generique, les applis connues restent en tete
        local ordered = {}
        for _, role in ipairs(chatGridRoleOrder) do
            if placed[role] then
                table.insert(ordered, placed[role])
            end
        end
        for _, target in ipairs(extras) do
            table.insert(ordered, target)
        end
        local cols = math.ceil(math.sqrt(#ordered))
        for i, target in ipairs(ordered) do
            target:place(ctx:grid_cell(i, cols))
        end
    end,
})

-- hl.layout.register prefixe le nom par "lua:"
hl.workspace_rule({ workspace = "3", layout = "lua:chat-grid" })
