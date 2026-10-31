# Asset & Art — หอคอยคู่ฟ้า (Kub Kingdom Rush) · เกม 2

บันทึกคอทับผลงานจริงทั้งหมดอยู่ที่ [`../ASSET_MANIFEST.md`](../ASSET_MANIFEST.md) (`game2_record`, `keyb_record`, `external_pack_record`) — เอกสารนี้แจกแจงไฟล์ที่ดึงใช้ในฉาก + สถานะ

## ตารางกองทรัพย์ใช้ในเกม (รากอ้างจาก `games/game2_tower_defense/`)

| ชิ้นงาน | ไฟล์ | ต้นทาง (job) | สถานะ |
|---|---|---|---|
| แผนที่หลัก 1152×648 | `assets/art/kub_kingdom_map.png` (v2 `kub_kingdom_map_v2.png` เข้าฉากจริง) | pixflux 384×216 job `ecb637c9`, bg ปราสาท v2 job `5d0fffcf` → upscale nearest 3× (`shared/upscale_nearest.ps1`) | ✅ ฉากเดียว (ตัดสินวัน T2.6 — ยกเลิก Big World 1152×1296 ผลพร้อมจุดบกพร่อง) |
| แผนที่ 2 "สุสานหลวง" 256×144 (gen) → ยืดครอบจอใน `main.gd` (scale = 1152÷tex.width) | `assets/art/kub_kingdom_map_v3.png` | Pixen Key C (Phase E, 1 gen — ความละเอียดต่ำประหยัดโควตา + glitch-pixel สุสาน/สระ/ปราสาทหลวง สเกลเนียนเพราะ near-integer 4.5×) | ✅ หน้าเลือกแผนที่/ตารางคลื่น B ใช้ตรรกะ `MAPS[1]` |
| กบ → ชุดเดิน 8f 512×64 | `assets/art/gen/frog.png` + `frog_sheet.png` (แถวเท้า 59) | pixflux `ddf520f0` + animate `f476bf24`; ตัดพื้น `shared/cut_white_bg.ps1` | ✅ (sheet ประกอบด้วย `tools/build_frog_sheet.ps1`) |
| กิ้งก่าหน้าตรง 8f 512×64 | `assets/art/gen/lizard_front.png` + `lizard_sheet.png` (แถวเท้า 56) | ภาพนิ่ง `af1584b6` + animate `27961c75` (บันทึก: animate จากหันข้างไม่หมุนตัว — gen หน้าตรงแยกต้องทำ) | ✅ |
| กิ้งก่าหันข้าง 8f 512×64 | `assets/art/gen/lizard_side_sheet.png` (แถวเท้า 43, หัวซ้ายโดยกำเนิด) | animate `51facc93` | ✅ T5.2 ดึงกลับมาใช้จริงช่วงเดินแนวนอน (ตัดสิน T3.2 เก็บสต็อก แล้วคืนตามฟีดแบ็ก) |
| โกเลมหินเกราะหนา 64×64 | `assets/art/gen/stone_golem.png` | PixelLab Pixen job `87313238-c119-471f-91c3-e18849ef177a` | ✅ ภาพนิ่ง + procedural bob |
| ค้างคาว (บิน) | `assets/art/gen/bat_flyer.png` | Pixen Key C (Phase C) | ✅ มอน `flying` — hover ลอยบนถนน |
| สไลม์ (แตกเป็นจิ๋ว) | `assets/art/gen/slime_splitter.png` | Pixen Key C (Phase C) | ✅ ตาย→split 2 จิ๋วต่อเส้นทาง (ตัวเดียวกัน วาดเล็กด้วย scale) |
| แชแมน (ฮีลออร่า) | `assets/art/gen/shaman_healer.png` | Pixen Key C (Phase C) | ✅ ฮีล 95px ทุก 2.2 วิ — ออร่าเขียว/วงพัลส์วาด runtime |
| บอส KUBIT | `assets/art/gen/boss_kubit.png` (64×64 + สเกล 2.1 ใน `enemy.gd`) | Pixen Key C (Phase C) | ✅ hp โป่ง + ทอง 250 + แถบเลือดแดงกว้าง + สังหรณ์ "☠ บอส KUBIT" |
| ค่ายทหาร (ป้อมสายที่ 4) | `assets/art/gen/tower_barracks.png` | Pixen Key C (Phase B) | ✅ ส่งทหาร 1-2 ตน + rally |
| ทหาร Kubi (บล็อกทาง) | `assets/art/gen/soldier_knight.png` | Pixen Key C (Phase B) | ✅ Lv1 1 ตน / Lv2 2 ตน, respawn 6 วิ |
| ฮีโร่ Kubi เดิน 8f + neutral | `assets/art/gen/kubi_hero_sheet.png` (512×64) + `kubi_hero_neutral.png` | animate `e285f2e8` + คัดเฟรมยืน | ✅ |
| ป้อมนักธนู / ปืนใหญ่ / เวท | `assets/art/gen/tower_archer.png` / `tower_cannon.png` / `tower_mage.png` | Pixen mage job `399468d4-435b-4ead-a115-2dbccfaa9670`; ของเดิม pixflux `5801ea35` / `faf8a0e4` | ✅ ฐานใช้ภาพเดิม; ลำกล้อง/อาวุธหมุนเล็งเป้าและแสดง flash ด้วยภาพวาด runtime |
| ไอคอน tables มือวาด | `assets/art/icons/bow, hammer, scroll, x, upg_bow, upg_hammer.png` (64px) | **Ravenmore Icon Pack 2.0** (ฟรี itch.io ไม่กิน gen; ให้ credit Ravenmore) | ✅ T3-T4 |
| ไอคอนเหรียญ / หัวใจ (HUD) | `assets/art/icons/coin.png` / `heart.png` (ราว `assets/art/gen/raw/coin_v2.png` / `heart_v2.png` ไว้สต็อก) | pixen Key B (2 gen — เดิมไม่สวยตามฟีดแบ็ก T5.1) | ✅ v2 regenerated |
| ไอคอนโหมดเล็ง (ปุ่ม "เล็ง") | `assets/art/icons/target.png` | วาดเองด้วย PowerShell System.Drawing (Phase D — one-shot, ไม่กิน gen) | ✅ ปุ่มสลับ First/Last/Strong/Weak |
| ลูกระเบิด/ธนู/ลูกเวท projectiles | `assets/art/gen/arrow.png` / `bomb.png` | pixflux เดิม | ✅ + อนุภาคปะทุวาด runtime (CPUParticles2D) |
| เพลง 2 อารมณ์ + SFX 14 ชิ้น | `assets/audio/music_prep.wav` / `music_wave.wav` + `sfx_arrow/build/cannon/click/coin/die/explosion/horn/leak/lose/mage/sell/slash/win.wav` | **สังเคราะห์เองงวด Phase A ฟรี 0 gen** — `tools/generate_td_audio.ps1` (square/triangle/noise, 44.1k 16-bit) | ✅ wired ใน `scripts/sfx.gd` (crossfade ตามสถานะ) |
| Mockup ตำแหน่ง (อ้างงานออกแบบ) | `assets/art/mockup_field_v2.png` | ประกอบด้วย `tools/compose_mockup.ps1` | 📐 ใช้ตอนออกแบบ ไม่ได้รันในเกม |

