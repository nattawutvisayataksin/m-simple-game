# m-sample-game

โปรเจกต์เกมที่พัฒนาด้วย [Godot Engine](https://godotengine.org/)

## ข้อมูลเบื้องต้น

- ชื่อโปรเจกต์: `m-sample-game`
- เอนจิน: Godot
- Renderer: GL Compatibility
- Godot MCP: `@coding-solo/godot-mcp`

## โครงสร้างโปรเจกต์

```text
m-sample-game/
├─ project.godot       # ไฟล์ตั้งค่าโปรเจกต์ Godot
├─ readme.md           # เอกสารเบื้องต้นของโปรเจกต์
├─ scenes/             # ไฟล์ฉากของเกม (.tscn)
├─ scripts/            # สคริปต์ GDScript (.gd)
├─ addons/             # ส่วนเสริมของ Godot
└─ .vscode/
   └─ mcp.json         # การตั้งค่า Godot MCP สำหรับ VS Code
```

## การเปิดโปรเจกต์

1. ติดตั้ง Godot Engine
2. เปิด Godot Project Manager
3. เลือก **Import**
4. เลือกไฟล์ `project.godot` ในโฟลเดอร์โปรเจกต์
5. กด **Run Project** เพื่อเริ่มโปรเจกต์

หรือเปิดโฟลเดอร์นี้ด้วย Godot โดยตรงจากคำสั่ง:

```text
godot --editor --path .
```

## Godot MCP

โปรเจกต์นี้ตั้งค่า Godot MCP ไว้ใน `.vscode/mcp.json` เพื่อช่วยให้ AI agent สามารถโต้ตอบกับ Godot ได้ เช่น:

- เปิด Godot Editor
- เรียกใช้โปรเจกต์
- ตรวจสอบ debug output
- สร้างและจัดการฉาก
- เพิ่ม Node ในฉาก
- จัดการ UID ของไฟล์ Godot

หลังจากเปิดโปรเจกต์ใน VS Code ให้ Reload Window หาก MCP ยังไม่แสดงในทันที

## แนวทางการจัดเก็บไฟล์

- เก็บไฟล์ฉากทั้งหมดไว้ใน `scenes/`
- เก็บสคริปต์ GDScript ไว้ใน `scripts/`
- เก็บปลั๊กอินหรือส่วนเสริมไว้ใน `addons/`
- ตั้งชื่อไฟล์และโฟลเดอร์ให้สื่อความหมาย

## สถานะการพัฒนา

โปรเจกต์อยู่ในขั้นตอนเริ่มต้น สามารถเพิ่มฉาก ตัวละคร ระบบเกม และทรัพยากรต่าง ๆ ได้ตามต้องการ

## การนำโปรเจกต์ไปทำต่อที่คอมพิวเตอร์ที่บ้าน

โปรเจกต์ปลายทางบน GitHub คือ:

`https://github.com/nattawutvisayataksin/m-simple-game.git`

ขณะนี้ repository ดังกล่าวยังว่างอยู่ จึงสามารถใช้เป็น remote สำหรับเก็บโปรเจกต์นี้ได้

### วิธีส่งโปรเจกต์ขึ้น GitHub จากเครื่องนี้

เปิด Terminal ที่โฟลเดอร์ `m-sample-game` แล้วรันคำสั่งต่อไปนี้:

```text
git init
git add .
git commit -m "Initial Godot project setup"
git branch -M main
git remote add origin https://github.com/nattawutvisayataksin/m-simple-game.git
git push -u origin main
```

หากมีการตั้งค่า remote ไว้แล้ว ให้ใช้คำสั่งนี้แทนคำสั่ง `git remote add origin`:

```text
git remote set-url origin https://github.com/nattawutvisayataksin/m-simple-game.git
```

> หาก GitHub ขอรหัสผ่าน ให้ใช้ Personal Access Token (PAT) แทนรหัสผ่านบัญชี GitHub

### วิธีดาวน์โหลดและทำต่อที่บ้าน

ติดตั้งโปรแกรมเหล่านี้บนคอมพิวเตอร์ที่บ้านก่อน:

- Godot Engine รุ่น 4.x
- Git
- Node.js รุ่น 18 ขึ้นไป หากต้องการใช้ Godot MCP
- Visual Studio Code หากต้องการใช้ MCP ผ่าน VS Code

จากนั้นเปิด Terminal แล้วรัน:

```text
git clone https://github.com/nattawutvisayataksin/m-simple-game.git
cd m-simple-game
```

เปิดโปรเจกต์ด้วย Godot:

```text
godot --editor --path .
```

หรือเปิดโฟลเดอร์ `m-simple-game` ใน VS Code แล้วเปิดไฟล์ `project.godot` ผ่าน Godot

### ตั้งค่า Godot MCP ที่เครื่องบ้าน

ไฟล์ `.vscode/mcp.json` ถูกเก็บไว้ในโปรเจกต์แล้ว แต่ค่า `GODOT_PATH` อาจแตกต่างกันตามตำแหน่งติดตั้ง Godot ของแต่ละเครื่อง ให้แก้ path ในไฟล์นี้ให้ตรงกับเครื่องบ้าน เช่น:

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

ตรวจสอบ path ของ Godot บน Windows ได้ด้วยคำสั่ง:

```powershell
Get-Command godot
```

หลังแก้ไขไฟล์ MCP แล้ว ให้ Reload Window หรือเปิด VS Code ใหม่

### ขั้นตอนการทำงานประจำวัน

ก่อนเริ่มทำงาน:

```text
git pull origin main
```

หลังแก้ไขงานเสร็จ:

```text
git add .
git commit -m "Describe your changes"
git push origin main
```

ควร commit งานเป็นระยะ และตรวจสอบว่าไฟล์สำคัญ เช่น `project.godot`, `scenes/`, `scripts/`, `docs/` และ `.vscode/mcp.json` ถูกส่งขึ้น GitHub ครบถ้วน
