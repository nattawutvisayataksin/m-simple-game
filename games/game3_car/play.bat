@echo off
rem Open Kubi Grand Prix - double-click this file
rem Uses %USERNAME% to detect the user account; see ../HOME_SETUP.md for Godot path notes
"C:\Users\%USERNAME%\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0starter-kit-racing"
