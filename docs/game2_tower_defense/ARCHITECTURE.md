# สถาปัตยกรรม — หอคอยคู่ฟ้า (Kub Kingdom Rush) · เกม 2

GDD อยู่ที่ [GDD.md](GDD.md) · รายละเอียด asset/art [ASSETS.md](ASSETS.md) · key/โควตา [../ASSET_MANIFEST.md](../ASSET_MANIFEST.md)

**สถานะ: รอบ 12 ชม. (2026-10-31) — Phases A–E ครบ; อัปเดต 2026-11-01** — เพิ่ม Map C prototype และถอดฐานตายตัวทั้งสี่จุดออก; วางป้อมอิสระเป็นวิธีเดียว

## วิธีเล่น (โครงเกม ปิดปัจจุบัน)

- เปิดเกมได้ขึ้น **หน้า title "หอคอยคู่ฟ้า"** — เลือกแผนที่: **ป่า Kubi** (map A) หรือ **สุสานหลวง** (map B: มอนงัดจากสุสานซ้ายบน (258,140) ถนนเลี่ยงสระเข้าประตูปราสาทหลวง (850,380)); ปุ่มบน title แสดงสถิติคลื่นสูงสุดของแผนที่นั้น + ★ถ้าผ่าน
- map A: มอนเดิน PATH_A จากประตูม่วงซ้ายบน `(258,190)` ทางวน 9 ช่วง → ประตูปราสาท `(810,450)` (~1,272 px)
- ไม่มีฐานตายตัว: กด **B** แล้วคลิกพื้นเพื่อเปิดเมนูสร้างป้อมทุกแผนที่; พื้นที่วางยกเว้นถนน ประตู และบริเวณใกล้ป้อมอื่น · **นักธนู 90** / **ปืนใหญ่ 150** / **ป้อมเวท 130** / **ค่ายทหาร 110** ทอง
- เริ่มทอง 0; เลือก Kubi หรืออัศวินดาบแสงก่อนแผนที่ แล้วใช้ฮีโร่รับ bounty เป็นทุนตั้งต้น · **B** + คลิกพื้นหญ้า = วางป้อมอิสระ (ห้ามถนน/ประตู/ป้อมซ้อน)
- อัปเกรด Lv2 ทุกสาย · ขายคืน 60% · **พรีวิวคลื่นถัดไป** แสดงชิ้นเดียวแบบไอคอน+จำนวน+จุดอ่อนชนิด
- **โหมดเล็งต่อป้อม 4 แบบ** (ปุ่ม "เล็ง" ในเมนู / คีย์ 4): ใกล้ปราสาท / นำหน้า (เพิ่งเข้าวง) / ชี้เป้าหนัก (max_hp) / เก็บเศษ (เลือดปัจจุบันน้อยสุด)
- **คลื่น 2 รอบ**: คลื่น 1 = กองรัว 100 ตัว (กบ 40 นำ + กิ้งก่า/สไลม์/โกเลม/แชแมน/ค้างคาว อย่างละ 12, เกิด 0.42 วิ/ตัว) · คลื่น 2 = ทุกชนิดรวม 77 + บอส KUBIT 3 ตัว (เลือดโป่ง + ทอง 250 + สังหรณ์แดง) — เก็บตามคำขอผู้เล่น
- เรียกคลื่นก่อนได้โบนัสต่อวิ (ปุ่มมุมขวาบน / คีย์ N) · จบเกมสรุป **ฆ่า X ตัว · ทองรวม Y · คลื่น Z/8 + "สถิติใหม่!"** แล้วบันทึกคลื่นสูงสุดรายแผนที่ลง `user://td_best.json` (atomic)
- ฮีโร่: คลิกขวาเดิน/สั่งไล่ศัตรู · ฟาดอัตโนมัติรัศมี 120 · เกิดใหม่หน้าปราสาทของแผนที่ปัจจุบัน (`hero.home` = จุดสุดท้ายของถนน) ใน 8 วิ

## โครงไฟล์โค้ด (เก็บที่ `games/game2_tower_defense/`)

