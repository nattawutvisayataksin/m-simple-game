# Game Design Document — Kubi Coin Dash (Game 1 Redesign)

## 1. Overview
- **Name:** Kubi Coin Dash (Thai: คูบี้ กระโดดเก็บเหรียญ)
- **Genre:** 2D Side-scrolling Platformer (vertical slice)
- **Engine:** Godot 4.7 (GL Compatibility)
- **Status:** Vertical slice playable (run/jump, coins, enemies, hazards, goal, save)

## 2. Core loop
Run → jump gaps → collect coins → avoid enemies/hazards → reach goal flag.
Tight controller first: coyote time, jump buffer, variable height, asymmetric gravity.

## 3. Controls
- A/D or arrows: move
- Space/W/Up: jump
- Shift: sprint
- R: restart

## 4. Levels
- Level 1: 2400×720, 9 coins, 4 walkers, 3 spikes
- Level 2: 3200×720, 12 coins, 5 walkers, 5 spikes, 1 moving platform
- Level 3: 4000×720, 17 coins, 6 walkers, 6 spikes, 2 moving platforms
- Win: reach goal of level 3. Lose: hazard/enemy/time

## 5. Systems
- CharacterBody2D platformer controller (coyote/buffer/variable height)
- Coins (Area2D) with collected signal + pop juice
- Enemies (CharacterBody2D walkers, stomp from above kills)
- Hazards (Area2D spikes)
- Goal (Area2D)
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