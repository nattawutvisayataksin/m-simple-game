# Asset & Art — หอคอยคู่ฟ้า (Kub Kingdom Rush) · เกม 2

บันทึกคอทับผลงานจริงทั้งหมดอยู่ที่ [`../ASSET_MANIFEST.md`](../ASSET_MANIFEST.md) (`game2_record`, `keyb_record`, `external_pack_record`) — เอกสารนี้แจกแจงไฟล์ที่ดึงใช้ในฉาก + สถานะ

## ตารางกองทรัพย์ใช้ในเกม (รากอ้างจาก `games/game2_tower_defense/`)

| ชิ้นงาน | ไฟล์ | ต้นทาง (job) | สถานะ |
|---|---|---|---|
| แผนที่หลัก 1152×648 | `assets/art/kub_kingdom_map.png` (v2 `kub_kingdom_map_v2.png` เข้าฉากจริง) | pixflux 384×216 job `ecb637c9`, bg ปราสาท v2 job `5d0fffcf` → upscale nearest 3× (`shared/upscale_nearest.ps1`) | ✅ ฉากเดียว (ตัดสินวัน T2.6 — ยกเลิก Big World 1152×1296 ผลพร้อมจุดบกพร่อง) |
| กบ → ชุดเดิน 8f 512×64 | `assets/art/gen/frog.png` + `frog_sheet.png` (แถวเท้า 59) | pixflux `ddf520f0` + animate `f476bf24`; ตัดพื้น `shared/cut_white_bg.ps1` | ✅ (sheet ประกอบด้วย `tools/build_frog_sheet.ps1`) |
| กิ้งก่าหน้าตรง 8f 512×64 | `assets/art/gen/lizard_front.png` + `lizard_sheet.png` (แถวเท้า 56) | ภาพนิ่ง `af1584b6` + animate `27961c75` (บันทึก: animate จากหันข้างไม่หมุนตัว — gen หน้าตรงแยกต้องทำ) | ✅ |
| กิ้งก่าหันข้าง 8f 512×64 | `assets/art/gen/lizard_side_sheet.png` (แถวเท้า 43, หัวซ้ายโดยกำเนิด) | animate `51facc93` | ✅ T5.2 ดึงกลับมาใช้จริงช่วงเดินแนวนอน (ตัดสิน T3.2 เก็บสต็อก แล้วคืนตามฟีดแบ็ก) |
| ฮีโร่ Kubi เดิน 8f + neutral | `assets/art/gen/kubi_hero_sheet.png` (512×64) + `kubi_hero_neutral.png` | animate `e285f2e8` + คัดเฟรมยืน | ✅ |
| ป้อมนักธนู / ปืนใหญ่ | `assets/art/gen/tower_archer.png` / `tower_cannon.png` | pixflux `5801ea35` / `faf8a0e4` | ✅ สร้าง+อัปเกรด+ขายใช้ริกนี้เดิม |
| ไอคอน tables มือวาด | `assets/art/icons/bow, hammer, scroll, x, upg_bow, upg_hammer.png` (64px) | **Ravenmore Icon Pack 2.0** (ฟรี itch.io ไม่กิน gen; ให้ credit Ravenmore) | ✅ T3-T4 |
| ไอคอนเหรียญ / หัวใจ (HUD) | `assets/art/icons/coin.png` / `heart.png` (ราว `assets/art/gen/raw/coin_v2.png` / `heart_v2.png` ไว้สต็อก) | pixen Key B (2 gen — เดิมไม่สวยตามฟีดแบ็ก T5.1) | ✅ v2 regenerated |
| Mockup ตำแหน่ง (อ้างงานออกแบบ) | `assets/art/mockup_field_v2.png` | ประกอบด้วย `tools/compose_mockup.ps1` | 📐 ใช้ตอนออกแบบ ไม่ได้รันในเกม |

## เครื่องมือเจ้าของเกมนี้ (`games/game2_tower_defense/tools/`)

- ประกอบ/ตรวจภาพ: `build_frog_sheet.ps1`, `build_lizard_front_sheet.ps1`, `build_lizard_sheet.ps1`, `build_lizard_side_sheet.ps1`, `check_bgs_size.ps1`, `check_lizard_front.ps1`, `check_props.ps1`, `compose_big_mock.ps1`, `compose_mockup.ps1`, `compose_mockup_world_v3.ps1`, `compose_world.ps1`, `crop_master_portal.ps1`, `cut_lizard_front.ps1`, `grid_master.ps1`, `sample_master_colors.ps1`, `sample_seam_colors.ps1`, `measure_feet.ps1` (วัดแถวเท้าเพื่อ offset ยุติธรรม)
- เทส OS-click / ภาพ: `frog_contact.ps1`, `frog_diff.ps1`, `lizard_contact.ps1`, `lizard_front_diff.ps1`, `lizard_pair.ps1`, `test_click_log.ps1`, `test_click_win.ps1`
- สูทเทส GDScript: `test_menu.gd`, `test_menu2.gd`, `test_keys.gd`, `test_t3.gd`, `test_t4.gd`, `test_t5.gd`, `shot_debug.gd`
- เศษสคริปต์ legacy: บาง script อ้างพาธเครื่องเดิม `C:\m-simple-game\...` — เครื่องมือ one-shot ต้องตรวจ/แก้พาธก่อนรัน; **ไม่จำเป็นต้อง migrate** (ไม่โดนเรียกในสูทเทสหลัก)

## แพ็กภายนอกที่เก็บไว้ (ไม่ใช้ — ผู้อำนวยการตัดสิน)

ที่ `download_asset_opengameart/` (gitignored นอกราว repo):
- **Atlas** terrain (LPC/Sharm CC-BY-SA 3.0) + **hyptosis_tile_art** + **randomcc0bgsbyzanin** (CC0) — ทดลอง Big World 4× แล้ว **ตัดสินล้ม** (ไม่มีเน้บระบบนิเวศ พร็อพสติกเกอร์ขัดงาน gen) — บันทึกบทเรียนที่ GDD เกม 2
- ทิศทางชนะที่พิสูจน์: **gen ย่อย + เย็บสีตรงพาเลต + วาดถนนเอง** ไม่ใช่ประกอบพร็อพภายนอก

## โควตา gen ที่เกี่ยวก่อนข้อนี้

- T1-T2: Key B gen 7 ชิ้น (bg/ฮีโร่/กบ/กิ้งก่า 2 มุม/ป้อม 2) → เว้นว่างเหลือ 28/40 · T4.1 เผาโควตา timeout 10 gen (จนเหลือ 6) · T5.1 ไอคอน coin/heart v2 → **Key B 4/40**
- นโยบายผู้อำนวยการต่อไป: ใช้ Key B หมดก่อน → Key C (40/40) → Key A รื้นรายวัน — รายละเอียด使用 [../MCP_SETUP.md](../MCP_SETUP.md)
