# Art Direction Brief — ชิงเหรียญทอง (Coin Rush)

> อัปเดต: 2026-10-29 · ผูกกับ skill discipline `create-game-assets` · ธีม: Kub Chain / Kub Coin / Bitkub

## 1. Technical frame (locked)

| รายการ | ค่า |
|---|---|
| เอนจิน | Godot 4.7 (GL Compatibility) |
| มุมมอง | 2D Top-down, scale 1:1 px (จอ 1152×648) |
| Sprite ขนาดจริง | Player 32×32, Coin 32×32, Enemy 32×32 |
| พื้นหลัง | โปร่งใส (alpha) ทุก sprite |
| Filtering | nearest (pixel art) — ตั้งใน import settings ตอนนำเข้าจริง |
| ขนาดชน (ยังใช้เดิม) | Player r=16, Coin r=12, Enemy r=14 |
| แพลตฟอร์ม | Windows ก่อน (หน้าจอเดียว) |

## 2. Visual system (ธีม KUB)

**Palette roles:**
- `primary` ส้ม Bitkub `#FF8A1E` — ตัวหลัก (เหรียญ, ตัวละคร)
- `gold` ทอง `#FFC93C` — ไฮไลต์/แสงสะท้อน
- `cream` ครีม `#FFF3D6` — จุดสว่างบนโลหะ
- `dark` น้ำตาลอมดำ `#2A1708` — เส้น outline / เงา
- `danger` แดงเข้ม `#E5484D` + `maroon #7A1F1F` — เฉพาะศัตรู (ตัดกับสีเก็บได้ทั้งหมด)
- `ink` นีอองน้ำเงินเข้มพื้นหลัง `#16161E` — ยังใช้สีพื้น ColorRect เดิมได้ ไม่ต้องแก้ฉาก

**Shape language:** ทุกตัวเป็น "วงกลม/เหรียญ" เพื่อคงเงาชนวงกลมเดิม — โค้งมน ไม่มีมุมแหลมยกเว้น
เข็ม/spark ของศัตรู (อ่านออกทันทีว่าอันตราย)

**Silhouette priorities:**
- Player: กลม+หนวดเท้าสั้น+เสาอากาศ K — มองแล้วรู้ "ตัวเรา"
- Coin: วงกลมทอง-ส้ม อักษร K กลางเหรียญ — "ของที่ต้องเก็บ"
- Enemy: ก้อนเข้มเหลี่ยมมนสีแดง-ม่วง — "ห้ามแตะ"

**Edge treatment:** outline สีเข้มทึบ 1px รอบทั้งตัว (อ่านชัดบนพื้นเข้ม)

**Motion character (ตอน animate):**
- Coin: หมุนรอบตัวเอง 4–6 เฟรม + แสงวาบ
- Player: idle ลอยเบา ๆ 4 เฟรม / เดิน 6 เฟรม
- Enemy: ลอยแบบหยดสั่น + ประกายไฟ 4 เฟรม

## 3. ข้อจำกัดการผลิต (Pixellab MCP / REST)

**มี Pixellab API key จำนวน 2 key** (ผู้ใช้เปิดให้ใช้ได้อิสระ "เมื่ออยากใช้ให้ใช้ได้เลย"):

| Key | ที่เก็บ | สถานะโควตา (trial) | วิธีใช้ |
|---|---|---|---|
| Key A | session MCP ของ OpenCode (ภายนอก repo) | หลักหมด (46/40) — **daily bonus ทดสอบแล้วใช้ได้จริง** (2026-10-29: แตก bonus gen tileset 1 ครั้ง, ยอด today 5→4) | ผ่าน `tools.pixellab.*` ตรง ๆ — เหตุการณ์: ถ้า remaining=0 จะกิน bonus อัตโนมัติ (+5/คืน สูงสุด 20) |
| Key B | `.mcp.json` (ถูก gitignore, Bearer header ของ pixellab) | **ใช้แล้ว 3/40 → เหลือ 37** | REST v2 ตรง ๆ (`https://api.pixellab.ai/v2`) — หรือผู้ใช้รีสตาร์ท OpenCode แล้ว MCP ของ pixellab จะผูก key B ให้ใช้ผ่าน `tools.pixellab.*` ได้ด้วย |

