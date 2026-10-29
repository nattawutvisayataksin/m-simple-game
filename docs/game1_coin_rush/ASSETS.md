# Asset & Art — ชิงเหรียญทอง (Coin Rush) · เกม 1

ทิศทางศิลป์ฉบับเต็มอยู่ที่ [ART_DIRECTION.md](ART_DIRECTION.md) — เอกสารนี้ระบุ **รายไฟล์ผลงานแต่ละชิ้น: ต้นทาง / ไฟล์ / สถานะการใช้**

## ตารางกองทรัพย์จริงใช้ในฉาก (ทดสอบ headless ผ่าน)

| ชิ้นงาน | ไฟล์ (อ้างจากราก `games/game1_coin_rush/`) | ต้นทาง | สถานะ |
|---|---|---|---|
| พื้น/กำแพง tileset KUB 16 tiles | `assets/art/gen/kub_arena_sheet.png` | pixellab topdown tileset (Key A daily bonus · job `d54165fd`) 3×32 grid | ผูก main.tscn (พื้น Sprite2D tile + กำแพง 4 ด้าน) ✅ |
| Player "Kubi" หุ่นยนต์ส้ม | `assets/art/sprites/player_kubi.png` + sheet `assets/art/gen/player_sheet.png` (9f) | pixflux gen#2 + animate-pixminimax | ผูก player.tscn ✅ เดิน 8 เฟรม (เฟรม 0 ยืน) |
| เหรียญ K หมุน 9f | `assets/art/sprites/coin_kub.png` + sheet `assets/art/gen/coin_sheet.png` | pixflux gen#1 + animate | ผูก coin.gd ✅ |
| เหรียญทองพิเศษ (ค่า 1-10) | `assets/art/concept/coin_kub_gold.png` (edit, เฟรมทองทั้ง) + sheet 9f | **edit_image_pixen** (1 gen) + animate | ผูก `coin_gold.tscn` ✅ สุ่มมูลค่า |
| ไวรัสหนามแดง | `assets/art/sprites/enemy_glitch.png` + sheet `assets/art/gen/enemy_sheet.png` | pixflux gen#4 + animate pulse | ผูก enemy.tscn ✅ |
| ป้ายประกายทองเก็บเหรียญ | `assets/art/gen/burst_gold.png` | pixflux Key B (1 gen) + ตัดพื้นด้วย `shared/make_transparent.ps1` | tween เด้งหมุนตอนเก็บ ✅ |
| เพลง + SFX | `assets/audio/*.wav` | สังเคราะห์เองผ่าน `tools/generate_music.ps1` + `tools/generate_sfx.ps1` (ฟรี 0 gen) | bus Music/SFX ✅ |

## กติกาเรื่องไฟล์/เครื่องมือ

- เครื่องมือเกมนี้ (ที่เกี่ยว asset): `games/game1_coin_rush/tools/` — `generate_music.ps1` (สังเคราะห์เพลง) · `generate_sfx.ps1` (SFX sine) · `build_sprite_sheet.ps1` (ประกอบเฟรมเป็น sheet)
- เครื่องมือใช้ร่วมทุกเกม: `shared/` — gen_pixen / pixellab_anim / cut_white_bg / make_transparent / upscale_nearest / zoom_atlas / transparency_check — รายละเอียด + ข้อควรระวัง API ใน [`../MCP_SETUP.md`](../MCP_SETUP.md)
- ย้าย/แตะไฟล์ asset แล้วต้อง import ใหม่: `godot --headless --path games/game1_coin_rush --import`

## สร้างขึ้นด้วยโควตา gen ตอนไหน

- ช่วงสร้างเกม 1: ไล่ใช้ Key A จนหมด (0/50) แล้วต่อด้วย Key B — บันทึกความเสียหายละเอียดใน ASSET_MANIFEST
- นโยบายปัจจุบัน (ผู้อำนวยการสั่ง 2026-10-29): **ใช้ Key B ให้หมดก่อน (เหลือ 4/40) → Key C (40/40) → Key A รื้นรายวัน +5 สูงสุด 20**
- การใช้ปัจจุบันของเกม 2 ดูที่ ASSET_MANIFEST เช่นกัน — ยังไม่มี gen มาใหม่หลัง T5.1 แล้ว

## สิ่งที่ FAIL ถูกพิสูจน์แล้ว (ห้ามซ้ำ)

- ฟอนต์ดีล `create_font` (Latin-only) ไม่รองรับไทย — ยึด `LabelSettings` + ฟอนต์ fallback แทน (บันทึก ART_DIRECTION)
- ขยายเฟรม sheet ต้อง `shared/upscale_nearest.ps1` ก่อนใช้ — ห้ามขยายด้วยตัวกรอง linear (เบลอ)
- (`download_asset_opengameart/` เป็นแพ็กภายนอกที่ **ไม่ควร** เอามาประกอบกับเกม 1 — บทเรียนเต็มที่ GDD เกม 2 บรรทัด Big World)
