# คู่มือทำงานต่อบนคอมพิวเตอร์ที่บ้าน

เอกสารนี้ใช้สำหรับเตรียมเครื่องที่บ้านและนำโปรเจกต์ `m-sample-game` ไปพัฒนาต่อ

## 1. โปรแกรมที่ต้องติดตั้ง

ติดตั้งโปรแกรมต่อไปนี้บนคอมพิวเตอร์ที่บ้าน:

- Godot Engine รุ่น 4.x
- Git
- Visual Studio Code
- Node.js รุ่น 18 ขึ้นไป หากต้องการใช้ Godot MCP

ตรวจสอบการติดตั้งบน Windows ด้วย PowerShell:

```powershell
git --version
godot --version
node --version
npm --version
```

## 2. ดาวน์โหลดโปรเจกต์

เปิด PowerShell หรือ Terminal แล้วรัน:

```powershell
git clone https://github.com/nattawutvisayataksin/m-simple-game.git
Set-Location m-simple-game
```

## 3. เปิดโปรเจกต์ Godot

เปิดโปรเจกต์ด้วยคำสั่ง:

```powershell
godot --editor --path .
```

หรือเปิดโฟลเดอร์ `m-simple-game` ด้วย VS Code แล้วเปิดไฟล์ `project.godot` ผ่าน Godot Project Manager

## 4. ตั้งค่า Godot MCP (ถ้าต้องการใช้ AI ช่วยพัฒนา)

โปรเจกต์มีไฟล์ตั้งค่าอยู่ที่ `.vscode/mcp.json` แล้ว แต่ค่า `GODOT_PATH` ต้องตรงกับตำแหน่งติดตั้ง Godot บนเครื่องบ้าน

ตรวจสอบตำแหน่ง Godot:

```powershell
(Get-Command godot).Source
```

จากนั้นแก้ค่า `GODOT_PATH` ใน `.vscode/mcp.json` ให้เป็น path ที่ตรวจสอบได้ เช่น:

```json
{
  "servers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "@coding-solo/godot-mcp"],
      "env": {
        "GODOT_PATH": "C:\\Path\\To\\Godot.exe"
      }
    }
  }
}
```

หลังแก้ไข ให้ Reload Window หรือเปิด VS Code ใหม่

## 5. โครงสร้างไฟล์หลัก

```text
m-simple-game/
├─ .vscode/mcp.json   # การตั้งค่า Godot MCP
├─ addons/            # Godot addons
├─ docs/GDD.md        # Game Design Document
├─ scenes/            # ฉาก Godot เช่น player.tscn
├─ scripts/           # สคริปต์ GDScript
├─ project.godot      # การตั้งค่าโปรเจกต์
├─ readme.md          # ข้อมูลทั่วไป
└─ HOME_SETUP.md      # คู่มือการทำงานต่อที่บ้าน
```

## 6. ไฟล์ Player ที่มีอยู่

ฉาก `scenes/player.tscn` มีโครงสร้างดังนี้:

```text
Player (CharacterBody2D)
├─ Sprite2D
└─ CollisionShape2D
   └─ CircleShape2D
```

## 7. ขั้นตอนการทำงานประจำวัน

ก่อนเริ่มทำงาน ให้ดึงการเปลี่ยนแปลงล่าสุด:

```powershell
git pull origin main
```

หลังแก้ไขงานเสร็จ ให้บันทึกและส่งขึ้น GitHub:

```powershell
git add .
git commit -m "อธิบายสิ่งที่แก้ไข"
git push origin main
```

ก่อนปิดงานควรตรวจสอบสถานะ:

```powershell
git status
```

ถ้าเห็น `working tree clean` แสดงว่าไม่มีไฟล์ที่ยังไม่ได้ commit

## 8. การแก้ปัญหาเบื้องต้น

- หากเปิดโปรเจกต์ไม่ได้ ให้ตรวจสอบว่าเปิดจากโฟลเดอร์ที่มี `project.godot`
- หาก Godot MCP หา Godot ไม่พบ ให้ตรวจสอบค่า `GODOT_PATH`
- หาก `git push` ขอรหัสผ่าน ให้ใช้ GitHub Personal Access Token แทนรหัสผ่านบัญชี
- หากมี conflict หลัง `git pull` ให้หยุดแก้ไขอย่างระมัดระวัง และตรวจสอบไฟล์ที่ Git แจ้ง

## 9. Repository

โปรเจกต์นี้ใช้ repository:

`https://github.com/nattawutvisayataksin/m-simple-game.git`