**กติกาใชญาโควตา:**
- ทำงานผ่าน REST ได้เสมอด้วย key B — กินการ gen ตัวเอง (แต่ละปลายทางจะให้สถานะ "background_job_id" ที่ poll ได้ที่ `GET /background-jobs/{job_id}`)
- การตรวจสภาพ cap: REST ฟรีแรงก์ 1 job พร้อมกัน — ยังพอรันงานขนานจาก 2 key ต่างบัญชีได้
- การ frame count อนิเมต์: จำนวนเฟรมต้องเป็น **multiples of 4** (REST จะแจ้งเองถ้าไม่)
- หลักการจันทน์โควไว: ตรวจภาพให้ผู้ใช้เห็นก่อน ผลิต asset ตัวจริง (concept → approve → produce)
- มี `pixelart_workbench` (ฟรี ไม่กิน gen) ไว้แก้รายละเอียด/แก้พิกเซลด้วยตัวเอง
- หากโควตาหมดทั้ง 2 key: หยุด gen รอ daily bonus (+5 ทุกคืน, สูงสุด 20) หรือสับไปงานเอกสาร/โค้ดที่ไม่ใช้ gen
- ⚠️ ห้ามฝัง key ในไฟล์ที่จะ commit — สคริปต์ต้องอ่านจาก `.mcp.json` เท่านั้น

**สถานะแอนิเมชันที่ผลิตผ่าน Key B (ใช้ทั้งหมด 3 gen — เหลือ 37/40):**
- coin 9 frames: ✅ เสร็จ — `assets/art/gen/coin_sheet.png` + ผูกในฉากแล้ว (`Sprite2D.hframes=9` + coin.gd)
- player 9 frames: ✅ เสร็จ — `assets/art/gen/player_sheet.png` (เฟรม 0 = ยืน, 1-8 = เดิน) + player.gd
- enemy 9 frames: ✅ เสร็จ — `assets/art/gen/enemy_sheet.png` (0 = ต้นฉบับ, 1-8 = เต้นหายใจ) + enemy.gd

**สถานะทดสอบบนเครื่องผู้ใช้ (2026-10-29):**
- Godot 4.7.2 ติดตั้งแล้วด้วย winget (exe อยู่ที่ `C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_...`)
- `GODOT_PATH` ใน `.mcp.json` แก้ให้ชี้ exe จริงแล้ว / รอบต่อไปต้องอัปเดตเอกสารตาม HOME_SETUP ข้อ 3-4 อีกครั้งหากไปเครื่องอื่น
- ทดสอบรันเกม headless + หน้าต่างจริง: **ผ่าน ไม่มี error**
- ต้อง commit+push ไฟล์ที่แก้ในรอบนี้: `scenes/player.tscn, enemy.tscn, coin.tscn`, `scripts/coin.gd`, `docs/*` (สถานะ doc)

## สถานะการเก็บภาพ (asset provenance)

