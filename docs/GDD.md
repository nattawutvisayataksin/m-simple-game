# Game Design Document (GDD)

## 1. ข้อมูลทั่วไป

- **ชื่อเกม:** ชิงเหรียญทอง (Coin Rush) — ชื่อโค้ดโปรเจกต์: m-sample-game
- **ประเภทเกม:** 2D Top-down / Arcade เก็บของ + หลบหลีก
- **แพลตฟอร์มเป้าหมาย:** Windows (Godot 4.x, GL Compatibility)
- **เอนจิน:** Godot Engine
- **สถานะ:** เพลย์-อะ-โพรโตไทป์ มีเงื่อนไขแพ้และเสียงแล้ว

## 2. แนวคิดหลักของเกม

เกมฝึกพัฒนาเกมแบบมินิมอล: ผู้เล่นควบคุมตัวละครในสนามปิด เดินเก็บเหรียญที่วางกระจายอยู่ให้ครบภายในไม่กี่วินาที
โครงเกมนี้ถูกออกแบบให้เรียนรู้พื้นฐานของ Godot ครบวงจร: Input, Physics, Collision, Signal, HUD

**เหตุผลของชื่อ "ชิงเหรียญทอง (Coin Rush)":**
- คำว่า "ชิง" และ "Rush" สื่อความเร่งรีบสู้เวลา 30 วิ — หัวใจของเกมคือความเร็ว ไม่ใช่แค่เก็บของ
- "เหรียญทอง" บอกเป้าหมายของผู้เล่นชัดเจน และชวนให้ขยายไปสู่เหรียญทองพิเศษ (คะแนน 3 เท่า) ซึ่งเป็นโจทย์อยู่แล้ว
- ชื่อสั้น อ่านออกภาษาไทย จำง่าย และมีน้ำเสียงอาร์เคดภาษาไทย ไม่เฉยเมยเหมือนชื่อเดิม "Coin Catcher"
- ชื่อสำรองที่พิจารณา: "วิ่งล่าเหรียญ (Coin Chase)", "รีบเก็บให้ไว (Quick Grab)"

## 3. รูปแบบการเล่น

- การควบคุมตัวละคร: **WASD** หรือ **ปุ่มลูกศร** (ตั้งใน Input Map ของ project.godot)
- เป้าหมายของผู้เล่น: เก็บเหรียญให้ครบ 10 อัน
- ระบบการเล่นหลัก: เหรียญสุ่มตำแหน่ง ไม่แน่นแน่นิ่ง เก็บมาเรื่อย ๆ คะแนนนับขึ้นทันที
- เงื่อนไขชนะและแพ้: **ชนะ** = เก็บเหรียญครบ 10 อันภายใน 30 วิ, **แพ้** = โดนลูกเหล็กชน หรือหมดเวลา

## 4. ตัวละคร

### Player

- ประเภท Node: `CharacterBody2D`
- ฉาก: `scenes/player.tscn`
- Node ภายใน:
  - `Polygon2D` (ชื่อ Visual) วงกลมสีฟ้า รัศมี 16 px
  - `CollisionShape2D` รูปวงกลม (CircleShape2D)
- สคริปต์: `scripts/player.gd` — อ่าน Input Map ด้วย `Input.get_vector()` แล้วเรียก `move_and_slide()`

### Coin

- ประเภท Node: `Area2D`
- ฉาก: `scenes/coin.tscn`
- Node ภายใน:
  - `Polygon2D` วงกลมสีเหลือง รัศมี 12 px
  - `CollisionShape2D` รูปวงกลม
- สคริปต์: `scripts/coin.gd` — ยิงสัญญาณ `collected` เมื่อ body ใน group "player" เข้ามา

### Enemy (ลูกเหล็กเด้ง)

- ประเภท Node: `Area2D`
- ฉาก: `scenes/enemy.tscn` (วางในฉากหลัก 2 ตัว)
- เด้งไปมาในสนามด้วยทิศทางสุ่ม พลิกความเร็วเมื่อโดนขอบเขต `BOUNDS_MIN/MAX`
- สคริปต์: `scripts/enemy.gd` — ยิงสัญญาณ `caught_player` เมื่อชนผู้เล่น → เกมแพ้

