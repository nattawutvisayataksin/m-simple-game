# m-sample-game — คลังฝึกทำเกม (Godot 4.7)

Repo นี้เก็บ **เกมฝึกพัฒนา 4 เกม (แยกโฟลเดอร์เกมของตัวเอง มี `project.godot` อิสระแต่ละเกม)** + เครื่องมือทั่วไป + เอกสารแยกต่อเกม

## เกมที่มีและเล่นได้

| # | เกม | ไฟล์โปรเจกต์ | สรุปสั้นโครงเกม | วิธีเล่น |
|---|---|---|---|---|
| 1 | **Kubi Coin Dash** 🪙 | `games/game1_coin_rush/` | Platformer 8 ด่าน: วิ่ง/กระโดด, เก็บเหรียญ, ศัตรู 4 ชนิด + มินิบอส (ด่าน 8), ธีมฉาก 3 แบบใหม่ (ท่อระบาย/ท้องฟ้า/ปราสาท) + เพลงรายธีม, สกินฮีโร่ 5 สีเลือกในเมนู · คูบี้ กระโดดเก็บเหรียญ | ดับเบิลคลิก `play.bat` หรือ `godot --path games/game1_coin_rush` |
| 2 | **หอคอยคู่ฟ้า (Kub Kingdom Rush)** 🏰 | `games/game2_tower_defense/` | Tower defense: มอนเดินเส้นเดียว ซื้อ/อัปเกรด/ขายป้อม · กลิ้ง 10 คลื่น + ฮีโร่ Kubi · ปุ่ม 1-4 ลานป้อม | ดับเบิลคลิก `play.bat` หรือ `godot --path games/game2_tower_defense` |
| 3 | **Kubi Grand Prix ราชวงศ์ทอง** 🚗 | `games/game3_car/` | แข่งรถ 3D ในเมือง Kubi · WASD ขับ/เบรก/เลี้ยว · เก็บเหรียญและผ่านประตูให้ครบ 3 รอบ | ดับเบิลคลิก `games/game3_car/play.bat` หรือ `godot --path games/game3_car` |
| 4 | **แท็กซี่คู่ฟ้า (Kubi Crazy Cab)** 🚕 | `games/game4_crazy_kab/` | แท็กซี่อาร์เคด top-down แนว Crazy Taxi: นาฬิกาเกม 120 วิ รับ-ส่งลูกค้าตามหมุด · ทิปส่งเร็ว/ดริฟท์/เฉียด/แรมพ์ · ปลดล็อกรถ 3 คัน · คู่มือค่าเกมในเมนู | ดับเบิลคลิก `games/game4_crazy_kab/play.bat` หรือ `godot --path games/game4_crazy_kab` |

> สถานะเกม 2: **ปิดโปรเจกต์** ที่ T5.2 (คำวินิจฉัยผู้อำนวยการ + บทเรียนเก็บไว้เต็ม ๆ ใน GDD เกม 2)
> สถานะเกม 3: **T1.1 WIP** — เกมรถ 3D พร้อมระบบหลัก กำลังต่อยอดภาพเมือง Kubi (`docs/game3_car/GDD.md`)
> สถานะเกม 4: **เกมเล่นได้เต็ม (G18)** — เมนู 7 จอ (รวมอู่อัปเกรด + กะฝึกขับ 3 ขั้นมีจอสรุป) · อัปเกรดรถถาวร Lv0-3 + เลือกรถประจำกะ · ป้ายลูกค้า 3 วงเลือกรับได้ · กะกลางคืน (เงิน x1.5/โกเลม 2 เท่า) · ภารกิจต่อกะ 3 อย่าง + โบนัส · เพลงราตรี + จิ้งหรีด · สไปรต์ PixelLab 9 ภาพ + เมืองแต่ง · เสียงสังเคราะห์ 16 ไฟล์ + juice · เซฟ v2 · เทส 4 ชุด PASS (`docs/game4_crazy_kab/`)

## โครงสร้าง repo

