# Asset Manifest — ชิงเหรียญทอง (Coin Rush)

```json
{
  "project": "m-sample-game (Ching Lian Thong / Coin Rush)",
  "notes": "Pixellab: 3 keys ให้ใช้อิสระเมื่อต้องการ (Key A หมด 50/40 รอ bonus รื้นรายวัน, Key B เหลือ 16/40, Key C เต็ม 40 + bonus 5) — key ฝังใน global config ~/.config/opencode/opencode.json นอก repo (รายละเอียดเชื่อมโยง docs/MCP_SETUP.md) — รายละเอียด docs/game1_coin_rush/ART_DIRECTION.md §3",
  "anim_cost_record": "2026-10-29: coin 8f + player 8f + enemy 8f = 3 gen (Key B ok, เหลือ 37/40) — เฟรมจริง 9 ไฟล์/ชุด + spritesheet ผูกในฉากแล้ว",
  "tileset_cost_record": "2026-10-29: kub_arena_sheet (16 tiles 32×32) = 1 gen (Key A daily bonus, available-เหลือ 4 วันนี้) — ผูกใน main.tscn (พื้น + กำแพง 4 ด้าน, กำแพง เข้าตา 40→32px ยึด grid) ทดสอบ headless ผ่าน",
  "music_record": "2026-10-29: music.wav chiptune loop 13.7s สังเคราะห์เองใน tools/generate_music.ps1 (ฟรี ไม่ใช้ gen) + bus Music/SFX (default_bus_layout.tres) + HUD icon ใช้ coin_kub.png ซ้ำ — ฟอนต์จริง process: หยุด (create_font Latin-only, ใช้ LabelSettings)",
  "gold_record": "2026-10-29: coin_gold (edit 1 gen) + goldcoin_sheet 9f (anim 1 gen) + ไวรัสเขียว/น้ำเงิน (edit ตัวละ 1 gen) = 4 gen รวม — หมด daily bonus Key A วันนี้ (used 50/40; ยืนยันด้วยการยิงจริงคืน error 'no generations or credits') ; ไวรัส 2 สีเก็บไว้ใช้ระยะ B",
  "keyb_record": "2026-10-29: MCP `pixellab-b` (Key B) — balance จริงตอนนี้: used 34 remaining **6/40** (10 gen ถูกใช้จริงใน T4.1: submit ที่ timeout ตาม timeout 30s x1 + gen 9 ชิ้น/things — คำเตือน: create-image-pixen แบบ REST นั้น synchronous กลับมาเป็น inline base64 ใน response นาน 30-40 วิ ต้อง timeout >= 90s ถึงจะไม่โดนเผาโควต้าเปลี่ยน ใช้ tools/gen_pixen.ps1), รายการสำคัญวันนี้: T1/T2 (พื้นหลัง ecb637c9, ฮีโร่+anim e285f2e8, กบ ddf520f0, กิ้งก่าหันข้าง 56d4f5e0, ป้อมนักธนู 5801ea35, ป้อมปืนใหญ่ faf8a0e4) + bg v2 5d0fffcf + quadrant ล้ม 4 + แผงทุ่งหญ้า 796a3559 + anim เดิน กบ f476bf24 / กิ้งก่าหันข้าง 51facc93 / กิ้งก่าหน้าตรง: ภาพนิ่ง af1584b6 + anim 27961c75 (ทดลองหมุนตัวหันข้าง→หน้าตรงล้ม b784c4e9 = บทเรียนบันทึกไว้ใน GDD2 แล้ว) — ท่องไว้: 1 job/key ช่วงเดียว, cooldown ~45วิ, อยากได้องศาที่ไม่มีต้อง gen องศานั้นก่อนเสมอ",
  "keys_status_record": "2026-10-29: สถานะ key ยืนยัน get_balance ล่าสุด — Key A (44b00e80): หมด 50/40 (remaining 0, รอ bonus รื้น) · Key B (pixl_9ca): 16/40 · Key C (pixl_0b5): 40/40 + โบนัสรายวัน 5 (โน้ตจาก API: bonus รื้นทุกคืน +5 สูงสุด 20 และคือค่างวดเดียวกับ plan ไม่ใช่สองเท่า) — ลำดับการใช้ต่อจากนี้: ใช้ Key C ก่อน (โควตาใหม่เต็ม) แล้วค่อยไล่ Key B → A",
  "game2_t5_record": "2026-10-29: T5 ฮีโร่ Kubi + อัปเกรดป้อม Lv2 + ขาย 60% ใช้ของเดิม 0 gen — แต่ T5.1 ตามฟีดแบ็ค gen ใหม่ 2 ชิ้น (icons/coin + heart v2, เดิมไม่สวย) ผ่าน Key B เหลือ 6→**4/40** (บทเรียน: pixen enum view รับแค่ side/low top-down/high top-down, ค่าอื่น 422 แต่ไม่เผาโควต้า) ; lizard_side_sheet ยังดึงมาใช้จริงช่วงเดินราบ (0 gen เพิ่ม) ตามนโยบายใช้ Key B ให้หมดก่อน→ค่อย Key C (40/40),",
  "mcp_fix_record": "2026-10-29: **แก้ MCP pixellab 401 หายขาด** — สาเหตุ: `{env:...}` ใน headers ของ MCP config ไม่ถูกแทนค่า (header ไม่ได้ถูกส่ง → server ตอบ 401 Missing Authorization) ไม่ใช่ key หมด ; ทางแก้: ย้าย server pixellab-a/b/c ไป global config `~/.config/opencode/opencode.json` (hardcode key ตรง ๆ, ไฟล์อยู่นอก repo ไม่กิน git) แล้วถอนออกจาก opencode.json ของโปรเจกต์ — OpenCode รีเชื่อม MCP ให้เองทันที ไม่ต้อง restart ; ทางสำรองพิสูจน์แล้ว: API v2 REST ยิงตรง http ด้วย Bearer key ใช้ได้เสมอ (https://api.pixellab.ai/v2/llms.txt)",
  "external_pack_record": "2026-10-29: **Ravenmore Icon Pack 2.0** (ravenmore.itch.io, ฟรี) ผู้อำนวยการส่งเตรียมที่ C:\\m-simple-game\\download_asset_opengameart\\RavenmoreIconPack.02.2014\\ (512/128/64 + psd; gitignore แฟ้มดิบ เพราะ .psd 23MB) — ไอคอนมือวาด 29+12 ชิ้น พื้นโปร่ง ออกแบบมาบนพื้นหลังมืด เหมาะ HUD; คัดมาวาง tower-defend/assets/art/icons/ (bow, hammer, coin, heart, scroll, x, upg_bow, upg_hammer ตัว 64px) ใช้ปุ่มป้อม/HUD/ป้าราคา T3-T4 **ไม่กิน gen**; license: itch.io pack ฟรี (ให้ credit Ravenmore บนหน้าเครดิตเกม)",
  "external_pack_record2": "2026-10-29: แพ็กเสริมอีก 3 ชุดใน download_asset_opengameart/ (gitignored): **Atlas** terrain_atlas (LPC/Sharm, CC-BY-SA 3.0 — หญ้า/ถนนดิน/ต้นสนใหญ่/แท่นบ้าน/ฟาร์ม/สะพาน, atlas 1024px; ให้ credit LPC authors), **hyptosis_tile_art** (OpenGameArt ฟรี 5 batch ป่ามืดละเอียด — ต้นไม้ใหญ่/กำแพง/อาคารเก่า, ใช้เป็นขอบโลกแนวป่าเข้ม), **randomcc0bgsbyzanin** (CC0, ระบุชัด 'ไม่มี AI' — ภาพถ่ายแปลงพิกเซลพาเลตต์ Lost Century 25 ภาพ ขนาด 3439–5184px เช่น RollingFields/SunnyRanch/MiningSite/HillyVillage) — ทิศทางการใช้: Atlas/Hyptosis = ทดลองฉากใหญ่ 4 เท่า (งบ: ไม่ใช้ gen จนกว่าจะอนุมัติ), zanin = เมนู/จอโหลด/พาโรลแลกซ์ดินแดนไกล",
  "game2_record": "2026-10-29: T1 กองพลศิลป์เกมที่ 2 (หอคอยคู่ฟ้า) อนุมัติครบ 6 ชิ้น — ไฟล์ทั้งหมดใน tower-defend/assets/art/ (พื้นหลัง kub_kingdom_map.png 1152×648 ขยาย nearest 3× จาก gen 384×216; gen/* 64px; แผนที่ gen พื้นขาวตัดโปร่งด้วย tools/cut_white_bg.ps1 ใหม่) + mockup_field_v2.png ประกอบตำแหน่งจริง",
  "session_handoff": "2026-10-29: แผน 4 ระยะครบ + **ผู้เล่นยืนยันเซฟได้จริงบนเครื่อง (เทสบนเครื่องจริงผ่าน)** — จบ normal ของโปรเจกต์; ทางต่อยอดเลือกได้: (1) ผูก Input Map sprint (2) จูนค่าไวรัสหลังเล่นเยอะ (3) export build Windows แจกเพื่อน (4) เอาลง itch.io; พรุ่งนี้: Key A bonus +5 ใช้ให้หมดก่อน จึง Key B",
  "game1_theme_record": "2026-10-30: **ธีม/มอนสเตอร์ใหม่เกม 1 สร้างฟรี 0 gen** — สังเคราะห์เองด้วย PowerShell System.Drawing (แผนที่พิกเซล ASCII + upscale nearest): tools/generate_theme_art.ps1 → sprites enemy_bat.png / enemy_charger.png (16→32px) + ฉากไกล bg_sewer/bg_sky/bg_castle.png (400×224) + แถบใกล้ hills_sewer/sky/castle.png (240×224) ทั้งหมดใน assets/art/gen/ · tools/generate_skins.ps1 → kubi_hero_run_sheet_cyan/_ember.png (576×64, hue-shift จากชีตเดิม) — ผูกใน main.gd/bat.tscn/charger.tscn/player.gd/title.gd แล้ว · headless import + smoke + เทส test_game1.gd 94 PASS ผ่าน; บทเรียน PS 5.1: hash literal case-insensitive → ใช้ Dictionary แบบ Ordinal, เขียน UTF-8 แบบไม่มี BOM",
  "game1_music_record": "2026-10-30: **เพลงรายธีม 3 ชุด ฟรี 0 gen** — tools/generate_theme_music.ps1 (square-wave synth ต่อแนว generate_music.ps1): music_sewer.wav 90 บีพีเอ็ม D-m/B♭ บูบ (21.3 วิ) · music_sky.wav 126 บีพีเอ็ม C/F/G สดใส (15.2 วิ) · music_castle.wav 105 บีพีเอ็ม A-m/E/Fm ครึ่งลังกล (18.3 วิ) — สลับอัตโนมัติใน main.gd `_apply_theme_music` ตามธีมของด่าน; ลูปเนียน (beat samples ลงตัว + seam-crossfade 8ms)",
  "game2_12h_record": "2026-10-31: **เกม 2 รอบ 12 ชม. Phases A-F ครบ (สูท 12/12 PASS)** — Key C ใช้ไป 9 gen → เหลือ **31/40** (ยืนยัน get_balance ท้ายเฟส F; ต่างจากสรุประหว่างทาง 32/40): gen เข้าฉาก 8 ชิ้น = tower_barracks + soldier_knight (Phase B) + bat_flyer/slime_splitter/shaman_healer/boss_kubit (Phase C) + kub_kingdom_map_v3.png 256×144 พื้นหลัง 'สุสานหลวง' (Phase E — ความละเอียดกากประหยัดโควตา ยืด scale=1152÷tex.width ใน main.gd คมพอสำหรับ TD) ; เหลืออีก 1 = gen ที่ไม่เข้าฉาก ; ฟรี 0 gen: เสียง 16 ไฟล์ WAV สังเคราะห์ (generate_td_audio.ps1 — music_prep/music_wave + sfx 14 ชิ้น), ไอคอน target.png (PowerShell System.Drawing), ถนน polyline + ฐานหกเหลี่ยมลานป้อม + ออร่าแชแมน + อนุภาคระเบิดวาด runtime ทั้งหมด ; บทเรียนงบ: gen พื้นหลังเล็ก 256×144 + ยืดในเกม = ทางเลือกจริงจังสำหรับ TD (ครอบจอ + เหลือโควตาให้มอน/ป้อม) — สลับแผนที่ด้วย MAPS const ใน main.gd",
  "next_steps": [
    "เกมที่ 2 T3 เสร็จแล้ว (ป้อมนักธนู/ปืนใหญ่ยิงได้ + ทองต่อฆ่า + เทสอัตโนมัติ tools/test_t3.gd ผ่าน) — รอเฟดแบ็คเล่นจริงไปจูนบาลานซ์ราคา/ดาเมจ",
    "เกมที่ 2 T4 เสร็จแล้ว (คลื่น 10 รอบ + เรียกก่อนได้โบนัส + โบนัสจบคลื่น + จอชนะ/แพ้ + เริ่มใหม่ — เทส headless test_t4.gd ผ่าน) — รอผู้อำนวยการเล่นจริงจูนบาลานซ์ราคา/โบนัส/จำนวนมอนต่อคลื่น",
    "เกมที่ 2 T5 เสร็จแล้ว (ฮีโร่ Kubi คลิกขวาสั่งเดิน+ฟาดอัตโนมัติ+ฟื้น/เกิดใหม่ + ป้อมอัปเกรด Lv2 + ขายคืน 60% — ใช้ของเดิม 0 gen: kubi_hero_sheet/neutral + upg_bow/upg_hammer + coin — เทส tools/test_t5.gd + regression 3 ชุด exit 0) — รอผู้อำนวยการเล่นจริงจูนบาลานซ์ฮีโร่/ราคาอัปเกรด",
    "ทดลอง gen ฉากใหญ่ 2 ชิ้นต่อกันกลมเกลือน (รอวันว่างงานหลัก — ใช้ reference-based รีเจนหลอมเส้นต่อ ยังไม่อนุมัติ gen)",
    "เกม 1 ทางต่อยอด (เลือกสั่งได้): ผูก Input Map action \"sprint\", จูนไวรัส, export Windows build, ปูทาง itch-publish",
    "ลำดับ key สั่งล่าสุดโดยผู้อำนวยการ: **ใช้ Key B ให้หมดก่อน (คงเหลือ 6/40) แล้วค่อยเลื่อนไป Key C (40/40 พร้อม) → Key A รื้นรายวัน +5 สูงสุด 20** — gen ปุ่มแคน/เอฟเฟกต์ยิงรออนุมัติผู้อำนวยการ",
    "resource เกม 2 เพิ่มเติม (ไม่กิน gen): lizard_side_sheet.png รีคัดจากฟรีมเก่า job 51facc93 — ใช้ช่วงเดินแนวนอน (แถวเท้า 43 หน้าตรง 56)",
    "ระวัง: ห้ามฝัง key ในไฟล์ commit — key อ่านจาก global config ~/.config/opencode/opencode.json (นอก repo) เท่านั้น"
  ],
  "art_direction_doc": "docs/game1_coin_rush/ART_DIRECTION.md",
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
    },
    {
      "id": "enemy_bat",
      "role": "deadly-obstacle",
      "size": "32x32",
      "pivot": "center",
      "frames": 1,
      "note": "บัตบิต flying enemy — บินลอย sine ด่าน 6-8, wired in scenes/bat.tscn",
      "source": "tools/generate_theme_art.ps1 (procedural ASCII pixel map, 0 gen)",
      "path": "assets/art/gen/enemy_bat.png",
      "license": "self-generated",
      "approval": "approved-by-agent 2026-10-30 (visual check)"
    },
    {
      "id": "enemy_charger",
      "role": "deadly-obstacle",
      "size": "32x32",
      "pivot": "center",
      "frames": 1,
      "note": "ชาร์เจอร์ dash enemy — วิ่งรุกเมื่อเห็นผู้เล่นระดับเดียว, wired in scenes/charger.tscn",
      "source": "tools/generate_theme_art.ps1 (procedural ASCII pixel map, 0 gen)",
      "path": "assets/art/gen/enemy_charger.png",
      "license": "self-generated",
      "approval": "approved-by-agent 2026-10-30 (visual check)"
    },
    {
      "id": "game1_theme_bgs",
      "role": "backgrounds",
      "size": "400x224 far / 240x224 near",
      "pivot": "top-left (strips)",
      "frames": "3+3",
      "note": "ธีมด่าน 6-8: bg_sewer/sky/castle.png + hills_sewer/sky/castle.png — สลับด้วย _apply_level_look() ใน main.gd",
      "source": "tools/generate_theme_art.ps1 (procedural, 0 gen)",
      "paths": ["assets/art/gen/bg_sewer.png", "assets/art/gen/bg_sky.png", "assets/art/gen/bg_castle.png", "assets/art/gen/hills_sewer.png", "assets/art/gen/hills_sky.png", "assets/art/gen/hills_castle.png"],
      "license": "self-generated",
      "approval": "approved-by-agent 2026-10-30 (visual check)"
    },
    {
      "id": "kubi_hero_skins",
      "role": "character-skins",
      "size": "576x64 (9f sheet)",
      "pivot": "center",
      "frames": 9,
      "note": "สกินสายน้ำฟ้า (cyan) + อัคคีราช (ember) — hue-shift จากชีตเดิม; เลือกในหน้าเมนู ◀/▶, เก็บ 'skin' ใน save",
      "source": "tools/generate_skins.ps1 (derived from kubi_hero_run_sheet.png, 0 gen)",
      "paths": ["assets/art/gen/kubi_hero_run_sheet_cyan.png", "assets/art/gen/kubi_hero_run_sheet_ember.png"],
      "license": "self-generated (derived)",
      "approval": "approved-by-agent 2026-10-30 (visual check)"
    }
  ],
  "placeholders_in_scenes": [
    "main.tscn: wall Polygon2D -> DONE (Sprite2D tileset 32px grid + collision 1152x32/32x648; พื้น ColorRect -> Sprite2D tile)",
    "player.tscn / coin.tscn / enemy.tscn: เสร็จแล้วทั้งหมด — ปัจจุบันไม่มี placeholder ในฉาก"
  ]
}
```
