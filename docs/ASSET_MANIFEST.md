# Asset Manifest — สมุดบัญชี asset + โควตา key (รวมทุกเกม)

> ยุบ 2026-11-01: ตัดบันทึกต่อรอบ/ต่อ asset เก่าออกเพื่อประหยัด token (ประวัติย้อนหลังหาได้จาก git history ของไฟล์นี้)
> asset รายตัวของแต่ละเกมดู `docs/gameX/ASSETS.md` ของเกมนั้น

## สถานะ key PixelLab (ยืนยัน `get_balance` 2026-11-01)

| key | ใช้/ทั้งหมด | สถานะ |
|---|---|---|
| A | 50/40 | หมด — รอ bonus รื้นรายวัน |
| B | 42/40 | หมด |
| C | 19/40 · **เหลือ 21** | **กำลังใช้** (โบนัสรื้นรายวัน +5, สะสมสูงสุด 20 — และคือค่างวดเดียวกับ plan ไม่ใช่สองเท่า) |

- นโยบายผู้อำนวยการ: ใช้ Key C เฉพาะภาพสำคัญจริง — **เช็คยอดทุกครั้งก่อน gen** (`tools["pixellab-c"].get_balance()`)
- Key ฝังใน global config `~/.config/opencode/opencode.json` (นอก repo) — **ห้ามฝัง key ในไฟล์ที่ commit**
- รายละเอียดการเชื่อม MCP: [MCP_SETUP.md](MCP_SETUP.md)

## บทเรียน gen/MCP ที่พิสูจน์แล้ว (ห้ามลืม)

1. `create-image-pixen` แบบ REST เป็น synchronous ตอบกลับ inline base64 ใช้เวลา 30–40 วิ → timeout ต้อง ≥90 วิ ไม่งั้นโควต้าถูกเผาเปล่า — ใช้ `shared/gen_pixen.ps1` (timeout 110 วิ) แทน
2. `gen_pixen.ps1` อ่าน env `PIXELLAB_API_KEY_B` ก่อน → fallback global config; ไม่เขียน key ลงไฟล์ใด ๆ
3. pixen `view` enum รับแค่ side / low top-down / high top-down (ค่าอื่นตอบ 422 แต่ไม่เสียโควต้า)
4. pixflux `animate` ไม่พลิกตัว "หันข้าง→หน้าตรง" — ต้อง gen ภาพนิ่งหน้าตรงแยกเป็นงานให้เอง
5. **gen พื้นหลังเล็ก 256×144 + ยืด scale ในเกม** = ทางเลือกจริงจังประหยัดโควตา (ใช้จริงกับพื้นหลัง "สุสานหลวง" เกม 2 — คมพอสำหรับ TD)
6. `{env:...}` ใน headers ของ MCP config ไม่ถูกแทนค่า = 401 Missing Authorization ทั้งที่ key ไม่ได้หมด; ทางแก้ = hardcode key ใน global config นอก repo แล้วถอนออกจาก config โปรเจกต์
7. ทางสำรองเมื่อ MCP พัง: ยิง API v2 ตรง (https://api.pixellab.ai/v2/llms.txt) ด้วย Bearer key ใช้ได้เสมอ
8. **เสียงทุกเกม + ธีมภาพเกม 1 + ไอคอนภายใน = PowerShell สังเคราะห์/วาดเอง** (`tools/generate_*.ps1`) — 0 gen เสมอเมื่อทำได้

## แพ็กภายนอก (ดิบ gitignored)

| แพ็ก | license | สถานะการใช้ |
|---|---|---|
| Ravenmore Icon Pack 2.0 (itch.io) | ฟรี — ให้ credit Ravenmore | **ใช้ในเกม 2** (ปุ่มป้อม/HUD 64px) |
| Atlas terrain_atlas (LPC/Sharm) | CC-BY-SA 3.0 — credit LPC | เก็บ — ทดลองฉากใหญ่ 4 เท่าถูกตัดสินล้ม |
| hyptosis_tile_art | OpenGameArt ฟรี | เก็บ — ไม่ใช้ |
| zanin randomcc0bgsbyzanin | CC0 | เก็บ — ไม่ใช้ |

> บทเรียนศิลป์ที่พิสูจน์แล้ว: **ประกอบพร็อพแพ็กภายนอก + พื้นหญ้าแบนสีเดียว ผ่านอาการ "ไม่ผ่าน ทุเรศ"** — ทิศทางชนะคือ gen/วาดเอง + เย็บสีตรงพาเลต + วาดถนนเอง