## 5. โลกและฉาก

- **ฉากหลัก:** `scenes/main.tscn` — สนามขนาด 1152×648 px ปิดด้วยกำแพง 4 ด้าน
- กำแพงเป็น `StaticBody2D` + `RectangleShape2D` เคลื่อนที่แล้วเดินชะงักหรือเลื่อนตามผนัง
- เหรียญถูกวางแบบสุ่มในพื้นที่กลางสนาม ไม่ซ้อนกันหรือติดกำแพง (`scripts/main.gd`)
- HUD: `CanvasLayer` + Label ซ้ายบนแสดงคะแนน, กลางจอแสดงข้อความชนะ
- ปุ่ม **R** รีสตาร์ตฉาก (`reload_current_scene`)

## 6. ระบบเกม

- [x] ระบบควบคุมตัวละคร (Input Map + `Input.get_vector`)
- [x] ระบบการชน/กำแพง (`move_and_slide` + StaticBody2D)
- [x] ระบบเหรียญ (Area2D + signal `collected`)
- [x] ระบบคะแนน (score + Label HUD)
- [x] จอชนะ + รีสตาร์ตด้วยปุ่ม R
- [x] ระบบเวลานับถอยหลัง (จ๊าบ `delta` ทุกเฟรม, หมดเวลา = แพ้)
- [x] ระบบศัตรูลูกเหล็กเด้ง (Area2D, จับเมื่อชน)
- [x] ระบบสถานะเกม (PLAYING / WON / LOST)
- [x] ระบบเสียง (AudioStreamPlayer + .wav สังเคราะห์เอง)
- [ ] ระบบกล้อง (จำเป็นเมื่อขยายสนามใหญ่กว่าจอ)
- [ ] ระดับความยาก / level system
- [ ] งานศิลป์ เปลี่ยน Polygon เป็น sprite จริง

## 7. งานศิลป์และเสียง

- **ธีมภาพ: ชิงเหรียญทอง — ธีม KUB** (Kub Chain / Kub Coin / Bitkub) ส้ม-ทอง-ครีม เส้นขอบเข้ม
  ดูแลด้วย `docs/ART_DIRECTION.md` + `docs/ASSET_MANIFEST.md`
- สปรไตต์จริง (อนุมัติและใช้ในฉากแล้ว 2026-10-29):
  - Player "Kubi" หุ่นยนต์ส้ม — `assets/art/sprites/player_kubi.png`
  - Coin เหรียญ K — `assets/art/sprites/coin_kub.png`
  - Enemy ไวรัสหนามแดง — `assets/art/sprites/enemy_glitch.png`
  - ฉากเบื้องหลัง/กำแพง/ตัวเลข HUD: เปลี่ยนเป็นสปรไตต์แล้ว (Sprite2D, pixel filter nearest, `project.godot`)
  - แอนิเมชันเฟรมจริงผ่าน REST `animate-pixminimax` (มี Pixellab 2 key — Key B ใน `.mcp.json` มี 37 gen ว่าง ใช้ได้อิสระ):
    - เหรียญหมุน: สร็จสปรีตชีต 9 เฟรม `assets/art/gen/coin_sheet.png` ผูก `Sprite2D.hframes=9`+เลื่อนเฟรมใน coin.gd
    - Kubi เดิน: เสร็จ `assets/art/gen/player_sheet.png` (เฟรม 0 = ยืน, 1-8 = เดิน) ผูกแล้วใน player.gd
    - ไวรัส pulsate: เสร็จ `assets/art/gen/enemy_sheet.png` ผูกแล้วใน enemy.gd
    - สคริปต์ผลิต: `tools/pixellab_anim_resume.ps1` (อ่าน key จาก `.mcp.json`) + `tools/build_sprite_sheet.ps1`
- เพลงประกอบ: ยังไม่มี
- เสียงเอฟเฟกต์: มี 3 เสียง (`assets/audio/`) — pickup เก็บเหรียญ, win ชนะ, lose แพ้
  สร้างด้วยสคริปต์ `tools/generate_sfx.ps1` (สังเคราะห์คลื่น sine, แก้โน้ต/ความยาวได้ในไฟล์เดียว)

## 8. โครงสร้างโปรเจกต์

