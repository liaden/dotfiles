--
-- xmonad example config file.
-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.
--
-- Normally, you'd only override those defaults you care about.
--
import XMonad
import System.Exit ()
import XMonad.Util.SpawnOnce ( spawnOnce )
import XMonad.Util.NamedScratchpad
import XMonad.Actions.Submap
import Graphics.X11.ExtraTypes.XF86 (xF86XK_AudioLowerVolume, xF86XK_AudioRaiseVolume, xF86XK_AudioMute, xF86XK_MonBrightnessDown, xF86XK_MonBrightnessUp, xF86XK_AudioPlay, xF86XK_AudioPrev, xF86XK_AudioNext)
import XMonad.Hooks.EwmhDesktops ( ewmh, ewmhFullscreen )
import qualified XMonad.Actions.PhysicalScreens as PS
import XMonad.Hooks.Rescreen ( addAfterRescreenHook, setRescreenWorkspacesHook )
import XMonad.Layout.NoBorders
import XMonad.Hooks.ManageDocks ( avoidStruts, docks )
import XMonad.Util.Types ( Direction2D(..) )
import XMonad.Hooks.ManageHelpers ( doCenterFloat, doFullFloat, isDialog, isFullscreen, isInProperty )
import XMonad.Util.Hacks ( windowedFullscreenFixEventHook )
import XMonad.Layout.Spacing ( spacingRaw, Border(Border), SpacingModifier(ModifyScreenBorderEnabled) )
import qualified XMonad.Util.ExtensibleState as XS
import XMonad.Layout.PerScreen
import XMonad.Layout.Column
import XMonad.Layout.ThreeColumns
import XMonad.Actions.CycleWS ( toggleWS' )
import XMonad.Actions.WindowBringer ( gotoMenuConfig, WindowBringerConfig(..) )
import XMonad.Actions.UpdatePointer ( updatePointer )
import XMonad.Layout.ToggleLayouts ( toggleLayouts, ToggleLayout(..) )
import XMonad.Layout.ResizableTile ( ResizableTall(..), MirrorResize(..) )
import XMonad.Layout.Renamed ( renamed, Rename(..) )
import XMonad.Layout.Gaps
    ( gaps,
      setGaps,
      GapMessage(DecGap, ToggleGaps, IncGap) )

import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import Data.List (intercalate)
import Data.Bits ((.&.))
-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal      = "kitty"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth   = 2

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
-- The keyboard's butterfly key sends ctrl+alt+super as one key, so the same
-- thumb key drives xmonad here and Amethyst on macOS.
myModMask       = controlMask .|. mod1Mask .|. mod4Mask

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
myWorkspaces    = ["\63083", "\63288", "\63306", "\61723", "\63107", "\63601", "\63391", "\61713", "\61884"]

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#3b4252"
myFocusedBorderColor = "#bc96da"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
-- Each binding carries its description, so the cheat sheet is built from the
-- same list xmonad binds and cannot drift from it.
data Bind = Bind (KeyMask, KeySym) String (X ())
          | Sub  (KeyMask, KeySym) String [Bind]
          | Doc  String String

myKeys conf = M.fromList $ concatMap toKeys (concatMap snd (myBindings conf)) ++ workspaceKeys conf
  where
    toKeys (Bind k _ a) = [(k, a)]
    toKeys (Sub k _ bs) = [(k, submap . M.fromList $ concatMap toKeys bs)]
    toKeys (Doc _ _)    = []

myBindings :: XConfig Layout -> [(String, [Bind])]
myBindings conf@(XConfig {XMonad.modMask = modm}) =
    [ ("LAUNCH",
        [ Bind (modm .|. shiftMask, xK_Return) "Terminal"     $ spawn $ XMonad.terminal conf
        , Bind (modm,               xK_o     ) "App launcher" $ spawn "~/.config/rofi/scripts/launcher.sh type-7 style-4"
        , Bind (modm,               xK_p     ) "Dashboard"    $ spawn "~/.xmonad/bin/eww-toggle dashboard"
        , Bind (modm .|. shiftMask, xK_o     ) "Go to window by title" $ gotoMenuConfig def { menuCommand = "rofi", menuArgs = ["-dmenu", "-i"] }
        , Bind (modm,               xK_s     ) "Sidebar"      $ spawn "~/.xmonad/bin/eww-toggle sidebar"
        , Sub  (modm,               xK_f     ) "Scratchpads"
            [ Bind (0, xK_m) "Music scratchpad"   $ namedScratchpadAction scratchpads "music"
            , Bind (0, xK_s) "Slack scratchpad"   $ namedScratchpadAction scratchpads "slack"
            , Bind (0, xK_d) "Discord scratchpad" $ namedScratchpadAction scratchpads "discord"
            ]
        ])

    , ("WINDOWS",
        [ Bind (modm,               xK_j     ) "Focus next"           $ windows W.focusDown
        , Bind (modm,               xK_k     ) "Focus previous"       $ windows W.focusUp
        , Bind (modm,               xK_m     ) "Focus master"         $ windows W.focusMaster
        , Bind (modm,               xK_Return) "Swap with master"     $ windows W.swapMaster
        , Bind (modm .|. shiftMask, xK_j     ) "Swap with next"       $ windows W.swapDown
        , Bind (modm .|. shiftMask, xK_k     ) "Swap with previous"   $ windows W.swapUp
        , Bind (modm,               xK_t     ) "Sink into tiling"     $ withFocused $ windows . W.sink
        , Bind (modm .|. shiftMask, xK_f     ) "Float full screen"    $ withFocused $ \w -> windows $ W.float w (W.RationalRect 0 0 1 1)
        , Bind (modm .|. shiftMask, xK_c     ) "Close window"         kill
        , Doc  "Mod-Drag left"                 "Float and move"
        , Doc  "Mod-Drag right"                "Float and resize"
        , Doc  "Mod-Click middle"              "Raise"
        ])

    , ("LAYOUT",
        [ Bind (modm,               xK_Tab   ) "Next layout"          $ sendMessage NextLayout
        , Bind (modm .|. shiftMask, xK_Tab   ) "Reset layout"         $ setLayout (XMonad.layoutHook conf) >> applyHud
        , Bind (modm,               xK_space ) "Toggle full screen layout" $ sendMessage ToggleLayout
        , Bind (modm,               xK_i     ) "Show layout name"     showLayoutName
        , Bind (modm,               xK_h     ) "Shrink master"        $ sendMessage Shrink
        , Bind (modm,               xK_l     ) "Expand master"        $ sendMessage Expand
        -- ResizableTall names these for its mirrored form, so they read backwards here.
        , Bind (modm .|. shiftMask, xK_h     ) "Shrink window in column" $ sendMessage MirrorExpand
        , Bind (modm .|. shiftMask, xK_l     ) "Grow window in column" $ sendMessage MirrorShrink
        , Bind (modm,               xK_comma ) "More in master"       $ sendMessage (IncMasterN 1)
        , Bind (modm,               xK_period) "Fewer in master"      $ sendMessage (IncMasterN (-1))
        , Bind (modm,               xK_n     ) "Refresh sizes"        refresh
        ])

    , ("WORKSPACES",
        [ Doc  "Mod-1..9"                      "Switch to workspace"
        , Bind (modm,               xK_grave ) "Last workspace"       $ toggleWS' ["NSP"]
        , Doc  "Mod-Shift-1..9"                "Move window to workspace"
        , Doc  "Mod-w e r"                     "Focus screen 1, 2, 3 from the left"
        , Doc  "Mod-Shift-w e r"               "Move window to screen 1, 2, 3 from the left"
        ])

    -- A submap because modm already includes control, so mod-control-t would collide with mod-t.
    , ("GAPS",
        [ Sub  (modm,               xK_g     ) "Gaps"
            [ Bind (0, xK_g) "Toggle gaps"        $ sendMessage ToggleGaps
            , Bind (0, xK_t) "Grow left gap"      $ sendMessage $ IncGap 10 L
            , Bind (0, xK_y) "Grow top gap"       $ sendMessage $ IncGap 10 U
            , Bind (0, xK_u) "Grow bottom gap"    $ sendMessage $ IncGap 10 D
            , Bind (0, xK_i) "Grow right gap"     $ sendMessage $ IncGap 10 R
            ]
        , Bind (modm .|. shiftMask, xK_t     ) "Shrink left gap"      $ sendMessage $ DecGap 10 L
        , Bind (modm .|. shiftMask, xK_y     ) "Shrink top gap"       $ sendMessage $ DecGap 10 U
        , Bind (modm .|. shiftMask, xK_u     ) "Shrink bottom gap"    $ sendMessage $ DecGap 10 D
        , Bind (modm .|. shiftMask, xK_i     ) "Shrink right gap"     $ sendMessage $ DecGap 10 R
        , Bind (modm .|. shiftMask, xK_g     ) "Reset gaps"           $ sendMessage $ setGaps [(L,30), (R,30), (U,40), (D,60)]
        ])

    , ("MEDIA",
        [ Bind (0, xF86XK_AudioPlay)          "Play / pause"          $ spawn "playerctl play-pause"
        , Bind (0, xF86XK_AudioPrev)          "Previous track"        $ spawn "playerctl previous"
        , Bind (0, xF86XK_AudioNext)          "Next track"            $ spawn "playerctl next"
        , Bind (0, xF86XK_AudioRaiseVolume)   "Volume up"             $ spawn "pactl set-sink-volume 0 +5%"
        , Bind (0, xF86XK_AudioLowerVolume)   "Volume down"           $ spawn "pactl set-sink-volume 0 -5%"
        , Bind (0, xF86XK_AudioMute)          "Mute"                  $ spawn "pactl set-sink-mute 0 toggle"
        , Bind (0, xF86XK_MonBrightnessUp)    "Brightness up"         $ spawn "brightnessctl s +10%"
        , Bind (0, xF86XK_MonBrightnessDown)  "Brightness down"       $ spawn "brightnessctl s 10-%"
        , Bind (0,                  xK_Print ) "Screenshot to clipboard" $ spawn "~/.xmonad/bin/maimcopy"
        , Bind (modm,               xK_Print ) "Screenshot to file"   $ spawn "~/.xmonad/bin/maimsave"
        ])

    , ("SESSION",
        [ Bind (modm,               xK_b     ) "Toggle HUD"           toggleHud
        , Bind (modm,               xK_z     ) "Inhibit idle"         $ spawn "exec ~/.xmonad/bin/inhibit_activate"
        , Bind (modm .|. shiftMask, xK_z     ) "Allow idle"           $ spawn "exec ~/.xmonad/bin/inhibit_deactivate"
        , Bind (modm .|. shiftMask, xK_a     ) "Clipboard history"    $ spawn "exec ~/.xmonad/bin/clipboardy"
        , Bind (modm .|. shiftMask, xK_m     ) "Toggle portrait monitor" $ spawn "~/.xmonad/bin/toggle-portrait"
        , Bind (modm,               xK_q     ) "Restart xmonad"       $ spawn "xmonad --recompile 2> /tmp/xmonad-build.log && xmonad --restart || notify-send -u critical 'xmonad build failed' \"$(tail -20 /tmp/xmonad-build.log)\""
        , Bind (modm .|. shiftMask, xK_q     ) "Power menu"           $ spawn "~/.config/rofi/scripts/powermenu.sh type-3 style-5"
        , Bind (modm .|. shiftMask, xK_slash ) "Key bindings"         $ showKeyHelp modm (myBindings conf)
        ])
    ]

workspaceKeys conf@(XConfig {XMonad.modMask = modm}) =
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    [((m .|. modm, key), f def (PS.P sc))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(PS.viewScreen, 0), (PS.sendToScreen, shiftMask)]]

