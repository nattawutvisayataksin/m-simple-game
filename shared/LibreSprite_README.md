# LibreSprite — shared pixel art editor (portable)

เครื่องช่วยวาด/แก้ pixel art ให้ใช้ได้กับทุกเกมใน repo นี้ โดยพอร์ตพร้อมใช้ ไม่ต้องติดตั้งระบบ

- Launcher: `shared/start_libresprite.bat`
- ตัวโปรแกรม: `shared/LibreSprite/libresprite.exe`
- version: v1.3 (https://github.com/LibreSprite/LibreSprite)

## วิธีใช้
1. ดับเบิลคลิก `shared/start_libresprite.bat` หรือรัน:
   ```powershell
   .\shared\start_libresprite.bat
   ```
2. จะเปิดไฟล์ sprite จากภายนอกได้ด้วย Launcher:
   ```powershell
   .\shared\start_libresprite.bat games\game1_coin_rush\assets\art\sprites\player_kubi.png
   ```
3. หลังแก้ไข **Save เป้าหมายเดิม** แล้ว run ต่อ:
   ```powershell
   godot --headless --path games\game1_coin_rush --import
   ```

## หมายเหตุ
- แก้ sprite แล้วต้อง commit + push .png/.gif/.import
- ใช้ native .aseprite ได้ แต่ใช้เฉพาะเก็บไฟล์ก่อน export เป็น png/gif
- ตั้ง nearest-neighbor ใต้ตั้ง tool options ให้เส้นชัด (Ctrl+O)