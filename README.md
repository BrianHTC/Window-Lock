# Window-Lock

Window-Lock is a PowerShell tool for controlling a window on Windows. It can block the selected window from mouse and keyboard input, 
adjust its opacity, and keep it always on top, so that your operation on other apps doesn't affect the locked window. 

The controller stays above the locked window so you can unlock it or change its opacity at any time.

![image](https://github.com/BrianHTC/Window-Lock/blob/main/PANEL.png)
![image](https://github.com/BrianHTC/Window-Lock/blob/main/GAMEPLAY1.png)

## Features

- Lists visible windows with their process IDs
- Locks a selected window
- Disables keyboard interaction with the locked window
- Makes mouse input pass through the locked window
- Automatically sets the locked window to always on top,and made sure the controller panel shows up above the locked window,
  so that you can adjust normally. 
- Adjusts window opacity from 10% to 100%
- Unlocks the window without closing it
- Detects when the target window is closed
- Restores the target window when the controller exits normally

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or a compatible PowerShell environment
- Permission to modify the selected window
- Run-WindowLock.bat must be in the same folder with WindowLock.ps1

If the target application is running as administrator, run Window-Lock as administrator as well.

## Files

```text
WindowLock.ps1
Run-WindowLock.bat     Optional launcher
README.md
```

The PowerShell script filename must match the name used by the batch launcher. The examples in this README use `WindowLock.ps1`.

## Running the Tool

### Run from PowerShell

Open PowerShell in the tool folder and run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "the file path"
```

### Run with a Batch File

Download the batch file provided 

OR

Create a file such as `Run-WindowLock.bat` in the same folder as `WindowLock.ps1`:

```bat
@echo off
set "SCRIPT=%~dp0WindowLock.ps1"

if not exist "%SCRIPT%" (
    echo ERROR: WindowLock.ps1 was not found.
    echo Expected location: "%SCRIPT%"
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoLogo -File "%SCRIPT%"
exit /b %ERRORLEVEL%
```

`%~dp0` refers to the folder containing the batch file, so the launcher works even when it is started from another directory.

## Usage

1. Start `WindowLock.ps1`.
2. Select a window from the list.
3. If the required window is missing, click **Refresh list**.
4. Set the desired opacity with the **Window opacity** slider.
5. Click **Apply appearance** to change opacity without locking the window.
6. Click **Lock selected window**.
7. Use **Unlock window** when you want to interact with the target again.
8. Close the control panel when finished.

## Lock Behavior

When a window is locked, the tool:

- Adds mouse pass-through behavior
- Prevents the window from being activated by clicking
- Disables keyboard and normal control interaction
- Sets the window to always on top
- Keeps the controller above the target window
- Applies the currently selected opacity

Because mouse input passes through the locked window, clicking its visible area affects whatever is behind it instead.

## Unlock Behavior

Clicking **Unlock window**:

- Re-enables the target window
- Removes mouse pass-through behavior
- Allows the window to receive normal input again
- Leaves the selected opacity applied until the controller restores the original settings or exits

## Automatic Restoration

When the controller closes normally, it attempts to restore:

- The original enabled state
- The original extended window styles
- Full opacity
- Normal, non-topmost placement

For best results, unlock the target before ending the PowerShell process.

## Important Safety Note

Do not terminate the PowerShell process from Task Manager while a window is locked unless necessary. An unexpected termination can prevent the cleanup routine from restoring the target window.

If a target remains unresponsive after an unexpected termination:

1. Close and reopen the affected application, or
2. Restart Window Lock Manager, select the affected window, lock it, and then use **Unlock window**, or
3. Sign out of Windows and sign back in if the application cannot be recovered normally.

## Troubleshooting

### The target window is not listed

- Make sure the window is visible and has a title.
- Click **Refresh list**.
- Restore the target if it is minimized.
- Some system, protected, or special-purpose windows may not appear.

### Locking or opacity changes do not work

The target may be running with higher privileges than the tool.

Close Window Lock Manager and run it as administrator:

```powershell
Start-Process powershell.exe -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File "C:\Path\To\WindowLock.ps1"'
```

### Mouse input does not pass through

- Unlock and lock the target again.
- Make sure you are using the latest script version.
- Run the tool at the same elevation level as the target application.
- Some applications use custom input or rendering systems and may not follow standard window behavior completely.

### The controller appears behind the target

The script periodically reasserts the controller's topmost position while a target is locked. If it still appears behind:

- Click the controller taskbar button.
- Unlock and lock the target again.
- Check whether another application is using an exclusive full-screen mode.

### The target becomes fully transparent

The minimum GUI opacity is 10%, which helps prevent accidental loss of the target window. Move the slider toward 100% and click **Apply appearance**.

### PowerShell execution is blocked

Run the script with the bypass option:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\WindowLock.ps1"
```

This changes the execution policy only for that PowerShell process.

## Limitations

- Only one target window is managed at a time.
- The target must be a visible top-level window.
- Applications running at a higher privilege level may reject changes.
- Some applications may override always-on-top or input-related styles.
- Exclusive full-screen applications may not behave like normal desktop windows.
- Cleanup is not guaranteed if PowerShell, Windows, or the controller process crashes.

## Renaming the Script

If you rename the PowerShell script, update the batch launcher accordingly.

For example, if the script is named `WindowLockManager.ps1`:

```bat
@echo off
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -NoLogo -File "%~dp0WindowLockManager.ps1"
exit /b %ERRORLEVEL%
```

## License and Disclosure

This tool is written under the assitance of Microsoft Copilot AI. 
This tool is provided as-is. Test it with non-critical applications before using it in an important workflow.
You may use and make your own version of this tool. 