-- The JSON goes through a shell argument rather than a file so a stale cheat
-- sheet can never outlive the build that wrote it.
showKeyHelp :: KeyMask -> [(String, [Bind])] -> X ()
showKeyHelp modm groups =
    spawn $ "eww update keyhelp=" ++ shellQuote (keyHelpJson modm groups) ++ " && ~/.xmonad/bin/eww-toggle keyhelp"

-- Persistent so a Mod-q restart, which keeps the layouts' border state, keeps the flag too.
newtype HudHidden = HudHidden Bool deriving (Read, Show)

instance ExtensionClass HudHidden where
    initialValue  = HudHidden False
    extensionType = PersistentExtension

toggleHud :: X ()
toggleHud = do
    HudHidden hidden <- XS.get
    XS.put (HudHidden (not hidden))
    spawn $ if hidden
        then "~/.xmonad/bin/bartoggle show"
        else "~/.xmonad/bin/bartoggle hide; eww close sidebar dashboard keyhelp notifications;"
             ++ " eww update sidebar-open=false dashboard-open=false keyhelp-open=false"
    applyHud

-- Every workspace, not just the visible one, so switching while hidden keeps the full screen.
applyHud :: X ()
applyHud = do
    HudHidden hidden <- XS.get
    broadcastMessage (ModifyScreenBorderEnabled (const (not hidden)))
    refresh