```text
m-sample-game/
├─ project.godot      # ตั้งค่าเอนจิน + Input Map
├─ docs/GDD.md
├─ scenes/
│  ├─ main.tscn       # สนาม + กำแพง + Player + HUD
│  ├─ player.tscn
│  └─ coin.tscn
├─ scripts/
│  ├─ main.gd
│  ├─ player.gd
│  └─ coin.gd
├─ readme.md
└─ HOME_SETUP.md
```

## 9. แผนการพัฒนา (ดีไซน์ระยะถัดไป)

ขั้นเดิม 1–5 สำเร็จแล้ว (โปรโตไทป์เล่นได้จบทั้งชนะและแพ้) ระยะถัดไปแบ่งเป็น 4 ระยะ
ยึดหลัก **prototype-fast** — ทำทีละระยะเล็กแต่เกมต้องเล่นได้ครบทุกจุด และแต่ละระยะต้อง
"ตัดสินได้ว่าสนุกขึ้นจริงไหม" ก่อนไปต่อ

### ระยะ A: Polish ความรู้สึกการเล่น (game-feel) — ทำก่อน เพราะถูกและได้ผลเร็ว
- [x] เหรียญหมุนอยู่ตลอด ✅ (spritesheet 9f อยู่แล้ว + coin.gd เลื่อนเฟรม) + วิ่งเร็วเมื่อกด Shift ✅ 2026-10-29 (player.gd SPRINT_MULT 1.5 + เฟรมก้าวเร็วตาม)
- [x] เหรียญทองพิเศษ โผล่ 1 อันต่อรอบ ให้คะแนน 3 เหรียญ (export var value) — สร้างการตัดสินใจ "แค่ไหนคุ้มเสี่ยง" — 2026-10-29: coin_gold.tscn + value ผ่าน signal, สุ่ม 1 ใน 10 ตำแหน่ง, sprite: coin_kub_gold (edit_image_pixen) + sheets 9f (pixminimax), วาบแสงใน coin.gd
- [x] หลังจบรอบ ซ่อนเหรียญ/หยุดเหรียญไม่ให้เก็บได้ — 2026-10-29: coin.disable() + monitoring=false จาก _end_round
- [x] เวลาเหลือ ≤ 10 วิ ให้ตัวเลขเวลาเปลี่ยนสีแดงทุกวินาที — สร้างแรงกดดันแบบฟรี — 2026-10-29: _update_time_label สลับแดงกระพริบ
- [x] ✨ เพลิดบอนัส: เอฟเฟกต์ประกายทองตอนเก็บเหรียญ (burst_gold.png gen 1 จาก **Key B** + ตัดพื้นหลังด้วย make_transparent.ps1, tween scale+fade ใน coin.gd)

### ระยะ B: Level และความยาก (โจทย์ค้างใน readme)
- [ ] ระบบ level: ศัตรูเพิ่มทีละด่าน (2 → 3 → 4 ตัว) เหรียญถูกสุ่มวางใหม่ทุกด่าน
- [ ] ถ้ายังไม่พอ ให้ระยะนี้เพิ่มพฤติกรรมศัตรู: โต้โอกาสตามผู้เล่นน้อย ๆ / หมุนเร็วขึ้นเรื่อย ๆ (โจทย์ค้างใน enemy.gd)
- [ ] ไม่ต้องเปลี่ยนระบบอื่นแต่ละด่าน — หลักการของโปรเจกต์นี้คือฝึกเพิ่มความยากทีละเล็ก
- [ ] ระบบกล้องยังจำเป็นเมื่อขยายสนามใหญ่กว่าจอ (วางไว้ก่อน)

