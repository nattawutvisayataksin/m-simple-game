@echo off
rem เปิดเกม "ชิงเหรียญทอง (Coin Rush)" — ดับเบิลคลิกไฟล์นี้
rem ใช้ %USERNAME% ตรวจชื่อผู้ใช้เครื่องแทน hardcode (เดิม "admin" ไม่ตรงเครื่องอื่น)
rem หาก Godot ติดตั้งจาก winget จะพบที่นี่โดยอัตโนมัติ — เครื่องอื่นแก้ path ตาม HOME_SETUP.md
"C:\Users\%USERNAME%\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