showLayoutName :: X ()
showLayoutName = withWindowSet $ \ws ->
    spawn $ "notify-send Layout " ++ shellQuote (description . W.layout . W.workspace . W.current $ ws)

shellQuote :: String -> String
shellQuote s = "'" ++ concatMap (\c -> if c == '\'' then "'\\''" else [c]) s ++ "'"

keyHelpJson :: KeyMask -> [(String, [Bind])] -> String
keyHelpJson modm groups = obj [("columns", arr (map (arr . map section) (balance 3 groups)))]
  where
    section (title, bs) = obj [("title", str title), ("rows", arr (map row (concatMap (helpRows modm "") bs)))]
    row (k, d) = obj [("key", str k), ("desc", str d)]
    obj kvs = "{" ++ intercalate "," [str k ++ ":" ++ v | (k, v) <- kvs] ++ "}"
    arr vs = "[" ++ intercalate "," vs ++ "]"
    str s = "\"" ++ concatMap esc s ++ "\""
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc c    = [c]
    -- Contiguous split keeps the sections in reading order down each column.
    balance n gs = go gs
      where
        weight (_, bs) = 2 + length (concatMap (helpRows modm "") bs)
        target = (sum (map weight gs) + n - 1) `div` n
        go [] = []
        go xs = let (col, rest) = fill 0 xs in col : go rest
        fill _ [] = ([], [])
        fill acc (x:xs)
            | acc > 0 && acc + weight x > target = ([], x:xs)
            | otherwise = let (col, rest) = fill (acc + weight x) xs in (x:col, rest)

