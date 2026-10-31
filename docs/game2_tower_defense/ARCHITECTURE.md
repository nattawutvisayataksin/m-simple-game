# สถาปัตยกรรม — หอคอยคู่ฟ้า (Kub Kingdom Rush) · เกม 2

GDD อยู่ที่ [GDD.md](GDD.md) · รายละเอียด asset/art [ASSETS.md](ASSETS.md) · key/โควตา [../ASSET_MANIFEST.md](../ASSET_MANIFEST.md)

**สถานะ: รอบ 12 ชม. (2026-10-31) — Phases A–E ครบ** — เสียงเกมครบ, ค่ายทหาร, มอนใหม่ 3 + บอส + คลื่น 13 รอบ, พรีวิวคลื่น + โหมดเล็ง 4 แบบ + juice, แผนที่ 2 แผน + หน้า title เลือกแผนที่ + save สถิติ atomic; **สูทเทส 12/12 PASS**

## วิธีเล่น (โครงเกม ปิดปัจจุบัน)

- เปิดเกมได้ขึ้น **หน้า title "หอคอยคู่ฟ้า"** — เลือกแผนที่: **ป่า Kubi** (map A) หรือ **สุสานหลวง** (map B: มอนงัดจากสุสานซ้ายบน (258,140) ถนนเลี่ยงสระเข้าประตูปราสาทหลวง (850,380)); ปุ่มบน title แสดงสถิติคลื่นสูงสุดของแผนที่นั้น + ★ถ้าผ่าน
- map A: มอนเดิน PATH_A จากประตูม่วงซ้ายบน `(258,190)` ทางวน 9 ช่วง → ประตูปราสาท `(810,450)` (~1,272 px)
- สร้างป้อม 4 ลาน (คลิกฐาน/กด 1-4): **นักธนู 90 ทอง** / **ปืนใหญ่ 150 ทอง** (ระเบิดโดยรอบ) / **ป้อมเวท 130 ทอง** (ทะลุเกราะ) / **ค่ายทหาร 110 ทอง** (Lv2 ทหาร 2 ตน — ทหารบล็อกมอนตรงหน้า; คลิกเลื่อนจุดยืนรัลลี่ ปุ่ม 3)
- เริ่มทอง 0; ฮีโร่ Kubi ต้องฟาดมอนรับ bounty เป็นทุนตั้งต้น · **B** + คลิกพื้นหญ้า = วางป้อมอิสระ (ห้ามถนน/ประตู/ป้อมซ้อน)
- อัปเกรด Lv2 ทุกสาย · ขายคืน 60% · **พรีวิวคลื่นถัดไป** แสดงชิ้นเดียวแบบไอคอน+จำนวน+จุดอ่อนชนิด
- **โหมดเล็งต่อป้อม 4 แบบ** (ปุ่ม "เล็ง" ในเมนู / คีย์ 4): ใกล้ปราสาท / นำหน้า (เพิ่งเข้าวง) / ชี้เป้าหนัก (max_hp) / เก็บเศษ (เลือดปัจจุบันน้อยสุด)
- **คลื่น 13 รอบ hard-counter**: 4 ค้างคาว (ปืนใหญ่/ทหาร/ระเบิดทั้งหมดแถม — ต้องธนู/เวท), 5 สไลม์ (ตายแตก 2 จิ๋วเดินต่อ), 7+ แชแมน (ฮีลออร่า 95px ทุก 2.2 วิ ฆ่าตัวนำให้ไว), 13 บอส KUBIT (เลือดโป่ง + ทอง 250 + สังหรณ์แดง); โกเลมเกราะกายภาพ 65% — เวททะลุ
- เรียกคลื่นก่อนได้โบนัสต่อวิ (ปุ่มมุมขวาบน / คีย์ N) · จบเกมสรุป **ฆ่า X ตัว · ทองรวม Y · คลื่น Z/13 + "สถิติใหม่!"** แล้วบันทึกคลื่นสูงสุดรายแผนที่ลง `user://td_best.json` (atomic)
- ฮีโร่ Kubi: คลิกขวาเดิน/สั่งไล่ศัตรู · ฟาดอัตโนมัติรัศมี 120 · เกิดใหม่หน้าปราสาทของแผนที่ปัจจุบัน (`hero.home` = จุดสุดท้ายของถนน) ใน 8 วิ

