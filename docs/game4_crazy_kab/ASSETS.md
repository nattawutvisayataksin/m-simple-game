# ASSETS — เกม 4 แท็กซี่คู่ฟ้า (Kubi Crazy Cab)

> อัปเดต 2026-11-01 · สร้างด้วย PixelLab Key C (สคริปต์ `shared/gen_pixen_c.ps1`)

## สไปรต์ในเกม (res://assets/sprites/) — 9 ภาพ

| ไฟล์ | เนื้อหา | ขนาดในเกม | view |
|---|---|---|---|
| `car_kubi.png` | Kubi Cab แท็กซี่เหลือง | 52x52 | high top-down |
| `car_liz.png` | กิ้งก่าซิ่ง รถกรีน | 52x52 | high top-down |
| `car_golem.png` | โกเลมแท็กซี่ แวนเกราะดำ | 52x52 | low top-down |
| `car_traffic.png` | รถจราจรแฮตช์แบ็กเทา | 43x43 | low top-down |
| `hazard_slime.png` | สไลม์เขียวแปะถนน | 28x28 | high top-down |
| `hazard_golem.png` | โกเลมหินเดิน | 32x32 | side |
| `pass_frog.png` | กบผู้โดยสารรอรถ | 22x22 | side |
| `pass_liz.png` | กิ้งก่าลูกผู้โดยสาร | 24x24 | side |
| `pass_chick.png` | ไก่ลูกผู้โดยสาร | 26x26 | side |

- ภาพรถ 4 คันออกแบบหันหน้าลงซ้าย 135 องศา → โค้ดชดเชย `SPRITE_ANG = PI * 0.75` (car.gd, play.gd)
- ทุกภาพพื้นหลังโปร่ง ย่อ nearest-neighbor ให้พิกเซลคม

## วาดโค้ดแทน (ไม่ต้องมีภาพก็เล่นได้)

- หมุด POI / ตึกเมือง+ไฟหน้าต่าง / ฟุตบาท / ทางม้าลาย / แรมพ์ / ลูกศรชี้เป้า = `play.gd`
- เงารถ / ไฟเบรกแดง / ดาวหมุนตอนโดนโกเลม = `car.gd`

## เสียง (G8 + G16 + G18) — สังเคราะห์สัญญาณล้วน ฟรี ไม่กินโควตา PixelLab

- ตัวสร้าง: `games/game4_crazy_kab/tools/generate_audio.ps1` (pattern เดียวกับ `generate_td_audio.ps1` เกม 2) → `assets/audio/` **16 ไฟล์ WAV**
- เพลงกลางวัน: `music_day.wav` (124 BPM funky, C–Am–F–G ลูป 8 บาร์) ใช้ทุกจอปกติ
- **เพลงราตรี (G16)**: `music_night.wav` (88 BPM chill, Am–F–C–G 3 โน้ตสโลว์ + pad ค้างทั้งบาร์ ลูป 4 บาร์) — สลับอัตโนมัติเมื่อ `sfx.start_music(true)`
- **จิ้งหรีดยามดึก (G16)**: `sfx_cricket.wav` (4 ชิรป ~2 วิ × 3 พัลส์ ~4.2kHz) — player แยกวนตลอดเฉพาะกะกลางคืน (`set_ambience`), หยุดทันทีเมื่อกลับเมนู/จบกะ
- **ปิ๊งสอน (G18)**: `sfx_tut.wav` (2 โน้ตขึ้น 988→1319Hz 0.28 วิ) — เสียงผ่านขั้นของกะฝึกขับ (จบขั้น = "win" คงเดิม)
- SFX: pickup / drop / fail / squeal (ยางดริฟท์) / whoosh (เฉียด) / boing (แรมพ์) / thud (ชนโกเลม) / squish (สไลม์) / horn (เริ่มเกม) / click (เมนู)
- เดรัมเบล: `sfx.gd` พูล 10 ผู้เล่น + throttle ต่อชนิด (เช่น squeal 0.5 วิ) — จบเกมจิงเกิลตาม rides_ok ≥ 5 = "win"
- **เทสเสียงแยก**: `tools/test_4_audio.gd` (สลับเพลง/จิ้งหรีดตามกะ + จบกะตัดหมด) — exit 0 = ผ่าน

## ยอดบัญชี PixelLab Key C (ยืนยันจาก get_balance จริง)

- เริ่มงานเกม 4: ใช้ 9/40, เหลือ 31
- จบงานกราฟิกเกม 4: ใช้ 17/40, เหลือ 23
- เพิ่มผู้โดยสาร 2 สายพันธุ์ (กิ้งก่า+ไก่): ใช้ 19/40, **เหลือ 21**
- regen car_golem 1 ครั้ง เพราะเวอร์ชันแรกมีฐานหินฉากแนบมา

## เทคนิค gen ที่พิสูจน์แล้ว (เกม 4)

- รถ: `-View "high top-down"`, `-W 64 -H 64 -DownscaleTo 48`; ยูนิตเล็ก: `-View "side"`, `-W 32 -H 32`
- คำอธิบายห้ามมี "stone ground / terrain" — โปรเจกต์จะเอาพื้นหินมาเกาะรถ
- view จำกัด enum: side / low top-down / high top-down (ใส่ front แล้วพัง 422)
- **เสียงไม่ผ่าน PixelLab เลย** — PowerShell synth เอง: หลีเดื่อเอนจิน (`generate_audio.ps1`)
- **บทเรียนโบนัสรายวัน**: `generations_today` ของ key ที่ plan หมด (A/B) **ยิง REST จริงไม่ได้ — 402 Payment Required** ทั้งที่ตัวเลขโบนัสยังค้างโชว์; เหตุผลเดียวที่ชนได้คือ `generations_remaining > 0` หรือเครดิตเงินสด

## หลงเหลือ (ถ้าทำต่อ)

- ผู้โดยสารหลายชนิด (กิ้งก่าลูก/ไก่) สุ่มแต่ละทริป — เหลือเฉพาะสุ่มภาพ
