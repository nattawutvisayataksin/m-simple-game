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
| Key A | session MCP ของ OpenCode (ภายนอก repo) | ใช้แล้ว ~45/40 ต้องรอ daily bonus | ผ่าน `tools.pixellab.*` ตรง ๆ |
| Key B | `.mcp.json` (ถูก gitignore, Bearer header ของ pixellab) | **40/40 ว่าง** พร้อมใช้ทันที | REST v2 ตรง ๆ (`https://api.pixellab.ai/v2`) หรือกลายเป็น MCP ตอนรีสตาร์ทเซสชัน |

**กติกาใชญาโควตา:**
- ทำงานผ่าน REST ได้เสมอด้วย key B — กินการ gen ตัวเอง (แต่ละปลายทางจะให้สถานะ "background_job_id" ที่ poll ได้ที่ `GET /background-jobs/{job_id}`)
- การตรวจสภาพ cap: REST ฟรีแรงก์ 1 job พร้อมกัน — ยังพอรันงานขนานจาก 2 key ต่างบัญชีได้
- การ frame count อนิเมต์: จำนวนเฟรมต้องเป็น **multiples of 4** (REST จะแจ้งเองถ้าไม่)
- หลักการจันทน์โควไว: ตรวจภาพให้ผู้ใช้เห็นก่อน ผลิต asset ตัวจริง (concept → approve → produce)
- มี `pixelart_workbench` (ฟรี ไม่กิน gen) ไว้แก้รายละเอียด/แก้พิกเซลด้วยตัวเอง
- หากโควตาหมดทั้ง 2 key: หยุด gen รอ daily bonus (+5 ทุกคืน, สูงสุด 20) หรือสับไปงานเอกสาร/โค้ดที่ไม่ใช้ gen
- ⚠️ ห้ามฝัง key ในไฟล์ที่จะ commit — สคริปต์ต้องอ่านจาก `.mcp.json` เท่านั้น

**สถานะแอนิเมชันที่ผลิตผ่าน Key B (วันใช้ทั้ง 1/40, koszt 3 gen สำหรับชุดนี้):
- coin 8 frames: ✅ เสร็จ — `assets/art/gen/coin_sheet.png` + ผูกในฉากแล้ว
- player 8 frames / enemy 8 frames: 🔄 กำลังผลิต (background)

## สถานะการเก็บภาพ (asset provenance)

| Asset | ไฟล์ | ที่มา | สถานะ |
|---|---|---|---|
| Coin K | `assets/art/sprites/coin_kub.png` | pixflux gen #1 (2026-10-29), gallery id `5d62a5a3-...-eba6f` | ✅ อนุมัติ + ใช้ในฉากแล้ว (Sprite2D) |
| Player | `assets/art/sprites/player_kubi.png` | pixflux gen #2 (2026-10-29), gallery id `46c1a8be-...-419f` | ✅ อนุมัติ + ใช้ในฉากแล้ว |
| Enemy | `assets/art/sprites/enemy_glitch.png` | pixflux gen #4 (2026-10-29), gallery id `e2302782-...-1c3d` | ✅ อนุมัติ + ใช้ในฉากแล้ว |
| Coin anim | `assets/art/gen/coin_frames_*.png` | animate-pixminimax (REST, 8 เฟรม) | 🔄 กำลัง gen |
| Player anim | `assets/art/gen/player_frames_*.png` | animate-pixminimax (REST, 6 เฟรม) | 🔄 กำลัง gen |
| Enemy anim | `assets/art/gen/enemy_frames_*.png` | animate-pixminimax (REST, 6 เฟรม) | 🔄 กำลัง gen |

--- 
