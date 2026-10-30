# Game Design Document — Kubi Coin Dash (Game 1 Redesign)

## 1. Overview
- **Name:** Kubi Coin Dash (Thai: คูบี้ กระโดดเก็บเหรียญ)
- **Genre:** 2D Side-scrolling Platformer (vertical slice)
- **Engine:** Godot 4.7 (GL Compatibility)
- **Goal/Story:** ฝูงไวรัส "Glitch Bugs" ขโมยเหรียญกองทุนเมือง KUB → Kubi ตามเก็บคืนทีละด่าน กองข่าสุดท้ายว่าจบที่ยอดเขาโรงหล่อเหรียญ — แตะธงบนยอด = คืนเหรียญครบ = ชนะ
- **Status:** Playable 5 levels (run/jump, coins, enemies + Hopper, hazards, ravine pits, moving platforms, title menu, level banners, save)

## 2. Core loop
Run → jump gaps → collect coins → avoid enemies/hazards → reach goal flag.
Tight controller first: coyote time, jump buffer, variable height, asymmetric gravity.

## 3. Controls
- A/D or arrows: move
- Space/W/Up: jump
- Shift: sprint
- R: restart · Esc: กลับเมนู

## 4. Levels (ครบ 5 ด่าน — มีชื่อ + คำใบ้เปิดด่าน)
- 1 **ถนนสายเอิ้น**: 2400×720, 120วิ, 9 coins, 4 walkers, 3 spikes — พื้นต่อเนื่อง
- 2 **ทุ่งเหรียญเขียว**: 3200×720, 120วิ, 12 coins, 5 walkers, 1 hopper, 5 spikes, 1 moving
- 3 **ป่าไวรัสหนา**: 4000×720, 150วิ, 17 coins, 6 walkers, 2 hoppers, 6 spikes, 2 moving
- 4 **หุบเหวแตกร้าว**: 3600×720, 140วิ, 13 coins, 3 walkers, 2 hoppers, ground แตก 3 ชิ้น + ตกหุบเหวแพ้, 2 moving (สูง-ลง + นอน)
- 5 **ยอดเขาโรงหล่อเหรียญ**: 4200×720, 160วิ, 17 coins, 5 walkers, 4 hoppers, ground แตก 3 ชิ้น, 3 moving (2 สูง-ลง + นอน) — ธงบนยอด (goal_y)
- Lose: enemy/hazard/time/ตกหุบเหว · Win: ธงด่าน 5

## 5. Systems
- CharacterBody2D platformer controller (coyote 0.12 / buffer 0.15 / cut 0.55 / fall 1.35)
- State ผูก level → `LEVELS` data table (width/time/name/sub/platforms/grounds/coins/enemies/hoppers/hazards/moving/goal_y)
- Coins (Area2D): เงิน 1 แต้ม · ทอง 3 แต้ม (เรืองแสงโค้ง)
- Glitch Walker (CharacterBody2D, เดินกลับถิ่นที่ขอบ, stomp kills)
- **Glitch Hopper** (CharacterBody2D, กระโดดเข้าหาผู้เล่นเป็นระยะ + edge-aware, stomp kills ด้วย)
- Hazards (Area2D spikes)
- Ravine: `_process` เช็ค y เกิน height+90 → lose "ตกหุบเหว"
- Level banner (HUD label + tween): แสดง "ด่าน N · ชื่อ · คำใบ้" fade in/out ต่อด่าน
- Dev shortcut: `godot ... res://scenes/main.tscn -- <level 1-based>`
- Title scene (main_scene): เมนู → Space/Enter/คลิก เข้าเกม; แสดงสถิติจาก save
- Save (user://, atomic + .bak): hi_score, best_win_time, wins, plays, level
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

## 7. Next steps
- Title screen + checkpoint
- ด่าน 4+ / procedural level
- Export build (Windows/itch)