## เครื่องมือเจ้าของเกมนี้ (`games/game2_tower_defense/tools/`)

- ประกอบ/ตรวจภาพ: `build_frog_sheet.ps1`, `build_lizard_front_sheet.ps1`, `build_lizard_sheet.ps1`, `build_lizard_side_sheet.ps1`, `check_bgs_size.ps1`, `check_lizard_front.ps1`, `check_props.ps1`, `compose_big_mock.ps1`, `compose_mockup.ps1`, `compose_mockup_world_v3.ps1`, `compose_world.ps1`, `crop_master_portal.ps1`, `cut_lizard_front.ps1`, `grid_master.ps1`, `sample_master_colors.ps1`, `sample_seam_colors.ps1`, `measure_feet.ps1` (วัดแถวเท้าเพื่อ offset ยุติธรรม)
- เทส OS-click / ภาพ: `frog_contact.ps1`, `frog_diff.ps1`, `lizard_contact.ps1`, `lizard_front_diff.ps1`, `lizard_pair.ps1`, `test_click_log.ps1`, `test_click_win.ps1`
- สูทเทส GDScript 12 ชุด (ต้อง PASS ทั้งหมด, exit 0): `test_t3`, `test_t4`, `test_keys`, `test_t5`, `test_t6`, `test_t7`, `test_menu`, `test_menu2`, `test_t8` (ค่ายทหาร), `test_t9` (มอนใหม่+บอส), `test_t10` (โหมดเล็ง+พรีวิวคลื่น), `test_t11` (แผนที่ 2+title+save — คืนไฟล์เซฟผู้เล่นหลังจบ) + `shot_debug.gd` (แคปจอจริง 2 จอ: title + แผนที่ B)
- เสียง: `generate_td_audio.ps1` (สังเคราะห์ WAV ทั้ง 16 ไฟล์ — เขียน WAV header 16-bit หลัง block-align ให้ถูก)
- เศษสคริปต์ legacy: บาง script อ้างพาธเครื่องเดิม `C:\m-simple-game\...` — เครื่องมือ one-shot ต้องตรวจ/แก้พาธก่อนรัน; **ไม่จำเป็นต้อง migrate** (ไม่โดนเรียกในสูทเทสหลัก)

