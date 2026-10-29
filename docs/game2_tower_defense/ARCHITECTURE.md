# สถาปัตยกรรม — หอคอยคู่ฟ้า (Kub Kingdom Rush) · เกม 2

GDD อยู่ที่ [GDD.md](GDD.md) · รายละเอียด asset/art [ASSETS.md](ASSETS.md) · key/โควตา [../ASSET_MANIFEST.md](../ASSET_MANIFEST.md)

**สถานะ: พักพัฒนารอผลทดลองเล่น** — ฟีเจอร์ป้อมเวท/โกเลมหินและอาวุธป้อมหมุนเล็งเป้าพร้อมแล้ว; ผู้ใช้ขอพักหลังเปิดเกมให้ทดสอบ รอรับ feedback ก่อนเริ่มงานรอบถัดไป ดูขั้นตอนส่งต่องานที่ [HANDOFF.md](HANDOFF.md)

## วิธีเล่น (โครงเกม)

- Tower defense แบบ Kingdom Rush: มอนเดิน PATH_A `[ประตูม่วง (261,250) → วกลง → เลี้ยวขวา → ประตูปราสาท (816,495)]`
- สร้างป้อมได้ 4 ลาน (คลิกฐาน/กดปุ่ม 1-4): **นักธนู 90 ทอง** (ยิง 0.75 วิ dmg 9 รัศมี 170) / **ปืนใหญ่ 150 ทอง** (1.7 วิ dmg 30 รัศมี 200 ระเบิด 70px โหมดเพื่อนบ้าน) / **ป้อมเวท 130 ทอง** (ยิงเวททะลุเกราะ)
- อัปเกรด Lv2 ได้ (นักธนู 70 · ปืนใหญ่ 110) · ขายคืน 60%
- คลื่น 10 รอบ — เรียกก่อนได้โบนัส, จบคลื่นได้โบนัส, จอชนะ/แพ้ + เริ่มใหม่
- โกเลมหิน: มอนช้า HP 95 เกราะลดดาเมจกายภาพ 65%; เวทมนตร์ของป้อมเวทไม่ถูกเกราะลด
- ฮีโร่ Kubi: คลิกขวาสั่งเดินพร้อมตัวชี้จุดหมาย · ฟาดศัตรูรัศมี 130 (dmg 18/0.9 วิ) พร้อมเอฟเฟกต์โจมตี · ฟื้นตอนพัก · แพ้แล้วเกิดใหม่หน้าปราสาท (816,470) 8 วิ

## โครงไฟล์โค้ด (เก็บที่ `games/game2_tower_defense/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `scenes/main.tscn` + `scripts/main.gd` | พื้นหลังวาดหลังวัตถุเกม (แก้ป้อมลาน 3 ถูกบัง) · spawner กบ/กิ้งก่า/โกเลมหิน · คลื่น 10 รอบ · เศรษฐกิจและ HUD · ฐานสร้างหกเหลี่ยมพร้อมเลขลัด · เมนูแสดงชื่อ/ราคา · เมนูสร้าง/อัปเกรด/ขาย · วงระยะยิงเฉพาะป้อมที่เลือก · โหมดจอชนะ/แพ้ |
| `scripts/enemy.gd` | waypoint walker **carry leftover distance** (ระยะค้างข้ามจุดกัน "หยุดหายใจ" มุม) · เต้น `scale-pulse` + sheet 8f เดินจริง · เลือกชุดท่า: เดินแนวนอน = ชุด **หันข้าง** (flip หัวไปทางเดิน), ตั้ง/ทแยง = ชุดหน้าตรง · y-offset เท้าต่อชุด (กบ 59 / กิ้งก่าหน้าตรง 56 / หันข้าง 43 · วัดจริงด้วย `tools/measure_feet.ps1`) · `hp/reward/progress` (ป้อมเลืองเป้า "คืบหน้าสุด") · ส่งสัญญาณ `reached_castle` / `died(reward, at)` · เงาวงรีใต้เท้า + y-sort |
| `scripts/tower.gd` | เลือกเป้าคืบหน้าสุด · ฐานป้อมอยู่นิ่ง ส่วนอาวุธบนฐานหมุนตามเป้าแบบลื่นและยิงเมื่อเล็งตรง · แสงปากป้อม/แรงถอยเมื่อยิง · แสดงวงระยะเมื่อเลือกป้อม · `apply_upgrade` |
| `scripts/projectile.gd` | ลูกธนู / ลูกระเบิด splash / ลูกเวทที่ทะลุเกราะ |
| `scripts/hero.gd` | ฮีโร่ Kubi ตามระบบด้านบน · แถบเลือดเหนือหัว |
| `tools/` | เครื่องมือ + **สูทเทสอัตโนมัติ** (ดูส่วนถัดไป) |

