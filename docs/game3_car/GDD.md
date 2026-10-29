# GDD — เกมที่ 3: เกมรถ

> สถานะ: **T0.5 — มีฐานจริงแล้ว (Starter Kit Racing)** — รันได้ทันที รอผู้อำนวยการวางแนวเกมรถ/โมดัสเทรบานจูน

## 🚗 ของที่มีพร้อมแล้ว (Starter Kit Racing — Kenney NL, MIT/CC0)

ที่อยู่: `games/game3_car/starter-kit-racing/` (commit `3c3e434`) — เปิดเองด้วย `godot --path games/game3_car/starter-kit-racing`

| ของ | ที่เก็บ |
|---|---|
| ระบบรถขับได้จริง (arcade) — เร่ง/เบรก/เลี้ยว/Skid + เสียง | `scripts/vehicle.gd`, `vehicle-motorcycle.gd`, `scenes/vehicle*.tscn` |
| สนามแข่งตัวอย่างสร้างจาก **GridMap** (ต่อแผ่น-เลี้ยว-หิมเส้นชัย-เต็นទ์) | `scenes/main.tscn` + `models/*.glb`, `collision-*.fbx` |
| รถ 5 สี (truck yellow/red/purple/green + motorcycle) | `models/vehicle-*.glb` |
| เอฟเฟกต์ควันบุหรี่ท้าย + impact | `sprites/smoke.png`, `audio/*.ogg` |
| เรนเดอร์ Forward+ + **Jolt Physics** + MSAA | ตั้งไว้ใน `project.godot` ตามแผงสายพันธุ์ 4.6 (พิสูจน์แล้วรันได้บน Godot 4.7.2) |

**แผนสายการ T1 ที่ก้าวสู่ชัด:** hack ตรง EntryPoint ของ kit — เปลี่ยนภาพ/ปรับสนาม GridMap ชุดเรา + ผูก HUD/ชุดตัวเป้าของผู้อำนวยการ (ยังตัดสินไม่สิ้น) ตัว starter kit ประกอบถูกทุกอันที่เกม 3 ต้อง ไม่ทำซ้ำกัน (ระบบขับ/สนาม/เสียง) — โมเดลที่จะสั่งถามผ่าน MCP blender เป็นสิ่งที่ kit ไม่มี (เช่น รถ Kubi ธีมเมาท์)

## ❓ คำถามตั้งต้นที่ต้องตอบก่อน T1

1. **แนวเกมรถแบบไหน**: แข่งหน้าขวา (sidescroller racing) / top-down หลบรถเก็บของ / ถนนวิ่งสะสมเลน (traffic dodge) / drag race?
2. **เป้าประสบการณ์** เดินตามคณะเดิม: รอบแรกเน้น "สนุกไหม" ตัดสินจากการเล่นจริง ไม่กองฟีเจอร์
3. **งบ art**: มี Key C ใหม่ (ยังเต็ม?) + Key B เหลือ 4/40 — นัดบนสุดพาราพิ ตามนโยบาย Key B หมดก่อนค่อย C

## โครงที่วางไว้แล้ว (สืบทอดบทเรียนเกม 2)

| ลำบอก | ของแล้ว |
|---|---|
| โครง repo | `games/game3_car/` (project.godot อิสระ + scenes/ + scripts/ + assets/) |
| ฉากตั้งต้น | จอ 1152×648 เดียว ยืดหลักเดิม `(stretch canvas_items + aspect keep)` — กันบั๊กคลิก DPI ตั้งแต่กาบแรก |
| ทางเข้าเกม | `play.bat` ดับเบิลคลิก |
| แผนเทส | เก็บพาธเดียวกัน `tools/test_*.gd` --script จากในโฟลเดอร์ (เกม 2 เทียบชัดไปแล้ว) |

## ประวัติงาน (ใหม่ล่าสุดอยู่บนสุด)

| วัน | สรุป |
|---|---|
| 2026-10-29 | **T0.5 ลง Starter Kit Racing (KenneyNL, MIT/CC0)** ตามคำสั่ง "ลง kit ช่วยให้ไวขึ้น": vendor ไป `games/game3_car/starter-kit-racing/` (ตัด nested .git) — ประกอบระบบพร้อมขับได้ทันที: arcade vehicle (WASD + skid เสียง), สนามสร้างมาจาก GridMap (ต่อแผ่น/โค้ง/เส้นชัย/เต็นท์), รถ 5 สี + มอเตอร์ไซค์, ควันท้าย, Forward+ Jolt — พิสูจน์ headless import+run exit 0 บน Godot 4.7.2 — ประเด็นที่ต้องตัดสิน: kit นี้ = **3D** (ขั้นตอนแนว 2D เดิมสองเกม) ผู้อำนวยการต้องตรวจ "เป็น 3D แบบนี้ไหม" ก่อนลุยต่อ |
| 2026-10-29 | **T0 โครงตั้งต้น**: สร้างโฟลเดอร์ `games/game3_car/` + project.godot (ยืดพิกัด stretch canvas_items ติดตั้งตั้งแต่แรก ตามบทเรียน DPI 125% เกม 2) + ฉาก stub พร้อมรัน (จอเทา + ป้ายสถานะ) + play.bat + GDD.md — headless import รันสะอาด exit 0 — รอคำสั่งกำหนดแนวเกมรถ |