## โครงไฟล์โค้ด (เก็บที่ `games/game2_tower_defense/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `scenes/main.tscn` + `scripts/main.gd` | จุดเข้าเกม — สถานะ `title → prep ⇄ wave → won/lost` · **สเต็บแผนที่ (`MAPS` const + `_start_map()`)** สลับพื้นหลัง (scale อัตโนมัติ 1152÷กว้าง tex) / ถนน / ลาน / ประตู-ปราสาท / hero.home · หน้า title CanvasLayer 25 (ปิดอินพุตเกมระหว่าง title) · วาดถนน waypoint · spawner มอน 7 ชนิด · คลื่น 13 รอบ (`WAVES`) · ทอง 0 + bounty · **save สถิติ best atomic (`_load_best/_save_best/_record_best`)** · HUD (ชีวิต/ทอง/คลื่น/พรีวิวไอคอน/ปุ่มเรียกคื่้น) · ฐานหกเหลี่ยม + วางอิสระ B · เมนูสร้าง/อัปเกรด/ขาย + ปุ่มโหมดเล็ง · juice (`juice_shake`, อนุภาคระเบิด, ขอบแดง) · จอชนะ/แพ้ + บล็อกสถิติ |
| `scripts/enemy.gd` | waypoint walker carry leftover · ชุดท่าหันข้าง/หน้าตรง · **ค้างคาวบิน `flying`** (เป้าโดนเฉพาะธนู/เวท) · **สไลม์ `split_kind/split_count`** (ตาย→จิ๋วเดินต่อจากจุดตายด้วย waypoint ที่เหลือ) · **แชแมน `heal_radius/heal_interval`** (ออร่าเขียว + วง) · **บอส** hp โป่ง + สเกล 2.1 + แถบเลือดแดง · กริดสัญญาณ `reached_castle/died` |
| `scripts/tower.gd` | สายป้อม 4 ชนิด (ในนี้: ธนู/ปืนใหญ่/เวท + ค่ายทหาร บล็อกมอนด้วยทหาร + rally) · **โหมดเล็ง 4 แบบ (`targeting` + `cycle_targeting()` + `_pick_target()` คะแนนตามโหมด; ปืนใหญ่กรอง `flying` ทุกโหมด)** · อาวุธหมุนลื่น + ยิงเมื่อล็อก · `apply_upgrade` · ขายคืน 60% |
| `scripts/projectile.gd` | ธนู / ระเบิด splash + **อนุภาคปะทุ (CPUParticles2D one-shot)** / เวททะลุเกราะ |
| `scripts/hero.gd` | Kubi: คลิกขวาเดิน/ไล่ศัตรู · ฟาดอัตโนมัติ + bounty · **`home` map-aware** (เกิดใหม่ที่จุดสุดท้ายของถนนแผนที่ปัจจุบัน) |
| `scripts/sfx.gd` | เพลง 2 อารมณ์ crossfade + SFX 14 ชิ้น (สังเคราะห์ใน `tools/generate_td_audio.ps1`) |
| `tools/` | เครื่องมือ + **สูทเทสอัตโนมัติ 12 ชุด** (ดูส่วนถัดไป) |

## ระบบเทสอัตโนมัติ (มาตรฐาน repo)

รันจากราก repo (`shared/find_godot.ps1` หา Godot ของเครื่องนี้ หรือใช้ path ตรง):

```powershell
$godot = (Get-Command godot -ErrorAction Stop).Source # หรือระบุ path ของ Godot 4.7.2 เอง
$proj  = "games/game2_tower_defense"
$root  = (Resolve-Path .).Path
foreach ($t in @('test_t3','test_t4','test_keys','test_t5','test_t6','test_t7','test_menu','test_menu2','test_t8','test_t9','test_t10','test_t11')) {
  & $godot --headless --path $proj --script (Join-Path $root "games\game2_tower_defense\tools\$t.gd")
  if ($LASTEXITCODE -ne 0) { throw "Game 2 test failed: $t" }
}
```

ถ้าเป็น checkout ใหม่ ให้ import ก่อนหนึ่งครั้งด้วย `& $godot --headless --path $proj --import` แล้วจึงรันสูท ข้อพิสูจน์ = ทุก test จบด้วย `PASS` ไม่มี `FAIL` และ exit 0 · ภาพจอจริง: `--script tools/shot_debug.gd` (ไม่ headless) แคป PNG ตรวจการเจริญพันธุ์ของฉากด้วยตา