helpRows :: KeyMask -> String -> Bind -> [(String, String)]
helpRows modm prefix (Bind k d _) = [(prefix ++ keyLabel modm k, d)]
helpRows modm prefix (Sub k _ bs) = concatMap (helpRows modm (prefix ++ keyLabel modm k ++ " ")) bs
helpRows _    _      (Doc k d)    = [(k, d)]

keyLabel :: KeyMask -> (KeyMask, KeySym) -> String
keyLabel modm (mask, sym) = intercalate "-" (mods ++ [symLabel])
  where
    mods = [ "Mod" | modm /= 0, mask .&. modm == modm ] ++ [ "Shift" | mask .&. shiftMask /= 0 ]
    symLabel = M.findWithDefault (keysymToString sym) sym $ M.fromList
        [ (xK_slash, "/"), (xK_comma, ","), (xK_period, "."), (xK_grave, "`"), (xK_space, "Space")
        , (xF86XK_AudioPlay, "Play"), (xF86XK_AudioPrev, "Prev"), (xF86XK_AudioNext, "Next")
        , (xF86XK_AudioRaiseVolume, "Vol+"), (xF86XK_AudioLowerVolume, "Vol-"), (xF86XK_AudioMute, "Mute")
        , (xF86XK_MonBrightnessUp, "Bright+"), (xF86XK_MonBrightnessDown, "Bright-")
        ]


------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