## แพ็กภายนอกที่เก็บไว้ (ไม่ใช้ — ผู้อำนวยการตัดสิน)

ที่ `download_asset_opengameart/` (gitignored นอกราว repo):
- **Atlas** terrain (LPC/Sharm CC-BY-SA 3.0) + **hyptosis_tile_art** + **randomcc0bgsbyzanin** (CC0) — ทดลอง Big World 4× แล้ว **ตัดสินล้ม** (ไม่มีเน้บระบบนิเวศ พร็อพสติกเกอร์ขัดงาน gen) — บันทึกบทเรียนที่ GDD เกม 2
- ทิศทางชนะที่พิสูจน์: **gen ย่อย + เย็บสีตรงพาเลต + วาดถนนเอง** ไม่ใช่ประกอบพร็อพภายนอก

## โควตา gen ที่เกี่ยวก่อนข้อนี้

- T1-T2: Key B gen 7 ชิ้น (bg/ฮีโร่/กบ/กิ้งก่า 2 มุม/ป้อม 2) → เว้นว่างเหลือ 28/40 · T4.1 เผาโควตา timeout 10 gen (จนเหลือ 6) · T5.1 ไอคอน coin/heart v2 → **Key B 4/40**
- **รอบ 12 ชม. (2026-10-31) ใช้ Key C 9 gen** — Phase B ค่ายทหาร+ทหาร (2) · Phase C ค้างคาว/สไลม์/แชแมน/บอส (4) · Phase E พื้นหลัง "สุสานหลวง" (1) → เข้าฉากจริง 8 ชิ้น + ส่วนต่าง 1 — **Key C 31/40 คงเหลือ** (ยืนยัน `get_balance` ท้าย Stage F) ; เสียงทั้งหมด + ไอคอน target + โครงถนน/ฐานหกเหลี่ยม = วาดโค้ดฟรี 0 gen
- นโยบายผู้อำนวยการต่อไป: ใช้ Key B ที่เหลือ 4 ให้หมดก่อน → Key C (31/40) → Key A รื้นรายวัน — รายละเอียด [../MCP_SETUP.md](../MCP_SETUP.md)
