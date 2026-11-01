# ARCHITECTURE — แท็กซี่คู่ฟ้า (game4_crazy_kab)

> สไตล์เดียวกับเกม 2: โค้ดใน `scripts/main.gd` เป็นหลัก + ไฟล์ระบบรองแยก, เทส SceneTree headless ที่ `tools/`

## โครงโฟลเดอร์

```
games/game4_crazy_kab/
  project.godot          # 1152×648, stretch canvas_items (pattern เกม 2)
  scripts/main.gd        # title/menu ทุกจอ (เรื่อง/วิธีเล่น/คู่มือ) + ตัวจัดการ scene
  scripts/play.gd        # ห้องเล่น (เกิด map, HUD, เข็มเวลา 120 วิ)
  scripts/car.gd         # ฟิสิกส์อาร์เคดรถ (CAR_DEFS 3 คัน)
  scripts/passenger.gd   # ผู้โดยสาร + เวลาต่อรอบ + จุดส่ง
  scripts/hazard.gd      # สไลม์/โกเลม/near-miss
  scripts/save.gd        # user://taxi_best.json atomic
  tools/test_*.gd        # SceneTree headless, exit 0/1
  tools/shot_debug.gd    # แคปจอจริง
  assets/sprites/  audio/
docs/game4_crazy_kab/    # GDD/ROADMAP/PLAYER_GUIDE/ASSETS
```

## สถานะเกม (Play state)

- `state`: `"title" | "story" | "howto" | "guide" | "play" | "over"` — ทุกจอเขียนด้วยโค้ดล้วน (สไตล์ top-down HUD เดียวกับเกม 2)
- Play: `time_left` เริ่ม 120.0 วิ · `cash` เริ่ม 0 · `rides_ok / rides_fail` · combo ทิป
- ผู้โดยสาร spawn ตรงจุดป้ายข้ามถนน — จุดส่งเลือกจาก POI ระยะไม่ชนกับจุดรับ

## การต่อกันของไฟล์

- `main.gd` spawn `play.gd` (Node2D) หนึ่งตัวต่อหนึ่ง
- `car.gd` เป็น `CharacterBody2D` ชนผนังแผนที่ (StaticBody2D ขอบถนน)
- สัญญาณ: `passenger.delivered(ok, fare)` → `play.gd` เพิ่มเงิน/นับรอบ (ต่อกันแบบ signal กระจายเดิมของ repo)

## เทส pattern (เหมือนเกม 2)

- SceneTree + `_initialize` อ่านปรับให้ (`_process` frame แรกค่อย layout) — exit code = fail count
- เทส touch save จริง: backup → run → restore