### ระยะ C: ตัวจริงและศิลป์ แทน Polygon2D
- [x] วาด sprite ตัวละคร/เหรียญ/ศัตรู 3 ตัว ธีม KUB — ⭐ ผู้ใช้อนุมัติ 2026-10-29 (แทนที่ในฉากแล้ว)
- [x] แอนิเมชันเฟรมจริง — เหรียญ: chatsheet 9 เฟรม ผูกในฉากแล้ว; Kubi เดิน / ไวรัส pulsate กำลังผลิตผ่าน REST `animate-pixminimax` (Pixellab 2 key, ใช้ได้อิสระเมื่อต้องการ)
- [x] tileset กำแพง/พื้น ธีม KUB — gen ด้วย Key A daily bonus (job `d54165fd`) ผูกใน main.tscn แล้ว (พื้น Sprite2D tile + กำแพง 4 ด้าน Sprite2D tile 32px grid, Polygon2D หมดจากฉาก) — ทดสอบ headless 4.7.2 ผ่าน 2026-10-29
- [x] เพลงประกอบ + แยก bus เสียง — chiptune สังเคราะห์เอง `tools/generate_music.ps1` → `music.wav` (loop 13.7s seamless, loop_mode native ใน .import), bus Music/SFX ใน `default_bus_layout.tres`, Music autoplay / SFX 3 เสียงชี้ bus SFX — ⚠️ known-benign: quit ระหว่างเพลงเล่น → ObjectDB leak warning 2 instance ตอน exit (AudioServer teardown, ไม่มีผลต่อเกม)
- [x] HUD icon จากของเดิม (เหรียญ K ข้าง ScoreLabel) + LabelSettings สีทอง KUB / outline เข้ม — ฟอนต์จริงไม่ทำ (create_font ได้แค่ Latin 80 ไม่มีไทย — บันทึกไว้ ART_DIRECTION สถานะการเก็บภาพ)
- [ ] เพลงประกอบ + แยก bus เสียง (ตอนนี้มีเพียง SFX 3 เสียง)

### ระยะ D: ปิดหลังบ้านเกม
- [ ] hi-score + save/load ลง user:// (save-systems) — เก็บว่า "ติดด่านไหน / ใช้กี่วินาที"
- [ ] ทดสอบบนเครื่องจริง (ที่บ้าน) เก็บบั๊กก่อนแชร์ต่อ

### เกณฑ์ตัดสินระหว่างทาง
- ถ้าเล่นระยะ A จบแล้ว "ยังไม่รู้สึกเร่ารัก" แปลว่าปัญหาอยู่ที่กลไก ไม่ใช่งานศิลป์ — จะแก้เล่นไปที่ระยะ B แทนไปต่อ
- ถ้าระยะ B สนุกแล้ว ถึงจุดนี้ค่อยลงแรงเรื่อง sprite (ระยะ C) แต่ถ้าระยะ B ยังจืด ตอนนั้นตงชื่อใหม่
  หรือปรับแนวเกมก่อน ต่อไปจะไม่ย้อนแก้ห้ากำแพงหรือ HUD อีก
- ชื่อที่ตามนี้ไม่ต้องเปลี่ยนชื่อโค้ดก่อน (m-sample-game คงที่) แก้แค่ GDD/ชื่อหัวกระดาษพอ ตอน export จอแต่แรกก่อน
  มีชื่อจริงการพัฒนา

## 10. บันทึกการเปลี่ยนแปลง