## ระบบเทสอัตโนมัติ (มาตรฐาน repo — เกม 1 อ้างแพยจบ)

รันจากราก repo:

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source # หรือระบุ path ของ Godot 4.7.2 เอง
$proj  = "games/game2_tower_defense"
$root  = (Resolve-Path .).Path
foreach ($t in @('test_menu','test_menu2','test_t3','test_t4','test_keys','test_t5','test_t6','test_t7')) {
  & $godot --headless --path $proj --script (Join-Path $root "games\game2_tower_defense\tools\$t.gd")
  if ($LASTEXITCODE -ne 0) { throw "Game 2 test failed: $t" }
}
```

ถ้าเป็น checkout ใหม่ ให้ import ก่อนหนึ่งครั้งด้วย `& $godot --headless --path $proj --import` แล้วจึงรันชุดเทส ข้อพิสูจน์ = ทุก test จบด้วย `PASS` และ exit 0. ภาพจอจริง:

```powershell
& $godot --path games/game2_tower_defense --script (Join-Path $root "games\game2_tower_defense\tools\shot_debug.gd")
# เปิดเกมจริง + สั่งประกอบฉาก (ป้อมลาน1 + ป้าเมนูค้าง) + เซฟจอจริง temp PNG แล้วออก
```

| สูท | ตรวจอะไร |
|---|---|
| `tools/test_t3.gd` | ป้อมธนู/ปืนใหญ่ → ยิง → ตาย → ทองเพิ่มจริง · splash ปืนใหญ่ |
| `tools/test_menu2.gd` | คลิกจำลองผ่าน handler (headless ไม่มี OS input) |
| `tools/test_t4.gd` | weighted waves + โบนัสเรียกก่อน (ต่างมากตามที่คาด) |
| `tools/test_keys.gd` | กด 1-4 เปิดเมนูลาน → เลือกปุ่มกดป้องกัน/menu sync |
| `tools/test_t5.gd` | สร้าง/อัปเกรด/ขายป้อม · ตรวจลำดับวาดป้อมลาน 3 · ฮีโร่ฟาด/โดนรุม/ตาย/เกิดใหม่ |
| `tools/test_t6.gd` | ซื้อป้อมเวท · ตรวจเกราะโกเลมหิน · ยืนยันกระสุนเวทกำจัดโกเลมได้ |
| `tools/test_t7.gd` | ยืนยันว่าอาวุธนักธนู/ปืนใหญ่/เวท หมุนเล็งเป้าคนละทิศได้ถูกต้อง |

## บทเรียนเทคนิคพิสูจน์แล้ว (ห้ามลืม — ใช้เกม 3)

1. **ยืนยันภาพจอก่อนยิงโค้ด** — `tools/shot_debug.gd` ให้แคปจอเจริญเสียง (บั๊กวงทอง/เมนูถูกกักสามัญแก้มืนมาหลายรอบ จบเมื่อดูจอจริง); อ่านที่ `docs/game2_tower_defense/GDD.md` บันทึก T5.2
2. **DPI 125%**: `event.position` เป็นพิกัดหน้าต่างสเกล ไม่ใช่โลก — แก้ระบบ 3 ชั้น (get_global_mouse_position ฯลฯ) + **ทางลัดคีย์บอร์ด 1-4 เปิดเมนูลานเสมอ ปลอดภัย DPI** (บันทึก T3.1)
3. **ลูกโหนกวาดทับแม่** ใน Godot 2D: งานวาดใน `main._draw()` ถูก Background (ลูก) วาดทับเสมอ — overlay ต้องเป็นโหนดลูกของตัวเอง + `z_index`
4. **y-sort หัวข้อผิดจังหวะ**: เมนู (CanvasItem) ถูกจัดระยะตาม y — ป้าเมนูต้อง `z_index = 100` ไม่พึ่ง y
5. **enum/คนละสคริปต์** เทียบไม่เข้ากัน — ใช้ const int ร่วม
6. `TextureButton` ต้อง `ignore_texture_size` (ไม่ใช่ `expand_mode` ของ TextureRect)
7. `@warning_ignore("integer_division")` ในจุดหาร int ตั้งใจ (จอคอนโซลสะอาด)
8. **pixellab**: animate-pixminimax ไม่หมุนตัว → gen ภาพนิ่งมุมที่ต้องการก่อน; `create-image-pixen` view enum รับแค่ `side/low top-down/high top-down`; timeout ≥ 90 วิ (ดู [`../MCP_SETUP.md`](../MCP_SETUP.md))
