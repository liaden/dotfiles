import XMonad
import XMonad.Config.Gnome

myManageHook = composeAll (
    [ manageHook gnomeConfig
    , className =? "Unity-2d-launcher" --> doFloat
    , className =? "Unity-2d-panel" --> doIgnore
    ])

main = xmonad gnomeConfig { manageHook = myManageHook, modMask = mod4Mask }