```text
m-sample-game/
├─ games/
│  ├─ game1_coin_rush/      # เกม 1 (project.godot + scenes/scripts/assets/tools + play.bat)
│  ├─ game2_tower_defense/  # เกม 2 (โครงเดียวกัน, tools มีสูทเทสอัตโนมัติ)
│  ├─ game3_car/            # เกม 3 (Kubi Grand Prix; โปรเจกต์เล่นได้ใน ./)
│  └─ game4_crazy_kab/      # เกม 4 (แท็กซี่คู่ฟ้า; โครงเดียวกันกับเกม 2)
├─ shared/                  # เครื่องมือพิกเซล/ภาพใช้ร่วมทุกเกม (gen_pixen, pixellab_anim, upscale_nearest, ...)
├─ docs/
│  ├─ game1_coin_rush/      # GDD · ART_DIRECTION · ARCHITECTURE · ASSETS
│  ├─ game2_tower_defense/  # GDD · ARCHITECTURE · ASSETS
│  ├─ game3_car/            # GDD · ROADMAP · PLAYER_GUIDE · ASSETS
│  ├─ game4_crazy_kab/      # GDD · ARCHITECTURE · ART_DIRECTION · ROADMAP_12H · PLAYER_GUIDE · ASSETS (แท็กซี่)
│  ├─ ASSET_MANIFEST.md     # สมุดบัญชี asset+โควตา key (รัวมทั้ง 2 เกม, พยานบันทึกทั้งหมด)
│  ├─ MACHINE_PATHS.md      # สมุด path รายเครื่อง + ระเบียบ "ห้ามฝัง path ตามเครื่อง"
│  └─ MCP_SETUP.md          # MCP ทั้งหมด + ตำแหน่งตั้งค่า + บทเรียน 401/422/timeout
├─ HOME_SETUP.md            # คู่มือเตรียมเครื่องใหม่ (ติดตั้ง → clone → เปิดเกม → MCP)
├─ opencode.json            # MCP โปรเจกต์ (godot-mcp อยู่ global config ต่อเครื่อง — ไม่ฝัง path)
└─ .vscode/mcp.json         # MCP ตั้งค่าเดียวกันสำหรับ VS Code AI (อ่าน GODOT_PATH จาก env)
```

## สั่งรันเกม

```powershell
# เกม 1
godot --path games/game1_coin_rush
# เกม 2
godot --path games/game2_tower_defense

# เปิดด้วยตัวแก้ไข
godot --editor --path games/game1_coin_rush
godot --editor --path games/game2_tower_defense
```

ย้ายเครื่องใหม่ / เอนจินหรือ path ต่าง: อ่าน `HOME_SETUP.md` ตั้งค่า + MCP ใน `docs/MCP_SETUP.md`

## เทสอัตโนมัติ (เกม 2 — มาตรฐาน)

```powershell
$godot = (& .\shared\find_godot.ps1)   # หา Godot บนเครื่องนี้อัตโนมัติ (ห้าม hardcode path — docs/MACHINE_PATHS.md)
foreach ($t in @('test_t3','test_t4','test_keys','test_t5')) {
  & $godot --headless --path games/game2_tower_defense --script (Join-Path (Resolve-Path .) "games\game2_tower_defense\tools\$t.gd")
}
```

ผ่าน = `ALL PASS` + exit 0. (`shot_debug.gd` = เปิดเกมจริงแคปภาพจอหน้าเกม — ใช้ตรวจหน้าผู้เล่นเห็นจริง)

หลังย้ายไฟล์/asset ครั้งถัดไป รัน `godot --headless --path <โฟลเดอร์เกม> --import` — ถ้าโค้ด/ลิงก์ asset พังจะขึ้น `SCRIPT ERROR` ให้ตามจับ

## เอกสาร (ไฟล์เรียกชุดนี้ที่ไหน)

- เกม 1: [`docs/game1_coin_rush/GDD.md`](docs/game1_coin_rush/GDD.md) · [ARCHITECTURE.md](docs/game1_coin_rush/ARCHITECTURE.md) · [ASSETS.md](docs/game1_coin_rush/ASSETS.md) · [ART_DIRECTION.md](docs/game1_coin_rush/ART_DIRECTION.md)
- เกม 2: [`docs/game2_tower_defense/GDD.md`](docs/game2_tower_defense/GDD.md) · [ARCHITECTURE.md](docs/game2_tower_defense/ARCHITECTURE.md) · [ASSETS.md](docs/game2_tower_defense/ASSETS.md)
- รวมทั้งระเบียบ: [`docs/ASSET_MANIFEST.md`](docs/ASSET_MANIFEST.md) (โควตา key/การบัญชี asset/บทเรียน) · [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md) · `HOME_SETUP.md`

## ขั้นตอนการทำงานประจำวัน

```text
git pull origin main
# แก้โค้ด
git add .
git commit -m "อธิบายสิ่งที่แก้ไข"
git push origin main
```

Repository: `https://github.com/nattawutvisayataksin/m-simple-game.git`
> หาก push ขอรหัสผ่าน ให้ใช้ GitHub Personal Access Token (PAT) แทน
