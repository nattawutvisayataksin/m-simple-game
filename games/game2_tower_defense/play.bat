@echo off
rem เปิดเกม "หอคอยคู่ฟ้า (Kub Kingdom Rush)" — ดับเบิลคลิกไฟล์นี้
rem หาก Godot ติดตั้งจาก winget จะพบที่นี่โดยอัตโนมัติ — เครื่องอื่นแก้ path ตาม HOME_SETUP.md
"C:\Users\%USERNAME%\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
