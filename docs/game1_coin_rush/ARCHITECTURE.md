# สถาปัตยกรรม — ชิงเหรียญทอง (Coin Rush) · เกม 1

รวมองค์ประกอบฝึกพื้นฐานของเกมนี้จากมุมวิศวกรรม — ดีไซน์เชิงเกมดู [GDD.md](GDD.md) · งานศิลป์ [ART_DIRECTION.md](ART_DIRECTION.md) · โควตา/บัญชี asset [../ASSET_MANIFEST.md](../ASSET_MANIFEST.md)

## วิธีเล่น (โครงเกม) — เอกสารนี้แยกด้าน "โครงโค้ด/ระบบ"; แผนดีไซน์ระยะถัดไปดู GDD

- เก็บเหรียญ **10 อัน** ภายใน **30 วิ** = ชนะ · โดนลูกไวรัสชน = แพ้ · กด **R** เริ่มใหม่
- ควบคุม **WASD / ลูกศร** (เดินเร็ว Shift), จอสนาม 1152×648 ปิด 4 กำแพง

## โครงไฟล์โค้ด (เก็บที่ `games/game1_coin_rush/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `scenes/main.tscn` | ฉากหลัก: พื้น tileset + กำแพง 4 ด้าน (StaticBody2D) + Player + เหรียญ + HUD (`CanvasLayer`) |
| `scenes/player.tscn` | `CharacterBody2D` + Sprite2D ชุดเฟรมเดิน 9 ช่อง + CollisionShape2D กลม |
| `scenes/coin.tscn` | `Area2D` เหรียญ (มีรุ่น `coin_gold.tscn` ค่า 1-10 คะแนน) |
| `scenes/enemy.tscn` | `Area2D` ไวรัสไล่ + แอนิเมชัน pulse |
| `scripts/main.gd` | state machine `PLAYING/WON/LOST` · คะแนน/เวลา · เวลาเดินด้วย `delta` · HUD ปรับสีเมื่อเวลาน้อย · **ตาราง spawn ไวรัส** `VIRUS_SPAWN_SCHEDULE` (ประกอบเฟรสต้นครู่ก่อน ระยะหลังโหด) |
| `scripts/player.gd` | `move_and_slide` + `Input.get_vector` + `SPRINT_MULT` (Shift วิ่งเร็ว) |
| `scripts/coin.gd` | signal `collected` + แอนิเมชันหมุนสปรีตชีต 9 เฟรม + ป๊อปประกายทอง (`burst_gold.png` tween) |
| `scripts/enemy.gd` | ไวรัสโจมตี: `_steer()` — ตามผู้เล่น (chase) / วงาวูบ (patrol) · spawn ระยะสุ่ม + คูลดาวน์เปิดไล่ |

## ระบบที่ถูกฝึกจากเกมนี้ (ต้องขึ้นทะเบียน)

1. Input Map + `Input.get_vector()` — ควบคุมทิศทางลื่น ๆ
2. `move_and_slide()` + StaticBody2D — เดินแล้วเลื่อนตามกำแพง
3. Area2D + `body_entered` — เก็บเหรียญ/แพ้เมื่อโดน
4. Signal — เหรียญ/ศัตรูไม่ผูกติดกันเอง
5. State machine ในฉากหลัก (PLAYING/WON/LOST)
6. Camera ยังไม่มี (สนามเท่าจอ — เผื่อต่อ `camera-systems`)
7. HUD `CanvasLayer` + Label + LabelSettings (ธีม KUB)
8. เสียง 3 คลิปสังเคราะห์ sine + เพลง chiptune loop + **bus Music/SFX** (`default_bus_layout.tres`)

## เสียง / เพลง

- `assets/audio/music.wav` — เพลง chiptune 13.7s loop seamless (สังเคราะห์ตัวเอง ฟรี)
- `assets/audio/pickup.wav / win.wav / lose.wav` — SFX 3 คลิป
- สังกัดเสียง: เพลง bus Music (autoplay) + SFX คลิปแยก bus SFX (`default_bus_layout.tres`)
- ข้อควรรู้: ปิดเกมโผล่ ObjectDB leak warning 2 instance (ความรู้มี — ปล่อยได้ เป็น teardown ของ AudioServer ไม่กระทบเกม)

## การทดสอบ (เกมนี้ยังไม่มีสูทเทสอัตโนมัติ — เทสด้วยผู้เล่นจริงตามฟีดแบ็ก)

- ตรวจความสมบูรณ์ของโปรเจกต์หลังย้ายไฟล์: `godot --headless --path games/game1_coin_rush --import` ต้องไม่มี `SCRIPT ERROR`
- ต่อท้ายที่จะเขียนสูทเทส ให้โยกแพตเทิร์นจากเกม 2: `games/game2_tower_defense/tools/test_t3.gd` (extends SceneTree + จำลอง input + เทียบสถานะ)
