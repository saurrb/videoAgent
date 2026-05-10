#Requires AutoHotkey v2.0

if (A_Args.Length < 8) {
    ExitApp(2)
}

winTitle := A_Args[1]
promptFile := A_Args[2]
promptX := A_Args[3] + 0
promptY := A_Args[4] + 0
runX := A_Args[5] + 0
runY := A_Args[6] + 0
preDelayMs := A_Args[7] + 0
openHotkey := A_Args[8]
logPath := (A_Args.Length >= 9) ? A_Args[9] : ""
maxRuntimeMs := (A_Args.Length >= 10) ? (A_Args[10] + 0) : 15000

log(msg) {
    global logPath
    if (logPath = "")
        return
    FileAppend(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " " msg "`n", logPath, "UTF-8")
}

log("START")
log("ARGS winTitle=" winTitle " promptFile=" promptFile)
log("ARGS openHotkey=" openHotkey " maxRuntimeMs=" maxRuntimeMs)

if (maxRuntimeMs < 2000) {
    maxRuntimeMs := 2000
}
SetTimer(() => (log("ERR Watchdog timeout after " maxRuntimeMs "ms"), ExitApp(124)), -maxRuntimeMs)

if !FileExist(promptFile) {
    log("ERR Prompt file not found: " promptFile)
    ExitApp(3)
}

if !WinExist(winTitle) {
    log("ERR Window not found: " winTitle)
    ExitApp(4)
}

WinActivate(winTitle)
log("WinActivate sent")
if !WinWaitActive(winTitle, , 3) {
    log("ERR Could not activate window: " winTitle)
    ExitApp(5)
}
log("Window active")

Sleep(preDelayMs)
log("After preDelay")

; Optional hotkey to open side panel if the user configured one (example: !+g).
if (openHotkey != "" && openHotkey != "-") {
    ; Guard against argument-shift accidents or invalid send specs.
    if (InStr(openHotkey, ":\") || StrLen(openHotkey) > 40) {
        log("WARN Skipping suspicious openHotkey value: " openHotkey)
    } else {
        try {
            Send(openHotkey)
            Sleep(500)
            log("Open hotkey sent")
        } catch Error as ex {
            log("WARN openHotkey send failed: " ex.Message)
        }
    }
}

WinGetPos(&wx, &wy, &ww, &wh, winTitle)
log("Window pos w=" ww " h=" wh)
if (ww <= 0 || wh <= 0) {
    log("ERR Could not read window geometry.")
    ExitApp(6)
}

inputText := FileRead(promptFile, "UTF-8")
log("Prompt read chars=" StrLen(inputText))
A_Clipboard := ""
A_Clipboard := inputText
if !ClipWait(1) {
    log("ERR Clipboard did not update in time")
    ExitApp(7)
}
log("Clipboard set")

CoordMode("Mouse", "Screen")
Click(wx + promptX, wy + promptY)
Sleep(120)
log("Prompt click")
Send("^a")
Sleep(80)
Send("{Delete}")
Sleep(80)
Send("^v")
Sleep(120)
log("Prompt pasted")

Click(wx + runX, wy + runY)
Sleep(120)
log("Run clicked")

log("OK Submitted prompt")
ExitApp(0)
