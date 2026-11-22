-- détecte la machine via /etc/hostname pour les réglages per-host
local hostname = io.open("/etc/hostname"):read("*l")
-- bordures : theme.nix (hypr-theme.lua). si le variant est dynamique, les couleurs
-- extraites du fond par matugen (config/matugen/) passent devant. sinon le fichier
-- matugen, meme reste d'un ancien variant, est ignore.
local theme = require("hypr-theme")
if theme.dynamic then
    local ok, wallTheme = pcall(dofile, os.getenv("HOME") .. "/.config/hypr/matugen-colors.lua")
    if ok then theme = wallTheme end
end

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
    -- historique du presse-papiers : chaque copie part dans cliphist
    hl.exec_cmd("wl-paste --watch cliphist store")
    -- montage auto des cles usb, icone seulement quand un support est la
    hl.exec_cmd("udiskie --automount --notify --smart-tray")
    -- seulement la session : aucune appli ne part au login, pas meme un terminal.
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
-- dossier des captures de hyprshot (sinon ~). satty enregistre au meme endroit (satty/config.toml)
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/screenshots")


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
            -- 2 passes (rayon 5) au lieu de 4 : rendu proche pour moitie moins de charge gpu
            size      = 5,
            passes    = 2,
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
        -- vrr coupe : vrr=2 force un modeset sur 1440p@360 dsc (ecran noir au changement de
        -- workspace depuis un plein ecran) et vrr=1 cause du flicker oled sur les themes sombres.
        vrr                     = 0,
    },
})

hl.config({
    render = {
        -- pas de bascule hdr auto au plein ecran : elle force un modeset,
        -- donc environ 1s d'ecran noir en plein ecran sur youtube.
        cm_auto_hdr    = 0,
        -- jeux plein ecran seulement : contourne le compositeur (latence et charge gpu moindres)
        direct_scanout = 2,
    },
})