| ไฟล์ | หน้าที่ |
|---|---|
| `scenes/main.tscn` + `scripts/main.gd` | จุดเข้าเกม — สถานะ `title → prep ⇄ wave → won/lost` · แผนที่และเส้นทาง · วางป้อมอิสระด้วย B (กันถนน/ประตู/ป้อมซ้อน) · spawner มอน 7 ชนิด · คลื่น 2 รอบ (`WAVES` + `WAVE_GAPS` ต่อคลื่น) · ทอง + bounty · save สถิติ best atomic · HUD · เมนูสร้าง/อัปเกรด/ขาย + โหมดเล็ง · juice · จอชนะ/แพ้ + สถิติ |
| `scripts/enemy.gd` | waypoint walker carry leftover · ชุดท่าหันข้าง/หน้าตรง · **ค้างคาวบิน `flying`** (เป้าโดนเฉพาะธนู/เวท) · **สไลม์ `split_kind/split_count`** (ตาย→จิ๋วเดินต่อจากจุดตายด้วย waypoint ที่เหลือ) · **แชแมน `heal_radius/heal_interval`** (ออร่าเขียว + วง) · **บอส** ยึดเท้ากับพื้น พร้อมหายใจ/ก้าว/ฟันและเอฟเฟกต์ฟัน · กริดสัญญาณ `reached_castle/died` |
| `scripts/tower.gd` | สายป้อม 4 ชนิด (ในนี้: ธนู/ปืนใหญ่/เวท + ค่ายทหาร บล็อกมอนด้วยทหาร + rally) · **โหมดเล็ง 4 แบบ (`targeting` + `cycle_targeting()` + `_pick_target()` คะแนนตามโหมด; ปืนใหญ่กรอง `flying` ทุกโหมด)** · อาวุธหมุนลื่น + ยิงเมื่อล็อก · `apply_upgrade` · ขายคืน 60% |
| `scripts/projectile.gd` | ธนู / ระเบิด splash + **อนุภาคปะทุ (CPUParticles2D one-shot)** / เวททะลุเกราะ |
| `scripts/hero.gd` | Kubi: คลิกขวาเดิน/ไล่ศัตรู · ดาบแยกชิ้นขยับฟันพร้อมรอยดาบ · bounty · **`home` map-aware** (เกิดใหม่ที่จุดสุดท้ายของถนนแผนที่ปัจจุบัน) |
| `scripts/hero_blade.gd` | ฮีโร่ทางเลือกอัศวินดาบแสง · วาดท่าแขน มือ และดาบร่วมกัน · แสงฟันสีฟ้าขาวและประกาย · ใช้ movement/combat ของ Hero ร่วมกัน |
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
| `test_t4` | 2 คลื่น (กองรัว 100 + บอส 3) + เลือดโต 1.15^n + โบนัสเรียกก่อน + won/lost (**คืนไฟล์เซฟผู้เล่นหลังจบ — เพราะ `_game_over` บันทึก best จริง**) |
| `test_menu2`/`test_menu`/`test_keys` | คลิก/คีย์ผ่าน `_unhandled_input` headless (เรียก `_start_map(0)` ทำสีเขียวหลัง `_ready` จบ) |
| `test_t5` | ทอง 0 · สร้างป้อมอิสระ/อัปเกรด/ขาย · ฮีโร่ ฟาด/โดนรุม/เกิดใหม่ |
| `test_t6` | เวท vs โกเลมเกราะ |
| `test_t7` | อาวุธหมุนเล็งต่อทิศ |
| `test_t8` | ค่ายทหาร + ทหารบล็อก + respawn (Phase B) |
| `test_t9` | ค้างคาว/สไลม์แตก/แชแมนฮีล/บอส + บอสสุดท้ายคลื่น 2 (Phase C) |
| `test_t10` | โหมดเล็ง 4 แบบ + กรองบิน + พรีวิวไอคอน (Phase D) |
| `test_t11` | title ปิดอินพุต / `_start_map` A / B (ประตูสุสาน-ปราสาท-hero.home) / มอนเดิน PATH_B จนรั่ว / record_best + atomic + load (**คืนไฟล์เซฟผู้เล่น**) (Phase E) |

## บทเรียนเทคนิคพิสูจน์แล้ว (ห้ามลืม — ใช้ในเกมถัดไป)

1. **ยืนยันภาพจอก่อนยิงโค้ด** — `tools/shot_debug.gd` แคปจอจริง (บั๊ก z-order/เมนูจบเมื่อดูจอจริง)
2. **DPI 125%**: `event.position` เป็นพิกัดหน้าต่างสเกล — ระบบ 3 ชั้นแปลงพิกัดคลิกให้ตรง viewport
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
