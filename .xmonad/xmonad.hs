 
--
-- xmonad example config file for xmonad-0.9
--
-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.
--
-- Normally, you'd only override those defaults you care about.
--
-- NOTE: Those updating from earlier xmonad versions, who use
-- EwmhDesktops, safeSpawn, WindowGo, or the simple-status-bar
-- setup functions (dzen, xmobar) probably need to change
-- xmonad.hs, please see the notes below, or the following
-- link for more details:
--
-- http://www.haskell.org/haskellwiki/Xmonad/Notable_changes_since_0.8
--
 
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Actions.WindowBringer
import XMonad.Actions.RotSlaves
import XMonad.Layout.Grid
import XMonad.Layout.Tabbed
import XMonad.Layout.NoBorders
import XMonad.Layout.IM
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Reflect
import XMonad.Layout.LayoutHints
import XMonad.Util.Paste
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Master
import XMonad.Util.Scratchpad
import XMonad.Hooks.EwmhDesktops
import XMonad.Config.Gnome

import Data.Monoid
import Data.Ratio ((%))
import System.Exit
 
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import qualified XMonad.Prompt         as Prompt
import qualified XMonad.Prompt.Ssh as SSH
import qualified XMonad.Prompt.Shell as Shell
import qualified XMonad.Util.Themes as Theme
 
 
-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal      = "gnome-terminal"
 
-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False
 
-- defaultXPConfig =
--     XPC { font              = "-misc-fixed-*-*-*-*-12-*-*-*-*-*-*-*"
--         , bgColor           = "grey22"
--         , fgColor           = "grey80"
--         , fgHLight          = "black"
--         , bgHLight          = "grey"
--         , borderColor       = "white"
--         , promptBorderWidth = 1
--         , promptKeymap      = defaultXPKeymap
--         , completionKey     = xK_Tab
--         , position          = Bottom
--         , height            = 18
--         , historySize       = 256
--         , historyFilter     = id
--         , defaultText       = []
--         , autoComplete      = Nothing
--         , showCompletionOnTab = False }
myXPConfig = Prompt.defaultXPConfig { Prompt.position = Prompt.Top}
 
 
-- Width of the window border in pixels.
--
myBorderWidth   = 4
 
-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask       = mod4Mask
 
-- NOTE: from 0.9.1 on numlock mask is set automatically. This setting
-- should be removed from configs.
--
-- The mask for the numlock key. Numlock status is "masked" from the
-- current modifier status, so the keybindings will work with numlock on or
-- off. You may need to change this on some systems.
--
-- You can find the numlock modifier by running "xmodmap" and looking for a
-- modifier with Num_Lock bound to it:
--
-- > $ xmodmap | grep Num
-- > mod2        Num_Lock (0x4d)
--
-- Set numlockMask = 0 if you don't have a numlock key, or want to treat
-- numlock status separately.
--
-- myNumlockMask   = mod2Mask -- deprecated in xmonad-0.9.1
 
 
-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
-- myWorkspaces    = ["1","2","3","4","5","6","7","8","9"]
numberOfWorkSpaces = 9
myWorkspaces = ["1:vim", "2:web", "3:chat","4:mail" , "5:gimp"] ++ map show [6..numberOfWorkSpaces] 
 
-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#222222"
myFocusedBorderColor = "#4682b4"
 
 
k_XF86AudioLowerVolume = 0x1008FF11
k_XF86AudioMute = 0x1008FF12
k_XF86AudioRaiseVolume = 0x1008FF13
k_XF86AudioPlay = 0x1008FF14
k_XF86AudioStop = 0x1008FF15
k_XF86AudioPrev = 0x1008FF16
k_XF86AudioNext = 0x1008FF17
k_XF86Tools = 0x1008FF81
------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
 
    -- launch a terminal
    [ 
 
     ((modm .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf)
                                     
    -- launch gmrun
    , ((modm .|. shiftMask, xK_p     ), spawn "gmrun")
 
    -- close focused window
    , ((modm .|. shiftMask, xK_c     ), kill)
 
     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)
 
    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)
 
    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)
 
    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)
 
    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)
 
    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )
 
    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )
 
    -- Swap the focused window and the master window
    , ((modm,               xK_Return), windows W.swapMaster)
 
    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )
 
    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )
 
    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)
 
    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)
 
    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)
 
    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))
 
    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))
 
    -- Shell Prompt  (replaces dmenu)
    , ((modm,               xK_p     ), Shell.shellPrompt myXPConfig)
 
    -- Window Bringer, go to the workspace with that window
    , ((modm .|. shiftMask, xK_g     ), gotoMenu)
 
    -- File Manager
    , ((modm,               xK_o     ), spawn "thunar")
 
    -- SSH
    , ((modm .|. shiftMask, xK_s), SSH.sshPrompt myXPConfig)
 
    -- Capture Current Window
    , ((mod1Mask,xK_Print ), spawn "scrot --focused -e 'mv $f /tmp'")
 
    -- Capture entire screen
    , ((0,xK_Print ), spawn "scrot -e 'mv $f /tmp'")
 
    , ((modm              , xK_grave     ), scratchpadSpawnActionTerminal " urxvt +scrollBar -fg white -bg black -fn \"xft:Bitstream Vera Sans Mono:pixelsize:14\"")
 
     -- Control EMMS
     , ((0,k_XF86AudioLowerVolume), spawn " emacsclient -e '(emms-volume-lower)'")
     , ((0,k_XF86AudioRaiseVolume), spawn " emacsclient -e '(emms-volume-raise)'")
 
     , ((0,k_XF86AudioMute), spawn " emacsclient -e '(emms-pause)'")
     , ((0,k_XF86AudioPlay), spawn " emacsclient -e '(emms-play)'")
     , ((0,k_XF86AudioStop), spawn " emacsclient -e '(emms-stop)'")
 
     , ((0,k_XF86AudioNext), spawn " emacsclient -e '(emms-next)'")
     , ((0,k_XF86AudioPrev), spawn " emacsclient -e '(emms-previous)'")
 
     , ((0,k_XF86Tools), spawn " emacsclient -e '(emms)'")
 
    -- Lock Screen
    , ((modm .|. shiftMask, xK_l     ),    spawn "xscreensaver-command -l")
 
 
    -- Rotate slave windows
    , ((modm .|. shiftMask, xK_Tab   ), rotSlavesUp)
 
 
    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    --
    -- , ((modm              , xK_b     ), sendMessage ToggleStruts)
 
    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))
 
    -- Restart xmonad
    , ((modm              , xK_q     ), spawn "xmonad --recompile; xmonad  --restart")
    ]
    ++
 
    --
    -- mod-[1..9], Switch to workspace N
    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
 
    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
 
 
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
 
