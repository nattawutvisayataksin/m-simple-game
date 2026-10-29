# Asset Manifest — ชิงเหรียญทอง (Coin Rush)

```json
{
  "project": "m-sample-game (Ching Lian Thong / Coin Rush)",
  "notes": "Pixellab: 2 keys ให้ใช้อิสระเมื่อต้องการ (Key A = session MCP; Key B = .mcp.json, REST v2 มี 40 gen ว่าง) — รายละเอียด docs/ART_DIRECTION.md §3",
  "anim_cost_record": "2026-10-29: coin 8f + player 8f + enemy 8f = 3 gen (Key B ok, เหลือ 37/40) — เฟรมจริง 9 ไฟล์/ชุด + spritesheet ผูกในฉากแล้ว",
  "session_handoff": "2026-10-29: ทดสอบเกมบนเครื่องผู้ใช้ผ่าน (Godot 4.7.2 ติดตั้งแล้ว, path ใน .mcp.json GODOT_PATH แก้เรียบร้อย — ต่อเครื่องใหม่อ่าน HOME_SETUP ข้อ 3-4) ถัดไป: ระยะ C ชุดท้าย (tileset กำแพง/พื้น, HUD icon+ฟอนต์, เพลง) → ระยะ B",
  "next_steps": [
    "Phase C ท้าย: tileset กำแพง/พื้น ธีม KUB (main.tscn ยังใช้ Polygon2D สีล้วนอยู่) — ใช้โควตา Key B ได้",
    "Phase C ท้าย: HUD icon เหรียญ + ฟอนต์, เพลงประกอบ + audio bus",
    "Phase B: ความยาก เพิ่มไวรัสตามเวลา, เหรียญทอง 3 คะแนน (coin_kub_gold) ตาม manifest นี้",
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
    "player.tscn: Polygon2D -> replace with Sprite2D after approval",
    "coin.tscn: Polygon2D -> replace with Sprite2D + AnimatedSprite2D",
    "enemy.tscn: Polygon2D -> replace with Sprite2D",
    "main.tscn: wall Polygon2D -> keep or wall tileset (later)"
  ]
}
```
