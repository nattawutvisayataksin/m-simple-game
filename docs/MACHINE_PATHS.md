# สมุดบันทึก path รายเครื่อง (เครื่องที่ใช้พัฒนา)

Updated: 2026-10-31

## ระเบียบใหม่: ไฟล์ใน repo ไม่ฝัง path เครื่องอีกต่อไป

เดิม `GODOT_PATH` ถูก hardcode อยู่ใน `opencode.json`, `.vscode/mcp.json` และสูตรเทสใน README/HOME_SETUP
ทำให้สลับไปทำงานอีกเครื่องต้องแก้ path ไป-กลับเรื่อย ๆ ตั้งแต่วันที่ 2026-10-31 เปลี่ยนระเบียบเป็นระบบ 2 ชั้น:

```text
รันครั้งเดียวต่อเครื่อง:    powershell -ExecutionPolicy Bypass -File shared\setup_machine.ps1
มันจะทำทั้งหมดนี้ให้:    หา Godot ด้วยตัวเอง → ตั้ง env GODOT_PATH (ระดับ User)
                          → ใส่ godot-mcp ลง global config นอก repo (แนวเดียวกับ pixellab)
                          → build แคช import ทุกเกม
                          → เติมแถวของเครื่องนี้ลงตารางด้านล่างให้เอง
```

เครื่องมือที่ใช้ต่อจากนี้ (แทนการพิมพ์ path เองทุกครั้ง):

| ตัว | หน้าที่ | ตัวอย่างการใช้ |
|---|---|---|
| `shared/find_godot.ps1` | หา Godot บนเครื่องนี้ (ค้น env → โฟลเดอร์ winget → บน PATH) แล้วพิมพ์ path เดียว | `$godot = (& .\shared\find_godot.ps1)` |
| `shared/setup_machine.ps1` | ตั้งค่าเครื่องครบชุดในครั้งเดียว (มี `-NoImport` สำหรับกรณีไม่ต้อง build แคช) | คำสั่งด้านบน |

**ห้าม hardcode `C:\Users\<ชื่อ>\...` ลงไฟล์ code/config ที่ commit อีก** — ข้อยกเว้นเดียวคือไฟล์สมุด
นี้ (เซฟค่ารายเครื่องเพื่อพิสูจน์เวลาตะลุยหาปัญหา) ที่เหลือแตะมันคือสคริปต์หาเอง ไม่มีใครพิมพ์ path ใน code อีก

## ตาราง path รายเครื่อง (แถวเพิ่มเองโดย setup_machine.ps1)

| เครื่อง | ผู้ใช้ Windows | Godot.exe (ค่า GODOT_PATH) | ตั้งค่าเมื่อ/โดย |
|---|---|---|---|
| เครื่องหลัก | `Administrator` | `C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` | ยกจาก config ชุดที่ใช้มาก่อน — แนะให้รัน setup_machine.ps1 ครั้งเดียวเพื่อเข้าระบบใหม่ |
| เครื่องบ้าน (ACERHOMENITRO5) | `admin` | `C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` | 2026-10-31 ตั้งโดย setup_machine.ps1 — เทสผ่าน find_godot.ps1 + godot-mcp ตอบเวอร์ชัน |
| เครื่องหลัก (LICENSEHOME) | `Administrator` | `C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe` | 2026-10-31 ตั้งโดย setup_machine.ps1 — env GODOT_PATH + godot-mcp ตอบ 4.7.2 ผ่าน |

> เพิ่มเครื่องใหม่: รัน setup_machine.ps1 มันจะเติมแถวให้เอง (คอลัมน์แรกใช้ COMPUTERNAME กรอกชื่อคนมองรู้เรื่อง
> เช่น "เครื่องหลัก/เครื่องบ้าน" โดยยืนยันตัวจริงด้วย USERNAME คอลัมน์สองเสมอ)

## จุดที่ path ถูกใช้จริง (เครื่องไหนก็ถูกตามกลไกนี้)

| ที่ | กลไก | สลับเครื่องแล้วต้องแก้ไหม |
|---|---|---|
| `games/*/play.bat` | ใช้ `%USERNAME%` ใน path — **เล่นได้ทั้งสองเครื่องอยู่แล้ว** | ไม่ต้อง |
| `.vscode/mcp.json` (VS Code) | อ่าน `${env:GODOT_PATH}` จาก env ระดับ User | ไม่ต้อง — เปิด VS Code ใหม่หลังรัน setup |
| `opencode.json` (repo) | ไม่มี godot-mcp แล้ว (path ไม่มีที่ให้แก้) | ไม่ต้อง |
| `~/.config/opencode/opencode.json` (ของเครื่อง, นอก repo) | godot-mcp พร้อม GODOT_PATH ที่ setup เขียนให้ | ไม่ต้อง |
| สูตรเทส README / HOME_SETUP | `$godot = (& .\shared\find_godot.ps1)` | ไม่ต้อง |

## อัปเดตเวอร์ชัน Godot (เช่น 4.7.2 → 4.8)

`GODOT_PATH` ชี้ไฟล์เวอร์ชันตอนติดตั้งตรง ๆ — พอลงเวอร์ชันใหม่ (ผ่าน winget) ให้รัน setup_machine.ps1 ใหม่อีกครั้ง
มันเลือกเวอร์ชันสูงสุดเอง และท้ายรัน `--import` ทุกเกมให้แคชตามเวอร์ชันจริง

## เช็คเร็วหลังตั้งค่า

- `& .\shared\find_godot.ps1` — พิมพ์ออกมา path เดียว ไฟล์มีจริงบนดิสก์ = เครื่องพร้อม
- เปิดเกมดับเบิลคลิก `play.bat` — ขึ้นหน้าเกมได้ปกติ
- เปิด VS Code / OpenCode ใหม่ — ยิง get_godot_version ผ่าน AI ต้องตอบคืนเวอร์ชัน Godot = godot-mcp ต่อได้
