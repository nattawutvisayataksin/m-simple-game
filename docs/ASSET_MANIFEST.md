# Asset Manifest — ชิงเหรียญทอง (Coin Rush)

```json
{
  "project": "m-sample-game (Ching Lian Thong / Coin Rush)",
  "notes": "Pixellab: 2 keys ให้ใช้อิสระเมื่อต้องการ (Key A = session MCP, หลักหมดแต่ daily bonus ใช้ได้จริง; Key B = .mcp.json เหลือ 37/40) — รายละเอียด docs/ART_DIRECTION.md §3",
  "anim_cost_record": "2026-10-29: coin 8f + player 8f + enemy 8f = 3 gen (Key B ok, เหลือ 37/40) — เฟรมจริง 9 ไฟล์/ชุด + spritesheet ผูกในฉากแล้ว",
  "tileset_cost_record": "2026-10-29: kub_arena_sheet (16 tiles 32×32) = 1 gen (Key A daily bonus, available-เหลือ 4 วันนี้) — ผูกใน main.tscn (พื้น + กำแพง 4 ด้าน, กำแพง เข้าตา 40→32px ยึด grid) ทดสอบ headless ผ่าน",
  "session_handoff": "2026-10-29: ระยะ C tileset เสร็จ (headless ผ่าน) ถัดไป: HUD icon+ฟอนต์ → เพลง bus → ระยะ A (เหรียญทอง 3pts ฯลฯ) → ระยะ B",
  "next_steps": [
    "Phase C ท้าย: HUD icon เหรียญ + ฟอนต์, เพลงประกอบ + audio bus",
    "Phase A: ระยะ A polish — เหรียญทอง 3 คะแนน (edit coin image ลด gen), เวลา ≤10 วิ ตัวเลขแดง, ปิดเหรียญหลังจบรอบ",
    "Phase B: ความยาก เพิ่มไวรัสตามเวลา",
    "ระวัง: ห้ามฝัง key ในไฟล์ commit — key อ่านจาก .mcp.json (gitignored) เท่านั้น"
  ],
  "art_direction_doc": "docs/ART_DIRECTION.md",
  "engine": "godot-4.7",
  "created": "2026-10-29",
  "assets": [
    {
      "id": "coin_kub",
      "role": "pickup",
      "size": "32x32",
      "pivot": "center",
      "frames": 9,
      "anim_planned": "spin 9f DONE (coin_sheet.png, hframes=9 wired, frame-loops in coin.gd)",
      "source": "pixellab.pixflux gen#1 · gallery:5d62a5a3-9d1d-5edb-8beb-b8af707eba6f",
      "path": "assets/art/sprites/coin_kub.png",
      "license": "self-generated (pixellab subscription)",
      "approval": "approved-by-user 2026-10-29 (visual check)"
    },
    {
      "id": "player_kubi",
      "role": "character",
      "size": "32x32",
      "pivot": "center",
      "frames": 9,
      "anim_planned": "walk 9f DONE (player_sheet.png, frame 0=stand, 1-8=walk wired in player.gd)",
      "source": "pixellab.pixflux gen#2 · gallery:46c1a8be-5ce5-56ff-960b-0c96b52b419f",
      "path": "assets/art/sprites/player_kubi.png",
      "license": "self-generated (pixellab subscription)",
      "approval": "approved-by-user 2026-10-29 (visual check)"
    },
    {
      "id": "enemy_glitch",
      "role": "deadly-obstacle",
      "size": "32x32",
      "pivot": "center",
      "frames": 9,
      "anim_planned": "pulse-spark 9f DONE (enemy_sheet.png wired in enemy.gd + enemy.tscn)",
      "source": "pixellab.pixflux gen#4 · gallery:e2302782-54d8-53ff-88ab-9cc064b41c3d",
      "path": "assets/art/sprites/enemy_glitch.png",
      "license": "self-generated (pixellab subscription)",
      "approval": "approved-by-user 2026-10-29 (visual check)"
    },
    {
      "id": "kub_arena_tileset",
      "role": "tileset-walls-floor",
      "size": "16 tiles 32x32 (sheet 128x128)",
      "pivot": "tiled (Sprite2D region + texture_repeat)",
      "tiles_used": "พื้นล้วน bbox(64,32), กำแพงล้วน bbox(0,96) — ต่อนาย metadata ใน .json ใช้ต่อ autotile ได้",
      "source": "pixellab topdown tileset (Key A daily bonus) · job d54165fd-d47f-4653-bfb3-74e500386934",
      "path": "assets/art/gen/kub_arena_sheet.png",
      "license": "self-generated (pixellab subscription)",
      "approval": "approved-by-user 2026-10-29 (เห็นภาพตัวอย่างแผนที่)"
    },
    {
      "id": "coin_kub_gold",
      "role": "pickup-special",
      "size": "32x32",
      "pivot": "center",
      "frames": 1,
      "note": "This-gold-silver special 3pts (Phase A) - can be obtained by editing the coin image with edit_image, reduce gen",
      "source": "edit of coin_kub (planned)",
      "path": "assets/art/concept/coin_kub_gold.png",
      "license": "derived",
      "approval": "not-started"
    }
  ],
  "placeholders_in_scenes": [
    "main.tscn: wall Polygon2D -> DONE (Sprite2D tileset 32px grid + collision 1152x32/32x648; พื้น ColorRect -> Sprite2D tile)",
    "player.tscn / coin.tscn / enemy.tscn: เสร็จแล้วทั้งหมด — ปัจจุบันไม่มี placeholder ในฉาก"
  ]
}
```
