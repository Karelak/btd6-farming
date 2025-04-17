; /////////////////////////////////// Script for Bloons Tower Defense 6

; ============================== Setup
#NoEnv
#SingleInstance force
#MaxThreadsPerHotkey 1
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode 2

; ------------------------- State Constants
STATE_MENU_NAV := 1
STATE_IN_GAME := 2
STATE_POST_GAME_VICTORY := 3
STATE_POST_GAME_DEFEAT := 4
STATE_WAIT_HOME := 5

; ------------------------- Variables
isScriptRunning := false
isMenuGuiOpen := false
currentScriptState := STATE_MENU_NAV ; Start with menu navigation

windowOffsetX := 0
windowOffsetY := 0
gameClientWidth := 1920
gameClientHeight := 1080
isFullscreen := false

completedGamesCount := 0
levelUpsCount := 0
totalRuntimeSeconds := 0
currentRunStartTime := 0
currentRunEndTime := 0

selectedTargetMonkey := "dart"
selectedStrategy := "heli"
isTargetMonkeyWaterBased := false ; Will be set later based on selectedTargetMonkey

monkeyHotkeys := {"dart": "q"
    , "boomerang": "w"
    , "bomb": "e"
    , "tack": "r"
    , "ice": "t"
    , "glue": "y"
    , "sniper": "z"
    , "sub": "x"
    , "buccaneer": "c"
    , "ace": "v"
    , "heli": "b"
    , "mortar": "n"
    , "dartling": "m"
    , "wizard": "a"
    , "super": "s"
    , "ninja": "d"
    , "alchemist": "f"
    , "druid": "g"
    , "mermonkey": "o"
    , "farm": "h"
    , "engineer": "l"
    , "spike": "j"
    , "village": "k"
    , "handler": "i"
    , "hero": "u"}

baseActionDelayMs := 150
actionDelayMs := baseActionDelayMs
baseScreenTransitionDelayMs := 500
screenTransitionDelayMs := baseScreenTransitionDelayMs
useExtraDelay := false
scriptWindowTitle := "Bloons Tower Defense 6 Farming"
gameWindowTitle := "BloonsTD6"

; ------------------------- Hotkeys
Hotkey, IfWinActive, %gameWindowTitle%
Hotkey, ^m, menuHandler ; Renamed label
Hotkey, ^s, startFarming ; Renamed label
Hotkey, ^d, debugHandler, Off ; Renamed label

; ============================== Functions
; Startup message
MsgBox, , %scriptWindowTitle%, %A_ScriptName% started... Ctrl+M for menu, 5
SetTimer, checkGameWindowActive, 500 ; Renamed label
return

; Pause main loop
stopFarming: ; Renamed label
if (isScriptRunning) {
    currentRunEndTime := A_TickCount
    totalRuntimeSeconds := totalRuntimeSeconds + (currentRunEndTime - currentRunStartTime) / 1000
    updateTooltip("Functions stopped.")
}
isScriptRunning := false
return

; Adjust coordinates based on windowed/fullscreen mode
updateScreenCoordinates: ; Renamed label
WinGetPos, , , currentWidth, currentHeight, %gameWindowTitle%
remainder := Mod(currentHeight, 10)
if (remainder = 0 || remainder = 4 || remainder = 8) { ; Heuristic for fullscreen
    windowOffsetX := 0
    windowOffsetY := 0
    gameClientWidth := currentWidth
    gameClientHeight := currentHeight
    isFullscreen := true
} else { ; Assume windowed with title bar/borders
    windowOffsetX := 9
    windowOffsetY := 38
    gameClientWidth := currentWidth - 18
    gameClientHeight := currentHeight - 47
    isFullscreen := false
}
return

; Show status message in top corner
updateTooltip(message, timeoutMs := 2000) {
    global gameStatusMessage, statusUpdateTime
    
    ; Update status variables for potential persistent display
    gameStatusMessage := message
    statusUpdateTime := A_TickCount
    
    ; Format the tooltip with timing information if it's a major state change
    formattedMessage := message
    
    ; Display the tooltip
    Tooltip, % formattedMessage, 50, 50
    SetTimer, removeTooltip, -%timeoutMs%
    return
}