| Asset | ไฟล์ | ที่มา | สถานะ |
|---|---|---|---|
| Coin K | `assets/art/sprites/coin_kub.png` | pixflux gen #1 (2026-10-29), gallery id `5d62a5a3-...-eba6f` | ✅ อนุมัติ + ใช้ในฉากแล้ว (Sprite2D) |
| Player | `assets/art/sprites/player_kubi.png` | pixflux gen #2 (2026-10-29), gallery id `46c1a8be-...-419f` | ✅ อนุมัติ + ใช้ในฉากแล้ว |
| Enemy | `assets/art/sprites/enemy_glitch.png` | pixflux gen #4 (2026-10-29), gallery id `e2302782-...-1c3d` | ✅ อนุมัติ + ใช้ในฉากแล้ว |
| Arena tileset | `assets/art/gen/kub_arena_sheet.png` (+`.json` metadata) | topdown tileset gen เดียว (2026-10-29, **daily bonus ของ Key A**) job `d54165fd-...`, 16 tiles 32×32, bbox: พื้น=(64,32) กำแพง=(0,96) | ✅ ผู้ใช้เห็นภาพอนุมัติ + ผูกใน main.tscn แล้ว (create_topdown_tileset standard) |
| HUD เหรียญ icon | `assets/art/sprites/coin_kub.png` (ใช้ซ้ำจากตัวเกม ไม่ gen เพิ่ม) | Sprite2D แดน HUD ข้าง ScoreLabel (2026-10-29) | ✅ ในฉากแล้ว |
| เพลง chiptune loop | `assets/audio/music.wav` | **สังเคราะห์ PowerShell เอง** `tools/generate_music.ps1` (ฟรี ไม่ใช้ gen; square-wave lead+bass, 8 บาร์ 140 BPM C-G-Am-F, 13.7s seamless, loop=forward ตั้งใน .import) | ✅ ผูกในฉากแล้ว bus Music autoplay |
| เหรียญทองของพิเศษ | `assets/art/sprites/coin_kub_gold.png` + `assets/art/gen/goldcoin_sheet.png` (9f) | recolor จาก coin_kub ผ่าน `edit_image_pixen` (1 gen) + animate `pixminimax` 8f (1 gen) ทั้งหมด = bonus Key A 2026-10-29, job `aba8727d-abb` / `9a1c3deb` | ✅ ใช้ในฉากแล้ว (coin_gold.tscn, value=3, วาบแสง) |
| เอฟเฟกต์เก็บเหรียญ | `assets/art/gen/burst_gold.png` | pixflux **Key B** (1 gen) + ตัดพื้นหลังมืดด้วย `tools/make_transparent.ps1` (ฟรี) | ✅ ในฉากแล้ว (coin.gd tween scale+fade) |
| ไวรัสสีต่าง (ระยะ B) | `assets/art/sprites/enemy_glitch_green.png` / `enemy_glitch_blue.png` | recolor จาก enemy_glitch ผ่าน `edit_image_pixen` ตัวละ 1 gen (2026-10-29), job `8f1a2e57` / `288e6dbe` — ✅ **ผูกฉากแล้ว 2026-10-29**: `enemy_green.tscn` (เด้งบ้าคลั่ง, 330px/s + jitter 1.2 วิ) โผล่ 10 วิ / `enemy_blue.tscn` (ไล่ตาม, 210px/s chase 1.6) โผล่ 20 วิ — ภาพนิ่ง 1 เฟรม เต้นหายใจด้วย scale ใน enemy.gd แทนเฟรมจริง | ✅ ใช้ในฉากแล้ว (enemy.tscn แดงคงเดิม) |
| ฟอนต์ HUD | — (ไม่ผลิต) | pixellab `create_font` รองรับเฉพาะ Latin 80 glyph ไม่มีไทย → เลือกใช้ LabelSettings (สีทอง KUB + outline เข้ม) กับ default font แทน | ✅ ตัดสินใจแล้ว สามารถเปลี่ยน font จริงภายหลังถ้าต้องจ่าย gen |
| Coin anim | `assets/art/gen/coin_frames_*.png` | animate-pixminimax (REST, 8 เฟรม) | 🔄 กำลัง gen |
| Player anim | `assets/art/gen/player_frames_*.png` | animate-pixminimax (REST, 6 เฟรม) | 🔄 กำลัง gen |
| Enemy anim | `assets/art/gen/enemy_frames_*.png` | animate-pixminimax (REST, 6 เฟรม) | 🔄 กำลัง gen |

--- 
