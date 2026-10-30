# Game Design Document — Kubi Coin Dash (Game 1 Redesign)

## 1. Overview
- **Name:** Kubi Coin Dash (Thai: คูบี้ กระโดดเก็บเหรียญ)
- **Genre:** 2D Side-scrolling Platformer (vertical slice)
- **Engine:** Godot 4.7 (GL Compatibility)
- **Goal/Story:** ฝูงไวรัส "Glitch Bugs" ขโมยเหรียญกองทุนเมือง KUB แล้วกระจายหนีไป 3 ที่ลับ (ท่อระบาย / ท้องฟ้า / ปราสาทบิตคู) → Kubi ตามเก็บคืนทีละด่าน 8 ด่าน — แตะธงบนยอดปราสาทด่านสุดท้าย = คืนเหรียญครบ = ชนะ
- **Status:** Playable 8 levels (run/jump, coins, 4 ชนิดศัตรู, hazards, ravine pits, moving platforms, title menu + skin chooser, level banners, per-theme ambience, save)

## 2. Core loop
Run → jump gaps → collect coins → avoid enemies/hazards → reach goal flag.
Tight controller first: coyote time, jump buffer, variable height, asymmetric gravity.

## 3. Controls
- A/D or arrows: move
- Space/W/Up: jump
- Shift: sprint
- R: restart · Esc: กลับเมนู
- ←/→ หรือ A/D บนหน้าเมนู: เปลี่ยนสกิน Kubi (บันทึกลงเซฟทันที)

## 4. Levels (ครบ 8 ด่าน — มีชื่อ + คำใบ้เปิดด่าน)
- 1 **ถนนสายเอิ้น**: 2400×720, 120วิ, 9 coins, 4 walkers, 3 spikes — พื้นต่อเนื่อง
- 2 **ทุ่งเหรียญเขียว**: 3200×720, 120วิ, 12 coins, 5 walkers, 1 hopper, 5 spikes, 1 moving
- 3 **ป่าไวรัสหนา**: 4000×720, 150วิ, 17 coins, 6 walkers, 2 hoppers, 6 spikes, 2 moving
- 4 **หุบเหวแตกร้าว**: 3600×720, 140วิ, 13 coins, 3 walkers, 2 hoppers, ground แตก 3 ชิ้น + ตกหุบเหวแพ้, 2 moving (สูง-ลง + นอน)
- 5 **ยอดเขาโรงหล่อเหรียญ**: 4200×720, 160วิ, 17 coins, 5 walkers, 4 hoppers, ground แตก 3 ชิ้น, 3 moving (2 สูง-ลง + นอน) — ธงบนยอด (goal_y)
- 6 **ท่อระบายบิต**: 3200×720, 140วิ, 14 coins, walkers + บัตบิต 3 + ชาร์เจอร์ 2, ธีมท่อระบาย (bg_sewer) + ฝนหยดเขียว
- 7 **ท้องฟ้าเมฆเด้ง**: 3400×720, 150วิ, 14 coins, บัตบิต 4, hoppers 3, แพลตฟอร์มลอยเคลื่อนหนัก, ธีมฟ้า (bg_sky) + ประกายทอง
- 8 **ปราสาทบิตคู**: 3800×720, 160วิ, 15 coins, ground แตก + ศัตรูครบทุกชนิด, แพลตฟอร์มลอยแนวตั้งเร็ว, ธีมปราสาทกลางคืน (bg_castle) + ประกายไฟ — ธงจบเกม
- Lose: enemy/hazard/time/ตกหุบเหว (4, 5, 8) · Win: ธงด่าน 8