| วันที่ | รายละเอียด |
|---|---|
| 2026-10-28 | สร้างเอกสาร GDD เบื้องต้นและกำหนดโครงสร้าง Player |
| 2026-10-29 | สร้างเกม Coin Catcher: main scene, กำแพง, เหรียญ, HUD, จอชนะ, ปุ่มรีสตาร์ต |
| 2026-10-29 | เพิ่มเงื่อนไขแพ้: นับเวลา 30 วิ + ศัตรูลูกเหล็กเด้ง, เสียงเอฟเฟกต์ 3 เสียง, สถานะเกม |
| 2026-10-29 | วิเคราะห์ระบบทั้งโปรเจกต์ด้วย skill set (router + godot-gdscript), ตั้งชื่อเกมใหม่ "ชิงเหรียญทอง (Coin Rush)", อัปเดตแผนดีไซน์ 4 ระยะ (Polish / Level / ศิลป์ / Save) |
| 2026-10-29 | ระยะ C เริ่ม: ธีมภาพ KUB, สปรไตต์ 3 ตัว (Kubi / เหรียญ K / ไวรัส) ผ่านการอนุมัติและแทนสายในฉาก, แอนิเมชัน free-juice ในโค้ด + ผลิตเฟรมจริงผ่าน REST pixminimax |
| 2026-10-29 | เหรียญหมุนเฟรมจริงเสร็จ (spritesheet 9f → Sprite2D.hframes) + เพิ่ม Pixellab 2 key (REST v2 ใช้ได้อิสระ) — อัปเดต ART_DIRECTION §3, ASSET_MANIFEST; push ชุด sprite เดิมแล้ว, ชุดแอนิเมชันรอ commit ต่อ |
| 2026-10-29 | **แอนิเมชัน 3 ชุดเสร็จสมบูรณ์**: coin/player/enemy spritesheet 9f ผูกในฉากครบ (commit `aefa239` push GitHub แล้ว) + แก้ bugs ที่ Godot 4.7.2 พบ (คอมเมนต์ใน .tscn ไม่รองรับ → ลบ, coin.gd ประกาศซ้ำ → แก้, enemy.tscn texture เก่า → ชี้ sheet) — **ทดสอบรันจริงบนเครื่องผู้ใช้ผ่าน ไม่มี error** (Godot 4.7.2 จาก winget ติดตั้งแล้ว; GODOT_PATH ใน .mcp.json แก้สมบูรณ์) |
| 2026-10-29 | **tileset กำแพง/พื้น KUB เสร็จ** (ระยะ C ข้อ 3): gen 1 ครั้งด้วย **Key A daily bonus** (bonus ใช้ได้จริง 5→4, job `d54165fd`, 16 tiles 32×32) → `assets/art/gen/kub_arena_sheet.png` + เจอ metadata .json (bbox พื้น 64,32 / กำแพง 0,96) แทนที่ใน main.tscn: พื้น ColorRect → Sprite2D tile + กำแพง 4 ด้าน Polygon2D 40px → Sprite2D tile 32px ยึด grid (collision 1152×32 / 32×648) — headless import + รัน 30f ผ่าน ไม่มี error |
| 2026-10-29 | **ระยะ C ครบทุกข้อ**: (1) เพลง chiptune loop สังเคราะห์ PowerShell เอง `tools/generate_music.ps1` → music.wav 13.7s seamless (loop_mode ใน .import, autoplay, bus Music) + bus SFX เก็บ SFX 3 เสียง (2) HUD เหรียญ icon ใช้ coin_kub.png ซ้ำ + LabelSettings ทอง KUB/outline (ไม่ทำฟอนต์จริง — create_font Latin-only จนไม่มีไทย) (3) ⚠️ known-benign: quit ระหว่างเพลงเล่น → ObjectDB leak warning (AudioServer teardown, ไม่มีผล) — ทั้งหมดทดสอบ headless ผ่าน |
| 2026-10-29 | **ระยะ C ครบ + ระยะ A ผ่าน 3/4 ข้อ**: (1) เหรียญทองจาก `edit_image_pixen` (1 gen, ใช้ bonus Key A) + sheet หมุน 9f (1 gen) → coin_gold.tscn ให้ value=3, วาบแสง, สุ่ม 1 อันต่อรอบ / (2) หลังจบรอบปิดเหรียญ `coin.disable()` / (3) เวลา ≤10 วิ ตัวเลขแดงกระพริบ — + gen ไวรัสสีเขียว/น้ำเงิน (2 gen) เก็บไว้ระยะ B — ข้อค้าง: ผู้เล่นยังไม่ได้ทดสอบมือจริง (ค้างตาม GDD นี้), โบนัส เหลือ 0 จนรุ่งรัตติกาล |
| 2026-10-29 | **สถานะสำหรับเซสชันถัดไป**: ระยะ C ครบ 100%, ระยะ A ครบโจทย์ code (เหลือเฉพาะ: ผู้เล่นเทสรจริง, วิ่งเร็วด้วย Shift ยังไม่ทำ) — ถัดไป: ระยะ B (ไวรัส 2 สีพร้อมใช้) → ระยะ D (hi-score) — โควตา: Key A plan หมด+bonus วันนี้หมด (used 50/40, รอ +5 คืนถัดไป) **Key B เหลือ 37/40 ยังใช้อิสระผ่าน REST**; ผู้ใช้อนุมัติเพิ่ม MCP `pixellab-b` (Key B) ใน config ส่วน global → อนาคตหลังรีสตาร์ท จะเรียก pixellab แบบ 2 คีย์คู่ได้ทันที |