-- scratch pads
scratchpads = [ music, slack, discord ]
  where
    music = NS "music" spawn find manage
      where

        spawn = "flatpak run io.github.Pithos"
        find = className =? "Pithos"
        manage = customFloating $ rectCentered 0.8

    slack = NS "slack"  spawn find manage
      where
        spawn = "slack"
        find = className=? "Slack"
        manage = customFloating $ rectCentered 0.8

    discord = NS "discord"  spawn find manage
      where
        spawn = "discord"
        find = className=? "discord"
        manage = customFloating $ rectCentered 0.8
--
------------------------------------------------------------------------
-- Layouts:

portraitLayout =
  named "Column" (Column 1) ||| named "ThreeRow" (Mirror (ThreeColMid nmaster delta ratio)) ||| Full
  where
     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 1/2

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

--
landscapeLayout =
  named "Tall" tiled ||| named "Wide" (Mirror tiled) ||| named "ThreeCol" (ThreeColMid nmaster delta ratio) ||| Full
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = ResizableTall nmaster delta ratio []

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 3/5

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100

named n = renamed [Replace n]

-- One vertical 4k monitor, 1 horizontal 4k monitor.
-- Spacing and gaps prefix the name, which Mod-i would show.
myLayout = renamed [KeepWordsRight 1] $
           gaps [(L,0), (R,0), (U,0), (D,0)] $
            spacingRaw True screenBorder True windowBorder True $
            smartBorders $
            avoidStruts $
            toggleLayouts Full $
            ifWider 3000 (landscapeLayout) portraitLayout
  where
    -- adds together with screenBorder for full spacing around layout
    -- this gives proper offsets with the trays
    screenGaps = [(L,30), (R,30), (U,40), (D,60)]

    -- top bottom right left
    windowBorder = Border 10 10 10 10
    screenBorder = Border 40 60 10 10

rectCentered :: Rational -> W.RationalRect
rectCentered percentage = W.RationalRect offset offset percentage percentage
  where
    offset = (1 - percentage) / 2

------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = namedScratchpadManageHook scratchpads <+> composeAll
    [ isInProperty "_NET_WM_WINDOW_TYPE" "_NET_WM_WINDOW_TYPE_POPUP_MENU" --> doIgnore
    , isInProperty "_NET_WM_WINDOW_TYPE" "_NET_WM_WINDOW_TYPE_MENU"       --> doIgnore
    , isDialog     --> doCenterFloat
    , isFullscreen --> doFullFloat
    -- The client is a steamwebhelper window with class "steam"; games are steam_app_<id>.
    , className =? "steam" --> doShift (myWorkspaces !! 1)
    ]

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
myLogHook = updatePointer (0.5, 0.5) (0, 0) >> nsSingleScratchpadPerWorkspace scratchpads

------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
myStartupHook = do
  spawnOnce "exec ~/.xmonad/bin/align-monitors.sh"
  spawnOnce "exec ~/.xmonad/bin/bartoggle show"
  spawnOnce "exec eww daemon"
  spawn "xsetroot -cursor_name left_ptr"
  spawnOnce "exec ~/.xmonad/bin/lock.sh"
  spawnOnce "exec ~/.xmonad/bin/wallpapers.sh"
  spawnOnce "picom -f"
  spawnOnce "greenclip daemon"
  spawnOnce "dunst"
  spawnOnce "exec -merge ~/.Xresources"
  spawnOnce "xscreensaver -no-splash"

------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
--
main = xmonad $ addAfterRescreenHook restartBars $ setRescreenWorkspacesHook (PS.rescreen def) $
    docks $ ewmhFullscreen $ ewmh defaults

-- The bars are sized to the screens they started on, so they restart with the outputs.
restartBars :: X ()
restartBars = do
    HudHidden hidden <- XS.get
    spawn $ (if hidden then "" else "pkill -x tint2; while pgrep -x tint2 >/dev/null; do sleep 0.1; done; ~/.xmonad/bin/bartoggle show; ")
         ++ "eww reload"

-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults = def {
      -- simple stuff
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,

      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,

      -- hooks, layouts
        manageHook = myManageHook,
        layoutHook = myLayout,
        handleEventHook    = windowedFullscreenFixEventHook,
        logHook            = myLogHook,
        startupHook        = myStartupHook
    }