removeTooltip:
Tooltip
return

; Click at location, normalised with delay added
clickAt(x, y) {
    global actionDelayMs
    global windowOffsetX
    global windowOffsetY
    global gameClientWidth
    global gameClientHeight
    scaledX := (x * gameClientWidth // 1920) + windowOffsetX
    scaledY := (y * gameClientHeight // 1080) + windowOffsetY
    Click, %scaledX% %scaledY%
    Sleep actionDelayMs
    return
}

; Get colour at location, normalised
getColorAt(x, y) { ; Renamed function
    global windowOffsetX
    global windowOffsetY
    global gameClientWidth
    global gameClientHeight
    scaledX := (x * gameClientWidth // 1920) + windowOffsetX
    scaledY := (y * gameClientHeight // 1080) + windowOffsetY
    PixelGetColor, pixelColor, scaledX, scaledY ; Renamed variable
    return pixelColor
}

; Check for colour equivalence under threshold
isNearColor(testColor, targetColor, tolerance := 10) { ; Renamed function and parameters
    testBlue := format("{:d}", "0x" . substr(testColor,3,2))
    testGreen := format("{:d}", "0x" . substr(testColor,5,2))
    testRed := format("{:d}", "0x" . substr(testColor,7,2))
    targetBlue := format("{:d}", "0x" . substr(targetColor,3,2))
    targetGreen := format("{:d}", "0x" . substr(targetColor,5,2))
    targetRed := format("{:d}", "0x" . substr(targetColor,7,2))
    distance := sqrt((targetBlue-testBlue)**2+(targetGreen-testGreen)**2+(targetRed-targetRed)**2)
    return (distance < tolerance)
}

; Press key, with delay added
pressKey(key:=false) { ; Renamed function
    global monkeyHotkeys
    global selectedTargetMonkey
    global actionDelayMs
    if (!key) {
        key := monkeyHotkeys[selectedTargetMonkey]
    }
    SendInput %key%
    Sleep actionDelayMs
    return
}

; Press keys in sequence, with delay added
pressKeyStream(keys) { ; Renamed function
    for index, keyChar in StrSplit(keys) ; Improved loop
        pressKey(keyChar)
    return
}

debugHandler: ; Renamed label
Gui, Debug:New,, Variables snapshot
Gui, Font, s10, Courier
Gui, Add, Text,, isScriptRunning: %isScriptRunning%
Gui, Add, Text,, currentScriptState: %currentScriptState%
Gui, Add, Text,, actionDelayMs: %actionDelayMs%
Gui, Add, Text,, screenTransitionDelayMs: %screenTransitionDelayMs%
Gui, Add, Text,, isMenuGuiOpen: %isMenuGuiOpen%
Gui, Debug:Show
return


; ------------------------- Menu
; Options and information window
menuHandler: ; Renamed label
isMenuGuiOpen := true
; calculate needed information
Gosub updateScreenCoordinates
scriptStatusText := isScriptRunning ? "On" : "Off"
fullscreenStatusText := isFullscreen ? "Yes" : "No"
estimatedXpEarned := 57000 * completedGamesCount
estimatedMoneyEarned := 66 * completedGamesCount
currentRuntime := totalRuntimeSeconds
if (isScriptRunning) {
    currentRuntime := totalRuntimeSeconds + (A_TickCount - currentRunStartTime) / 1000
}
totalMinutes := Floor(currentRuntime / 60)
remainingSeconds := Mod(currentRuntime, 60)
formattedRuntime := totalMinutes . "min " . Round(remainingSeconds, 1) . "s"
; create menu
Gui, BTDF:New,, %scriptWindowTitle%
Gui, Font, s10, Courier
Gui, Add, Tab3,, Control|Tracking|Help|
Gui, Tab, 1 ; Control
Gui, Add, GroupBox, Section w200 h170, Options
Gui, Add, Text, xp+10 yp+18, Target Monkey:
Gui, Add, DropDownList, vSelectedTargetMonkey, Dart|Boomerang|Bomb|Tack|Ice|Glue|Sniper|Sub|Buccaneer|Ace|Mortar|Dartling|Wizard|Super|Ninja|Alchemist|Druid|Mermonkey|Spike|Village|Engineer|Handler
GuiControl, ChooseString, SelectedTargetMonkey, %selectedTargetMonkey%
Gui, Add, Text,, Strategy:
Gui, Add, DropDownList, vSelectedStrategy, Heli|Sniper
GuiControl, ChooseString, SelectedStrategy, %selectedStrategy%
Gui, Add, CheckBox, Checked%useExtraDelay% vUseExtraDelay, Extra Delay
Gui, Add, Button, gSaveButton xp ym+220 Default w80, &Save
Gui, Add, Button, gExitButton x+m yp w80, E&xit
Gui, Tab, 2 ; Tracking
Gui, Add, Text,, Window Size : %gameClientWidth%x%gameClientHeight%
Gui, Add, Text, y+m, Fullscreen : %fullscreenStatusText%
Gui, Add, Text,, Games Played : %completedGamesCount%
Gui, Add, Text, y+m, Runtime : %formattedRuntime%
Gui, Add, Text, y+m, XP Estimate : %estimatedXpEarned%
Gui, Add, Text, y+m, Level Ups : %levelUpsCount%
Gui, Add, Text, y+m, Money Estimate : %estimatedMoneyEarned%
Gui, Tab, 3 ; Help
Gui, Add, Text,, Ctrl+M : This menu
Gui, Add, Text, y+m, Ctrl+S : Start (when menu closed)
Gui, Add, Text, y+m, Ctrl+X : Stop (when running) or `n`texit script
Gui, Add, Text,, 'Save' closes GUI and keeps `nchanges, 'X' closes without `nchanges, and 'Exit' ends script
Gui, Add, Text,, All Strategies require Infernal `nDeflation unlocked
Gui, Add, Link, cgray, Detailed instructions on <a href="https://github.com/gavboi/btd6-farming">github</a>
Gui, Show
return

; Update variables based on menu settings
SaveButton:
Gui, Submit
actionDelayMs := baseActionDelayMs * (1 + useExtraDelay)
screenTransitionDelayMs := baseScreenTransitionDelayMs * (1 + useExtraDelay)
BTDFGuiClose:
Gui, BTDF:Destroy
; Update water monkey flag based on selection
if (selectedTargetMonkey = "sub" or selectedTargetMonkey = "buccaneer") {
    isTargetMonkeyWaterBased := true
} else {
    isTargetMonkeyWaterBased := false
}
isMenuGuiOpen := false
Sleep 250
if (scriptStatusText="On") { ; Check the status *before* the menu opened
    updateTooltip("Functions resumed.")
    Gosub startFarming
}
return

; ------------------------- Exit
; Stop script, or close script if already stopped
^x::
ExitButton:
if isScriptRunning {
    Hotkey, ^m, On ; Re-enable menu hotkey if script was running
    currentScriptState := STATE_MENU_NAV ; Reset state
    Gosub stopFarming
} else {
    MsgBox, 17, %scriptWindowTitle%, Exit %A_ScriptName%?,
    IfMsgBox, OK
        ExitApp
    MsgBox, , %scriptWindowTitle%, Script continuing..., 1
}
return

; ------------------------- Disable on unactive
; Stop script to avoid click checks if game/menu isn't active
checkGameWindowActive: ; Renamed label
if (!WinActive(gameWindowTitle)) {
    Gosub stopFarming
}
return

; ------------------------- Start farming
; Main loop
startFarming: ; Renamed label
Gosub updateScreenCoordinates
isScriptRunning := true
currentRunStartTime := A_TickCount
while (isScriptRunning) {

    if (currentScriptState = STATE_MENU_NAV) {
        Hotkey, ^m, Off ; Disable menu hotkey during automation
        updateTooltip("Navigating menus: Play -> Expert -> Infernal -> Easy -> Deflation")
        clickAt(953, 983)                        ; click play
        Sleep screenTransitionDelayMs
        clickAt(1340, 975)                    ; click expert maps
        Sleep screenTransitionDelayMs
        clickAt(1460, 580)                    ; click infernal
        Sleep screenTransitionDelayMs
        clickAt(625, 400)                        ; click easy
        Sleep screenTransitionDelayMs
        clickAt(1290, 445)                    ; click deflation
        Sleep screenTransitionDelayMs
        clickAt(1100, 720)                    ; try and click overwrite save (if present)

        ; Wait for map to load (check for green start button)
        mapLoadStartTime := A_TickCount
        mapLoaded := false
        while (isScriptRunning and !mapLoaded and (A_TickCount - mapLoadStartTime < 10000)) { ; 10 sec timeout
            updateTooltip("Waiting for map load (Infernal)...")
            startButtonColor := getColorAt(1020, 760)
            if (isNearColor(startButtonColor, 0x00e15d)) { ; Green color BGR
                mapLoaded := true
            } else {
                Sleep actionDelayMs
            }
        }

        if (!mapLoaded) {
             updateTooltip("Map load timed out! Stopping.")
             Gosub stopFarming ; Stop if map doesn't load
             continue ; Skip rest of loop iteration
        }

        ; Place Towers
        clickAt(1020, 760)                    ; click start button
        clickAt(10, 10)                       ; Click away to ensure nothing selected
        Sleep 2*screenTransitionDelayMs
        updateTooltip("Placing towers (" . selectedStrategy . " strategy)...")

        if (selectedStrategy="Heli") {
            pressKey("b")                            ; place heli 1
            clickAt(1560, 575)
            clickAt(1560, 575)
            pressKeyStream(",,,..")                ; Upgrades 003, 002
            clickAt(0, 0)                          ; Click away
            pressKey("z")                             ; place sniper
            clickAt(835, 330)
            clickAt(835, 330)
            pressKeyStream(",,////")               ; Upgrades 024
            pressKey("{Tab}")                      ; Target Strong
            pressKey("{Tab}")
            pressKey("{Tab}")
            clickAt(0, 0)                          ; Click away
            pressKey("b")                            ; place heli 2
            clickAt(110, 575)
            clickAt(110, 575)
            pressKeyStream(",,,..")                ; Upgrades 003, 002
            clickAt(0, 0)                          ; Click away
            pressKey()                             ; place target monkey (hotkey from variable)
            if (isTargetMonkeyWaterBased) {
                clickAt(482, 867)                  ; Water placement
                clickAt(482, 867)
            } else {
                clickAt(835, 745)                  ; Land placement
                clickAt(835, 745)
            }
        }
        else if (selectedStrategy="Sniper") {
            pressKey("k")                          ; place village
            clickAt(1575, 500)
            clickAt(1575, 500)
            pressKeyStream(",,//")                 ; Upgrades 002
            clickAt(0, 0)                          ; Click away
            pressKey("z")                          ; place sniper
            clickAt(1550, 585)
            clickAt(1550, 585)
            pressKeyStream("..////")               ; Upgrades 204
            clickAt(0, 0)                          ; Click away
            pressKey("f")                          ; place alchemist
            clickAt(1575, 650)
            clickAt(1575, 650)
            pressKeyStream(",,,/")                 ; Upgrades 301
            clickAt(0, 0)                          ; Click away
            pressKey()                             ; place target monkey (hotkey from variable)
            if (isTargetMonkeyWaterBased) {
                clickAt(482, 867)                  ; Water placement
                clickAt(482, 867)
            } else {
                clickAt(110, 560)                  ; Land placement
                clickAt(110, 560)
            }
        }

        ; Upgrade target monkey (assuming it's the last placed)
        updateTooltip("Upgrading target monkey (" . selectedTargetMonkey . ")...")
        pressKeyStream(",./,./,./,./,./,./") ; Example: 6 upgrades (adjust as needed)
        Sleep screenTransitionDelayMs

        ; Check if the upgrade screen is open and close it
        upgradePanelColor := getColorAt(1134, 68)
        if (isNearColor(upgradePanelColor, 0x548CB9)) { ; Check for brown panel color (B98C54 RGB -> 548CB9 BGR)
             clickAt(84, 94) ; close upgrade screen
        }

        clickAt(30, 0)                         ; Click away
        updateTooltip("Starting round...")
        pressKey("{Space}")                    ; start round
        pressKey("{Space}")                    ; speed up
        currentScriptState := STATE_IN_GAME    ; Move to in-game state
        Hotkey, ^m, On                         ; Re-enable menu hotkey
    }

    else if (currentScriptState = STATE_IN_GAME) {
        baseTooltip := "Round in progress... Waiting for Victory/Defeat"
        updateTooltip(baseTooltip)
        isWaitingForGameStateChange := true

        while (isWaitingForGameStateChange and isScriptRunning and !isMenuGuiOpen) {
            ; Check for Victory first
            victoryNextButtonColor := getColorAt(1030, 900)
            if (isNearColor(victoryNextButtonColor, 0x00e76e)) { ; Green next button (6EE700 RGB -> 00E76E BGR)
                updateTooltip("Victory detected!")
                currentScriptState := STATE_POST_GAME_VICTORY
                isWaitingForGameStateChange := false
                break ; Exit inner while loop
            }

            ; Check for Defeat
            defeatRestartButtonColor := getColorAt(926, 771)
            if (isNearColor(defeatRestartButtonColor, 0x00ddff)) { ; Light blue restart button (FFDD00 RGB -> 00DDFF BGR)
                updateTooltip("Defeat detected!")
                currentScriptState := STATE_POST_GAME_DEFEAT
                isWaitingForGameStateChange := false
                break ; Exit inner while loop
            }

            ; REMOVE THIS OLD LEVEL UP CHECK BLOCK (Lines 435-445 approx)
            ; levelUpColor1 := getColorAt(967, 375)       ; Blueish
            ; levelUpColor2 := getColorAt(134, 846)       ; Brownish
            ; levelUpColor3 := getColorAt(820, 587)       ; White
            ; if (isNearColor(levelUpColor1, 0xDFCE06) or isNearColor(levelUpColor2, 0x2151A3) or isNearColor(levelUpColor3, 0xFFFFFF)) {
            ;     ; Level up detected - dismiss popups but stay in STATE_IN_GAME
            ;     Hotkey, ^m, Off ; Temporarily disable menu during clicks
            ;     updateTooltip("Level Up detected! Dismissing popups...")
            ;     clickAt(30, 30)                 ; Click away for level number popup
            ;     Sleep screenTransitionDelayMs
            ;     clickAt(30, 30)                 ; Click away for knowledge popup
            ;     levelUpsCount := levelUpsCount + 1
            ;     Hotkey, ^m, On ; Re-enable menu
            ;     updateTooltip(baseTooltip) ; Restore original tooltip after dismissing
            ;     ; Don't set isWaitingForGameStateChange to false, continue checking for win/loss
            ; }

            ; KEEP THIS NEW LEVEL UP CHECK BLOCK
            ; Check for Level Up (can happen mid-round) - Requires all points to match
            levelUpCheck1 := getColorAt(124, 1014) ; White text/element
            levelUpCheck2 := getColorAt(142, 921) ; Brownish banner element
            levelUpCheck3 := getColorAt(239, 827) ; Yellowish banner element
            levelUpCheck4 := getColorAt(958, 495) ; Blueish popup background

            ; Store results of color checks in intermediate variables
            isColor1Match := isNearColor(levelUpCheck1, 0xFFFFFF)  ; White (FFFFFF RGB -> FFFFFF BGR)
            isColor2Match := isNearColor(levelUpCheck2, 0x2152A4)  ; Brownish (A45221 RGB -> 2152A4 BGR)
            isColor3Match := isNearColor(levelUpCheck3, 0x1DD0FF)  ; Yellowish (FFD01D RGB -> 1DD0FF BGR)
            isColor4Match := isNearColor(levelUpCheck4, 0xE0CE00)  ; Blueish (00CEE0 RGB -> E0CE00 BGR)

            if (isColor1Match and isColor2Match and isColor3Match and isColor4Match)
            {
                ; Level up detected - dismiss popups but stay in STATE_IN_GAME
                Hotkey, ^m, Off ; Temporarily disable menu during clicks
                updateTooltip("Level Up detected! Dismissing popups...")
                clickAt(30, 30)                 ; Click away for level number popup
                Sleep screenTransitionDelayMs
                clickAt(30, 30)                 ; Click away for knowledge popup
                levelUpsCount := levelUpsCount + 1
                Hotkey, ^m, On ; Re-enable menu
                updateTooltip(baseTooltip) ; Restore original tooltip after dismissing
                ; Don't set isWaitingForGameStateChange to false, continue checking for win/loss
            }

            Sleep actionDelayMs ; Wait a bit before checking again
        }
        ; If the loop exited because isScriptRunning became false or menu opened, the outer loop will handle it.
    }

    else if (currentScriptState = STATE_POST_GAME_VICTORY) {
        Hotkey, ^m, Off ; Disable menu hotkey during automation
        updateTooltip("Processing Victory: Clicking Next -> Home")
        clickAt(1030, 900)             ; Click Next button
        Sleep screenTransitionDelayMs
        clickAt(700, 800)              ; Click Home button
        completedGamesCount := completedGamesCount + 1
        currentScriptState := STATE_WAIT_HOME ; Move to wait for home screen state
        Hotkey, ^m, On ; Re-enable menu hotkey
    }

    else if (currentScriptState = STATE_POST_GAME_DEFEAT) {
        Hotkey, ^m, Off ; Disable menu hotkey during automation
        updateTooltip("Processing Defeat: Clicking Home")
        ; No 'Next' button on defeat, just click Home
        clickAt(700, 800)              ; Click Home button
        ; Maybe add a small delay or check if home was clicked successfully?
        Sleep 2 * screenTransitionDelayMs ; Increased delay to allow menu transition
        currentScriptState := STATE_WAIT_HOME ; Move to wait for home screen state
        Hotkey, ^m, On ; Re-enable menu hotkey
    }

     else if (currentScriptState = STATE_WAIT_HOME) {
        updateTooltip("Returning to Main Menu...")
        homeScreenWaitStartTime := A_TickCount
        homeScreenLoaded := false
        playButtonVisible := false
        while (!homeScreenLoaded and isScriptRunning and !isMenuGuiOpen and (A_TickCount - homeScreenWaitStartTime < 5000)) { ; 5 sec timeout
            ; Check only for the specific Play button color
            playButtonColor := getColorAt(965, 899) ; Check for Play button green

            if (isNearColor(playButtonColor, 0x00F066)) { ; (66F000 RGB -> 00F066 BGR)
                homeScreenLoaded := true
            } else {
                Sleep actionDelayMs
            }
        }

        if (homeScreenLoaded) {
            updateTooltip("Main Menu loaded. Starting next cycle.")
            currentScriptState := STATE_MENU_NAV ; Go back to start the next cycle
        } else {
            updateTooltip("Failed to detect Main Menu/Play Button, stopping.")
            ; Consider alternative recovery? For now, just stop.
            ; Maybe try clicking home again? currentScriptState := STATE_POST_GAME_DEFEAT;
            Gosub stopFarming
        }
    }

    ; Add a small sleep in the main loop if needed, though sleeps exist within states
    ; Sleep 10
}

; Script ends or was stopped
updateTooltip("Script stopped.")
Hotkey, ^m, On ; Ensure menu hotkey is on when script isn't running
return

; --- End of Script ---