-- this section configures keyboard layout, mouse sensitivity, and touchpad behavior.
-- the gesture entry below sets up a 3-finger swipe to switch workspaces.
---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- qwerty-fr (modules/desktop/sddm.nix) : qwerty us + accents sur altgr (alt droit).
        -- une seule disposition sur les deux hotes, donc aucune bascule
        kb_layout = "us_qwerty-fr",
        kb_variant = "qwerty-fr",
        kb_model   = "",
        kb_options = "caps:super", -- caps lock devient super partout (clavier 60% sur games)
        kb_rules   = "",
        numlock_by_default = true, -- verr num actif au demarrage de la session
        -- touche maintenue : repetition apres 300 ms, puis 40 par seconde (defauts 600 et 25)
        repeat_delay = 300,
        repeat_rate = 40,
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
-- menu rofi : verrouiller, veille, deconnexion, redemarrer, eteindre (pkgs/power-menu.nix)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("power-menu"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
-- historique du presse-papiers (super+v sert deja au flottant). il est stocke en
-- clair dans ~/.cache/cliphist/db. cliphist ignore les copies marquees sensibles
-- par l'appli source, mais bitwarden ne les marque pas : super+shift+suppr vide
-- tout l'historique apres avoir copie un mot de passe.
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + DELETE", hl.dsp.exec_cmd("cliphist wipe"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- gestion des fenetres.
-- f : vrai plein ecran. shift + f : maximise, la barre et les marges restent.
-- la regle suppress-maximize-events ne bloque que les demandes des applis,
-- pas ce dispatcher.
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- shift + fleches : deplace la fenetre active dans cette direction.
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

-- r : sous-map de redimensionnement. les fleches changent la taille par
-- pas de 40 px (20 px reste minuscule a l'echelle 1.8 de navi), echap ou
-- entree en sortent. tant qu'on y est, tous les autres binds sont inactifs.
hl.define_submap("resize", function()
    hl.bind("right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
    hl.bind("left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
    hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
    hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

-- tab : retour au workspace precedent, sans activer workspace_back_and_forth.
hl.bind(mainMod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))

-- w : liste des fenetres ouvertes dans rofi.
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("rofi -show window"))

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
-- super+home : capture de zone a annoter dans satty (reglages dans satty/config.toml)
hl.bind(mainMod .. " + Home",             hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))
-- pipette : copie en hex la couleur cliquee
hl.bind(mainMod .. " + SHIFT + X",       hl.dsp.exec_cmd("hyprpicker -a"))


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

-- scratchpad : un terminal deroulant (classe dropterm) sur le workspace
-- special "term". rien ne part au login : le terminal est lance au
-- premier super+s, puis reste vivant (shell et dossier gardes) et
-- super+s ne fait que le montrer ou le cacher.
hl.window_rule({
    name      = "dropterm-scratchpad",
    match     = { class = "^dropterm$" },
    workspace = "special:term silent",
    float     = true,
    size      = "monitor_w*0.7 monitor_h*0.5",
    move      = "monitor_w*0.15 50",
})

-- sans --always-new-process, wezterm reutilise son processus et ignore --class.
local droptermCmd = "wezterm start --always-new-process --class dropterm"
local droptermLaunchedAt = 0

hl.bind(mainMod .. " + S", function()
    -- get_windows ne voit que les fenetres mappees, classe exacte.
    if #hl.get_windows({ class = "dropterm" }) > 0 then
        hl.dispatch(hl.dsp.workspace.toggle_special("term"))
    elseif os.time() - droptermLaunchedAt > 3 then
        -- premier appui : pas de toggle. il partirait avant que la fenetre
        -- existe, puis la regle silent la poserait sans focus. la regle
        -- d'exec, lue apres les regles de fenetre, remplace le silent :
        -- hyprland ouvre lui-meme special:term et donne le focus au terminal.
        -- le delai de 3 s evite un second terminal si on rappuie pendant
        -- le demarrage.
        droptermLaunchedAt = os.time()
        hl.exec_cmd(droptermCmd, { workspace = "special:term" })
    end
end)

-- envoie la fenetre active dans le scratchpad, sans la suivre.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:term", follow = false }))

-- plan (games, et navi : ce fichier est partage). silent : la fenetre
-- part sur le workspace sans y changer le focus.
-- 1 grok, timon et vibe. 2 t3 code.
-- 3 rien. 4 brave. 5 social et fsa. 6 jeux. 7 lanceurs de jeux.
-- 10 suivi.

-- workspace 1. grok-bot est la classe du .desktop embarque.
hl.window_rule({
    name      = "assign-grok-workspace",
    match     = { class = "^(grok-bot)$" },
    workspace = "1 silent",
})

-- timon : electron nomme la classe d'apres le name du package.json
-- (timon-desktop), le StartupWMClass du .desktop (pkgs/timon.nix).
hl.window_rule({
    name      = "assign-timon-workspace",
    match     = { class = "^(timon-desktop)$" },
    workspace = "1 silent",
})

-- vibe : tui lancee dans wezterm avec la classe vibe (lanceur dans
-- modules/programs/apps.nix).
hl.window_rule({
    name      = "assign-vibe-workspace",
    match     = { class = "^(vibe)$" },
    workspace = "1 silent",
})

-- workspace 2 : t3 code. la fenetre pose com.t3tools.T3Code, le
-- .desktop annonce t3code (StartupWMClass) : on prend les deux.
hl.window_rule({
    name      = "assign-t3code-workspace",
    match     = { class = "^(com\\.t3tools\\.T3Code|t3code)$" },
    workspace = "2 silent",
})

-- workspace 4 : brave. la classe est celle du paquet (brave-browser).
hl.window_rule({
    name      = "assign-brave-workspace",
    match     = { class = "^(brave-browser)$" },
    workspace = "4 silent",
})

-- workspace 5 : social. vesktop et equibop : StartupWMClass du
-- paquet, et la casse minuscule que la fenetre wayland pose souvent.
-- signal : StartupWMClass = signal. fsa : classe fsa.
hl.window_rule({
    name      = "assign-vesktop-workspace",
    match     = { class = "^([Vv]esktop)$" },
    workspace = "5 silent",
})

hl.window_rule({
    name      = "assign-equibop-workspace",
    match     = { class = "^([Ee]quibop)$" },
    workspace = "5 silent",
})

hl.window_rule({
    name      = "assign-signal-workspace",
    match     = { class = "^(signal)$" },
    workspace = "5 silent",
})

-- fsa : le traitement du micro, range avec le social.
hl.window_rule({
    name      = "assign-fsa-workspace",
    match     = { class = "^(fsa)$" },
    workspace = "5 silent",
})

-- workspace 6 : les jeux, reconnus a la classe, pas au titre.
-- steam_app_<id> : fenetre d'un jeu steam. steam_app_default : jeu lance
-- hors steam via umu-proton / lutris. gamescope : un jeu lance dessous
-- (le paquet n'est pas installe, la classe suffit). un jeu wine classique
-- (classe <jeu>.exe) n'a aucune de ces classes et reste sur le workspace courant.
hl.window_rule({
    name      = "assign-steam-game-workspace",
    match     = { class = "^steam_app_(\\d+|default)$" },
    workspace = "6 silent",
})

hl.window_rule({
    name      = "assign-gamescope-workspace",
    match     = { class = "^(gamescope)$" },
    workspace = "6 silent",
})

-- workspace 7 : les lanceurs. le client steam, lutris, et battle.net
-- (lance par lutris sous wine, classe battle.net.exe). heroic n'est
-- pas installe, pas de regle.
hl.window_rule({
    name      = "assign-steam-workspace",
    match     = { class = "^([Ss]team)$" },
    workspace = "7 silent",
})

hl.window_rule({
    name      = "assign-lutris-workspace",
    match     = { class = "^(net.lutris.Lutris|[Ll]utris)$" },
    workspace = "7 silent",
})

hl.window_rule({
    name      = "assign-battlenet-workspace",
    match     = { class = "^([Bb]attle\\.net(\\.exe)?)$" },
    workspace = "7 silent",
})

-- workspace 10 : suivi du pc. btm et nvtop sont des programmes de
-- terminal, donc chacun a son lanceur wezterm et sa classe
-- (hosts/games/default.nix). un btm tape dans un terminal normal
-- n'est pas deplace. coolercontrol est la fenetre qt
-- (org.coolercontrol.CoolerControl), pas le service.
hl.window_rule({
    name      = "assign-ws10-btm-workspace",
    match     = { class = "^(ws10-btm)$" },
    workspace = "10 silent",
})

hl.window_rule({
    name      = "assign-ws10-nvtop-workspace",
    match     = { class = "^(ws10-nvtop)$" },
    workspace = "10 silent",
})

hl.window_rule({
    name      = "assign-coolercontrol-workspace",
    match     = { class = "^(org.coolercontrol.CoolerControl)$" },
    workspace = "10 silent",
})
