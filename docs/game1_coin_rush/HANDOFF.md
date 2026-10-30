# Handoff — Game 1 (Kubi Coin Dash)

## สถานะปัจจุบัน (30 ต.ค. 2026 — รอบแก้ feedback 4 ข้อ)
- **เริ่มจากหน้าเมนู**: `title.tscn` (main_scene) → Space/คลิกเริ่มเกม · ในเกม R รีสตาร์ท · Esc กลับเมนู
- **hero วิ่งได้จริง**: sheet 9 เฟรม `kubi_hero_run_sheet.png` (สร้างจาก animate_image บน Key B, ประกอบด้วย `tools/build_hero_sheet.gd`) — เฟรม 0-7 = รอบวิ่ง, เฟรม 3 = กลางอากาศ, เฟรม 8 = ยืน idle
- **กระโดดใหม่**: fall gravity 1.35 (เดิม 1.7 สุดสั้น), JUMP_CUT 0.55, JUMP_BUFFER 0.15, COYOTE 0.12, จับปุ่มจาก `_input` event ไม่หลุดอีก
- **near bg ใหม่** `hills_near.png` (pixen gen บน Key C, 240×224) — เขาพาสเตล + ต้นไม้ตัวเล็ก "ไม่แตะขอบบน" แก้ต้นไม้หัวตัด, scale 2.2 factor 0.45; แถบหินล่างถูกพื้นโลกบังเอง
- ตรวจผ่าน screenshot จริง 2 ตอน: title + gameplay (ต้นไม้ครบทรง, เลย์เอาต์อ่านชัด) — debug shots และ hook ถูกลบหมดแล้ว

## บทเรียนสำคัญ (กันซ้ำ)
- **Color.a เป็น float 0..1 ไม่ใช่ 0..255** — สคริปต์วัด alpha ทุกตัวก่อนหน้าเทียบ `> 200` เลยได้ "โปร่งใสหมด" หลอกตัวเอง; ใช้ `Color.a8` หรือเทียบ `> 0.85` (`tools/check_hills_alpha.gd` แก้แล้ว)
- **ห้าม**ปล่อย ColorRect/แผงป้ายใด ๆ ทับ canvas (รอบก่อน "Background" ดำปิดจอ) — ฉากหลังเริ่มจาก CanvasLayer (sky -100, far -90, near -80)
- **ห้าม**ใช้ region sheet ที่ไม่ได้ตรวจพิกเซลจริง — region (0,96) เคยเป็นช่องโล่งทำแพลตฟอร์มล่องหน
- **ภาพ gen ที่ต้นไม้แตะขอบบน** = ยอดตัดเป็นเส้นตรงเห็นชัดเมื่อวาง strip → สั่ง gen "nothing touches the top edge, small short trees on low horizon" แก้ตั้งแต่ต้นทาง
- GDI+ เปราะบนเครื่องนี้ — แปลง/ครอปภาพใช้ Godot headless script แทน

## โครงสร้างไฟล์สำคัญ
- `project.godot` main_scene = `scenes/title.tscn` (input jump/move, texture filter NEAREST, GL compatibility)
- `scenes/title.tscn` + `scripts/title.gd` — เมนู: ชื่อเกม + ฮีโร่ลอย + คำใบ้ + สถิติจาก save; Space/Enter/คลิก → main
- `scenes/main.tscn` + `scripts/main.gd` — LEVELS 3 ด่าน, sky/parallax CanvasLayers, `_build_platform` (ไทล์+ขอบเข้ม), save/load, shake/hit-stop, Esc กลับเมนู
- `scenes/player.tscn` + `scripts/player.gd` — hero sheet 9 เฟรม (scale 1.15, offset -13), coyote 0.12/buffer 0.15/cut 0.55/fall 1.35, run 12fps อัตโนมัติตามความเร็ว, air=เฟรม 3, idle=เฟรม 8
- `scenes/enemy.tscn` + `scripts/enemy.gd` — ไวรัสแดง scale 1.3, stomp → bounce + trauma 0.3 + hit-stop 0.06
- `scenes/coin.tscn` / `coin_gold.tscn` / `goal.tscn` / `hazard.tscn` / `moving_platform.tscn` (ไทล์ repeat 160×24)
- `tools/build_hero_sheet.gd` — ประกอบ run_frames/f0..f8.png → kubi_hero_run_sheet.png (รวม 576×64)
- `tools/check_hills_alpha.gd` (แก้ a8) / `tools/probe_pixels.gd` — ตรวจ alpha/สีพิกเซลจริง
- `assets/art/sprites/run_frames/` — 9 เฟรมดิบจาก animate_image (สำรองไว้แก้มือต่อใน LibreSprite ได้)
- `tools/generate_sfx.ps1` / `generate_music.ps1`

## ระบบฉาก
- SkyLayer (CanvasLayer -100): GradientTexture2D แนวตั้ง #3fa9e8→#8fd3f4→#ffe9c2
- BGFar (-90): `assets/art/gen/bg_sunny.png` scale 2.9 เต็มจอ, factor 0.18
- BGNear (-80): `assets/art/gen/hills_near.png` scale 2.2, factor 0.45 (เขา+ต้นไม้เล็ก, แถบหินล่างโดนพื้นบัง)

## วิธีรัน/ทดสอบ
```powershell
# import
godot --headless --path games/game1_coin_rush --import
# เปิดเล่นจริง
Start-Process "...Godot_v4.7.2-stable_win64.exe" -ArgumentList "--path","C:\m-simple-game\games\game1_coin_rush"
```

## Assets ชุดล่าสุด (30 ต.ค. รอบแก้ feedback)
- `gen/hills_near.png` (240×224, Key C 1 gen) — near strip ใหม่; ใช้เต็มภาพ (ช่องอากาศ row 121-126 ทำให้ไม่มีแนวครอปที่ปลอดภัย)
- `sprites/kubi_hero_run_sheet.png` (576×64, 9 ร่าง) — จาก `animate_image` บน Key B (1 daily) + เฟรมดิบ `run_frames/f0..f8.png`
- `gen/hills_strip.png` เก่า (ต้นไม้ยักษ์แตะขอบบน) — หยุดใช้, เก็บไว้เป็นตัวอย่าง anti-pattern
- เก่าแต่ยังใช่: `gen/bg_sunny.png` (far), ไทล์ 4 ชิ้น (ground cap / dirt fill / plank / moving — วาดเองฟรี 0 gen)
- ลบแล้ว: `hills_low.png`, `hills_sky_free.png` (ผลพลอย obsolete)

## โควตา (หลังรอบนี้)
- Key A: plan หมด + daily หมด
- Key B: plan หมด + daily หมดใช้แล้ว (animate hero 8 เฟรม 5)
- Key C: plan ~38 + daily ~9 หลัง hills_near (ยิง 1 gen จาก 39) — เผื่อเกม 2/ต่อไป; ห้ามฝัง key ในไฟล์ที่ commit
- LibreSprite portable พร้อมเปิด: `shared/start_libresprite.bat` (ใช้นามมือ sprite เพิ่มเติมได้)

## งานถัดไป
- เปิดเกมให้ user ลองเล่นจริงและฟังเห็นแกได้ไม่มี error
- Title screen, checkpoint, เพลงด่าน 2 ต่อ, ด่าน 4+ / procedural level
- Export build + itch