## 5. Systems
- CharacterBody2D platformer controller (coyote 0.12 / buffer 0.15 / cut 0.55 / fall 1.35)
- State ผูก level → `LEVELS` data table (width/time/name/sub/bg/near/platforms/grounds/coins/enemies/hoppers/chargers/bats/hazards/moving/goal_y)
- Coins (Area2D): เงิน 1 แต้ม · ทอง 3 แต้ม (เรืองแสงโค้ง)
- Glitch Walker (CharacterBody2D, เดินกลับถิ่นที่ขอบ, stomp kills)
- Glitch Hopper (CharacterBody2D, กระโดดเข้าหาผู้เล่นเป็นระยะ + edge-aware, stomp kills ด้วย)
- บัตบิต (scripts/bat.gd): บินลอย sine ไปมา, ไม่มีแรงโน้มถ่วง, stomp kills, กระพือปีกแบบทวีบีบตัว
- ชาร์เจอร์ (scripts/charger.gd): เดินปกติ แต่เห็นผู้เล่นระดับเดียว (420px, ±48px) → ดาช 330px/s; ชนกำแพงแล้วมึน 0.55 วิ (stomp target)
- ธีมฉากต่อด่าน: `_apply_level_look()` สลับภาพไกล/ใกล้ + ไล่สีฟ้า (SKY_SEWER/SKY_SKY/SKY_CASTLE) + CanvasModulate
- บรรยากาศ: `_setup_weather()`/`_apply_weather()` — CPUParticles2D ใต้กล้อง (หยดน้ำท่อระบาย / ประกายท้องฟ้า / ประกายไฟปราสาท)
- สกินฮีโร่ 3 ชุด: `player.gd set_skin()` + บันทึก `skin` ใน save; เลือกใน title (◀/▶)
- Hazards (Area2D spikes)
- Ravine: `_process` เช็ค y เกิน height+90 → lose "ตกหุบเหว"
- Level banner (HUD label + tween): แสดง "ด่าน N · ชื่อ · คำใบ้" fade in/out ต่อด่าน
- Dev shortcut: `godot ... res://scenes/main.tscn -- <level 1-based>`
- Title scene (main_scene): เมนู → Space/Enter/คลิก เข้าเกม; แสดงสถิติจาก save
- Save (user://, atomic + .bak): hi_score, best_win_time, wins, plays, level, skin
- Camera2D smooth follow + bounds
- HUD (coins, time, best stats)
- Save/load (user://, atomic, v1 schema)
- Screen shake + squash/stretch juice

## 6. Art (สร้าง 30 ต.ค. 2026 — ชุดแสงสว่าง platformer)
- **สีสันสว่างอ่านเห็นทันที**: ท้องฟ้าไล่เฉด cyan→cream + เนินหญ้าดอกไม้, พื้นหญ้า/ดิน, ไม้พลังงานสีเรือนขอบทอง
- **ทิศทาง**: far = `bg_sunny.png` เต็มจอ (ท้องฟ้า+เมฆ+ดวงอาทิตย์+เนินเขา) · near = `hills_low.png` แถบหญ้าพาขนาน 45% · ไทล์วาดเองด้วย pixel tools ฟรี (ground cap / dirt fill / plank / moving)
- **ตัวละคร**: `kubi_hero_run.png` 64px side-run ใหญ่ readable + run-bob/lean/skid-dust; ศัตรูไวรัสแดง scale 1.3
- **Juice**: hit-stop สือง stomp, squash/stretch ตาม rest-scale, screen shake, SFX jump/land/stomp/pickup
- **บล็อกที่ต้องเลิกใช้ (สอนค้างเก็บไว้)**: ColorRect แผงดำ "Background" ใน main.tscn โอบมองทับทั้ง canvas — ลบออก พาณิชย์ parallax จึงไม่มองเห็น

## 7. Dev log
- **2026-10-30 (รอบสร้างสรรค์ใหญ่):** เพิ่มมอนสเตอร์ 2 ชนิด (บัตบิต / ชาร์เจอร์) · ด่าน 6-8 ธีมใหม่ (ท่อระบาย / ท้องฟ้า / ปราสาท) พร้อมฉาก+สีฟ้า+บรรยากาศรายธีม · สกินฮีโร่ 3 ชุดเลือกในเมนู (บันทึกเซฟ) · ชุดเทสอัตโนมัติ `tools/test_game1.gd` 94 ข้อ (PASS) · รีไรต์ PLAY.md · อาร์ตสร้างด้วย `tools/generate_theme_art.ps1` + `tools/generate_skins.ps1` (ไม่กิน gen)
- **2026-10-30 (รอบ 2):** เพลงรายธีม 3 แนว สลับอัตโนมัติตามด่าน (`_apply_theme_music`) — ท่อระบาย 90 BPM บูบ / ท้องฟ้า 126 BPM สดใส / ปราสาท 105 BPM ครึ่งลังกล สร้างฟรีด้วย `tools/generate_theme_music.ps1` (0 gen, ลูปเนียน seam-crossfade)

## 8. Next steps
- รอ playtest มนุษย์ (ด่าน 6-8 เนื้อใหม่ยังไม่เคยเล่นจริง) — จูนความยากตามฟีดแบ็ค
- เพลงต่อธีม (ต่อยอด tools/generate_music.ps1) · สกินเพิ่ม · export build (Windows/itch)