| สูท | ตรวจอะไร |
|---|---|
| `test_t3` | ธนู/ปืนใหญ่ยิง→ตาย→ทอง · splash |
| `test_t4` | 13 คลื่น + เลือดโต 1.15^n + โบนัสเรียกก่อน + won/lost (**คืนไฟล์เซฟผู้เล่นหลังจบ — เพราะ `_game_over` บันทึก best จริง**) |
| `test_menu2`/`test_menu`/`test_keys` | คลิก/คีย์ผ่าน `_unhandled_input` headless (เรียก `_start_map(0)` ทำสีเขียวหลัง `_ready` จบ) |
| `test_t5` | ทอง 0 · คลิก 4 ลาน · สร้าง/อัปเกรด/ขาย · วางอิสระ · ฮีโร่ ฟาด/โดนรุม/เกิดใหม่ |
| `test_t6` | เวท vs โกเลมเกราะ |
| `test_t7` | อาวุธหมุนเล็งต่อทิศ |
| `test_t8` | ค่ายทหาร + ทหารบล็อก + respawn (Phase B) |
| `test_t9` | ค้างคาว/สไลม์แตก/แชแมนฮีล/บอส + ตารางคลื่น 13 รอบ (Phase C) |
| `test_t10` | โหมดเล็ง 4 แบบ + กรองบิน + พรีวิวไอคอน (Phase D) |
| `test_t11` | title ปิดอินพุต / `_start_map` A / B (ประตูสุสาน-ปราสาท-hero.home) / มอนเดิน PATH_B จนรั่ว / record_best + atomic + load (**คืนไฟล์เซฟผู้เล่น**) (Phase E) |

## บทเรียนเทคนิคพิสูจน์แล้ว (ห้ามลืม — ใช้เกม 3)

1. **ยืนยันภาพจอก่อนยิงโค้ด** — `tools/shot_debug.gd` แคปจอจริง (บั๊ก z-order/เมนูจบเมื่อดูจอจริง)
2. **DPI 125%**: `event.position` เป็นพิกัดหน้าต่างสเกล — ระบบ 3 ชั้น + ทางลัดคีย์ 1-4 ปลอดภัย DPI
3. **ลูกวาดใน `_draw()` โดน Background (ลูก) ทับเสมอ** — overlay ต้องเป็นโหนดลูก + `z_index`
4. **y-sort**: ป้าเมนูต้อง `z_index = 100` (ไม่พึ่ง y)
5. **enum คนละสคริปต์** ไม่เข้ากัน — ใช้ const int
6. `TextureButton` ต้อง `ignore_texture_size`
7. `@warning_ignore("integer_division")` จุดหาร int ตั้งใจ
8. **pixellab**: view enum รับแค่ `side/low top-down/high top-down`; no_background อนุญาต canvas ≤65,536px²; timeout ≥ 90 วิ
9. **`FileAccess` ไม่ `close()` = Windows file lock** ทำ `DirAccess.remove_absolute/rename_absolute` พังแบบเงียบ ๆ (save atomic/เทส restore ต้องปิดทุก handle — จับได้จาก test_t11 phase restore)
10. **SceneTree `_initialize` รันก่อนฉาก `_ready`** — โหนดลูก (layers/หอพ เงียบระดับ) ยังไม่ถูกสร้าง; สั่งงานฉากต้องเริ่มเลื่อนไปเฟรมแรกของ `_process` (test_t4/t5/keys/menu/menu2 ผ่าน pattern `_main._start_map(0)` เฟรมแรก)
11. **เทสที่ถูกระบบเซฟ**: `_game_over` เรียก `_record_best` (บันทึกจริง = เทสเปลืองไฟล์ผู้เล่น) — ทุกเทสที่สั่งจบเกม/record ต้อง backup+restore `user://td_best.json` เสมอ (test_t4/test_t11)
12. **พื้นหลัง gen เล็กครอบจอได้**: scale = 1152÷ความกว้าง tex อัตโนมัติ — ประหยัดโควตา my gen (256×144 จอเต็มคมพอสำหรับ TD)
