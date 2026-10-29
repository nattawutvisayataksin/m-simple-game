# Coin Catcher (m-sample-game)

เกมฝึกพัฒนา 2D ด้วย [Godot Engine 4.x](https://godotengine.org/) — เป้าหมายคือฝึกพื้นฐานการทำเกมทีละระบบ

**วิธีเล่น:** เก็บเหรียญให้ครบ 10 อัน ด้วย **WASD** หรือ **ปุ่มลูกศร** เก็บครบแล้วชนะ กด **R** เริ่มใหม่

## โครงสร้างโปรเจกต์

```text
m-sample-game/
├─ project.godot          # ตั้งค่าเอนจิน + Input Map (WASD/ลูกศร)
├─ readme.md
├─ HOME_SETUP.md          # คู่มือเตรียมเครื่องที่บ้าน
├─ docs/GDD.md            # Game Design Document
├─ scenes/
│  ├─ main.tscn           # ฉากหลัก: กำแพง + Player + ศัตรู + HUD
│  ├─ player.tscn         # CharacterBody2D (นักเก็บเหรียญ)
│  ├─ coin.tscn           # Area2D (เหรียญที่เก็บได้)
│  └─ enemy.tscn          # Area2D (ลูกเหล็กเด้ง — โดนชน = แพ้)
├─ scripts/
│  ├─ main.gd             # คะแนน / นับเวลา / สถานะเกม / เสียง
│  ├─ player.gd           # การเคลื่อนที่ (move_and_slide)
│  ├─ coin.gd             # เก็บเหรียญด้วย signal
│  └─ enemy.gd            # ศัตรูเด้งไปมาในสนาม
├─ assets/audio/          # เสียง .wav สร้างด้วยสคริปต์ (ดู tools/)
├─ tools/generate_sfx.ps1 # สคริปต์สังเคราะห์เสียงเอฟเฟกต์
└─ .vscode/mcp.json       # ตั้งค่า Godot MCP สำหรับ VS Code
```

## ระบบที่ฝึกจากโปรเจกต์นี้

- Input Map และ `Input.get_vector()` — ควบคุมทิศทางลื่น ๆ
- `move_and_slide()` — เดินแล้วเลื่อนตามกำแพงอัตโนมัติ
- Area2D + `body_entered` — ตรวจการชนเหรียญและศัตรู
- Signal — เหรียญ/ศัตรูส่งข่าวไปฉากหลักโดยไม่ผูกติดกัน
- สถานะเกม (state machine) — `PLAYING / WON / LOST`
- นับเวลาถอยหลังด้วย `delta` — หมดเวลา = แพ้
- `randf_range` — สุ่มตำแหน่งวางเหรียญไม่ให้ซ้อนกัน
- HUD (CanvasLayer + Label) — คะแนน, เวลา, จอชนะ/แพ้
- เสียงเอฟเฟกต์ — AudioStreamPlayer + ไฟล์ .wav ที่สังเคราะห์เอง

## กติกา

- เก็บเหรียญให้ครบ 10 อันภายใน 30 วิ = **ชนะ**
- โดนลูกเหล็กสีแดงชน = **แพ้**
- กด **R** เริ่มเกมใหม่ได้ตลอดเวลา

## การเปิดโปรเจกต์และเล่น

1. ติดตั้ง Godot Engine รุ่น 4.x
2. เปิด Godot Project Manager → **Import** → เลือกไฟล์ `project.godot`
3. กด **F5** (Run Project) เล่นได้ทันที (main scene คือ `scenes/main.tscn`)

หรือผ่านคำสั่ง:

```text
godot --editor --path .
```

## Godot MCP

โปรเจกต์ตั้งค่า `@coding-solo/godot-mcp` ไว้ที่ `.vscode/mcp.json` — ใช้ AI ช่วยสร้างฉาก / เพิ่ม Node / ตรวจ debug ได้

> ต้องแก้ `GODOT_PATH` ในไฟล์นั้นให้ตรงกับเครื่องคุณ ดูขั้นตอนใน `HOME_SETUP.md`

## สถานะการพัฒนา

- [x] Player เคลื่อนที่ + ชนกำแพง
- [x] ระบบเหรียญที่เก็บได้
- [x] HUD score + จอชนะ/จอแพ้
- [x] เสียงเก็บเหรียญ (+ เสียงชนะและแพ้)
- [x] นับเวลาถอยหลัง 30 วิ
- [x] ศัตรูลูกเหล็กเด้ง 2 ตัว
- [ ] ระดับความยาก (เกม level เพิ่มศัตรู)
- [ ] sprite จริงแทน Polygon2D
- [ ] เก็บ hi-score ลงไฟล์

หัวข้อฝึกชุดต่อไปดูส่วน "โจทย์ฝึกหัด" ที่คอมเมนต์ในไฟล์ `scripts/*.gd`

## การทำต่อที่คอมพิวเตอร์ที่บ้าน

Repository:

`https://github.com/nattawutvisayataksin/m-simple-game.git`

```text
git clone https://github.com/nattawutvisayataksin/m-simple-game.git
cd m-simple-game
godot --editor --path .
```

คู่มือเตรียมเครื่องฉบับเต็มอยู่ที่ `HOME_SETUP.md`

## ขั้นตอนการทำงานประจำวัน

```text
git pull origin main
# แก้โค้ด
git add .
git commit -m "อธิบายสิ่งที่แก้ไข"
git push origin main
```

> หาก push ขอรหัสผ่าน ให้ใช้ GitHub Personal Access Token (PAT) แทน