------------------------------------------------------------------------
-- Layouts:
 
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- * NOTE: XMonad.Hooks.EwmhDesktops users must remove the obsolete
-- ewmhDesktopsLayout modifier from layoutHook. It no longer exists.
-- Instead use the 'ewmh' function from that module to modify your
-- defaultConfig as a whole. (See also logHook, handleEventHook, and
-- startupHook ewmh notes.)
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--

imLayout =  layoutHintsToCenter $ reflectHoriz $ withIM (0.15) (ClassName "Pidgin" `And` Role "buddy_list") (Grid ||| Full)
gimpLayout = layoutHintsToCenter $ withIM (0.11) (Role "gimp-toolbox") $ reflectHoriz $ withIM (0.15) (Role "gimp-dock") (Full ||| Grid)

myLayout = onWorkspace "3:chat" imLayout $ 
           onWorkspace "5:gimp" gimpLayout $
           layoutHintsToCenter ( tiled ||| tabbed shrinkText (Theme.theme Theme.donaldTheme) ||| Grid )
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled   = Tall nmaster delta ratio
              
    mgrid = mastered delta ratio $ Grid
 
    -- The default number of windows in the master pane
    nmaster = 1
 
    -- Default proportion of screen occupied by master pane
    ratio   = 2/3
 
    -- Percent of screen to increment by when resizing panes
    delta   = 3/100
 
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
myManageHook = composeAll
    [ manageHook gnomeConfig
    , className =? "MPlayer"        --> doFloat
    , className =? "Gimp"           --> doShift "5:gimp"
    , title =? "Ediff"           --> doFloat
    , className =? "Firefox" --> doShift "2:web"
    , className =? "Google-chrome" --> doShift "2:web"
    , className =? "Evolution" --> doShift "4:mail" 
    , className =? "Pidgin" --> doShift "3:chat"
    , className =? "Rhythmbox" --> doShift "3:chat"
    , (className =? "Firefox" <&&> resource =? "Dialog") --> doFloat
    , (className =? "Firefox" <&&> title =? "Downloads") --> doHideIgnore
    , (className =? "Evolution" <&&> title =? "Send & Receive Mail") --> doCenterFloat
    , (className =? "Evolution" <&&> title =? "Print") --> doCenterFloat
    , (className =? "sun-awt-X11-XFramePeer") --> doCenterFloat
    , (className =? "java-lang-Thread") --> doCenterFloat
    , resource  =? "desktop_window" --> doIgnore  
    , scratchpadManageHook (W.RationalRect 0.1 0.3 0.8 0.5)
    ]
 
------------------------------------------------------------------------
-- Event handling
 
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.
-- It will add EWMH event handling to your custom event hooks by
-- combining them with ewmhDesktopsEventHook.
--
myEventHook = mempty
 
------------------------------------------------------------------------
-- Status bars and logging
 
-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.
-- It will add EWMH logHook actions to your custom log hook by
-- combining it with ewmhDesktopsLogHook.
--
myLogHook = return ()
 
------------------------------------------------------------------------
-- Startup hook
 
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.
-- It will add initialization of EWMH support to your custom startup
-- hook by combining it with ewmhDesktopsStartup.
--
myStartupHook = return ()
 
------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.
 
-- Run xmonad with the settings you specify. No need to modify this.
--
main = xmonad . withUrgencyHook NoUrgencyHook =<<  xmobar defaults 
 
 
 
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs (changed to gnomeConfig at Aegis)
--
-- No need to modify this.
--
defaults = gnomeConfig {
      -- simple stuff
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        -- numlockMask deprecated in 0.9.1
        -- numlockMask        = myNumlockMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,
 
      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,
 
      -- hooks, layouts
        layoutHook         = myLayout,
        manageHook         = myManageHook,
        handleEventHook    = myEventHook,
        logHook            = myLogHook,
        startupHook        = myStartupHook
    }
