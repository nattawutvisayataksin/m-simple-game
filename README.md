# m-sample-game — คลังฝึกทำเกม (Godot 4.7)

Repo นี้เก็บ **เกมฝึกพัฒนา 2 เกม (แยกโฟลเดอร์เกมของตัวเอง มี `project.godot` อิสระแต่ละเกม)** + เครื่องมือทั่วไป + เอกสารแยกต่อเกม ตั้งใจให้เกมที่ 3 เพิ่มตามมาได้ทันที

## เกมที่มีและเล่นได้

| # | เกม | ไฟล์โปรเจกต์ | สรุปสั้นโครงเกม | วิธีเล่น |
|---|---|---|---|---|
| 1 | **ชิงเหรียญทอง (Coin Rush)** 🪙 | `games/game1_coin_rush/` | เก็บเหรียญ 10 (ทองพิเศษ ค่า 1-10) ภายใน 30 วิ · ไวรัสไล่ · WASD/ลูกศร + Shift วิ่งเร็ว · R รีสตาร์ท | ดับเบิลคลิก `play.bat` หรือ `godot --path games/game1_coin_rush` |
| 2 | **หอคอยคู่ฟ้า (Kub Kingdom Rush)** 🏰 | `games/game2_tower_defense/` | Tower defense: มอนเดินเส้นเดียว ซื้อ/อัปเกรด/ขายป้อม · กลิ้ง 10 คลื่น + ฮีโร่ Kubi · ปุ่ม 1-4 ลานป้อม | ดับเบิลคลิก `play.bat` หรือ `godot --path games/game2_tower_defense` |
| 3 | **เกมรถ (Game 3 - Car)** 🚗 | `games/game3_car/` | โครงตั้งต้น — รอกำหนดแนวเกม (แข่งเร็ว / หลบรถ / เก็บของ เป็นต้น) | ดับเบิลคลิก `play.bat` หรือ `godot --path games/game3_car` |

> สถานะเกม 2: **ปิดโปรเจกต์** ที่ T5.2 (คำวินิจฉัยผู้อำนวยการ + บทเรียนเก็บไว้เต็ม ๆ ใน GDD เกม 2)
> สถานะเกม 3: **โครงตั้งต้น T0** — โฟลเดอร์ + ฉาก stub พร้อมรัน, รอผู้อำนวยการกำหนดแนวเกมรถ (`docs/game3_car/GDD.md`)

## โครงสร้าง repo

```text
m-sample-game/
├─ games/
│  ├─ game1_coin_rush/      # เกม 1 (project.godot + scenes/scripts/assets/tools + play.bat)
│  └─ game2_tower_defense/  # เกม 2 (โครงเดียวกัน, tools มีสูทเทสอัตโนมัติ)
├─ shared/                  # เครื่องมือพิกเซล/ภาพใช้ร่วมทุกเกม (gen_pixen, pixellab_anim, upscale_nearest, ...)
├─ docs/
│  ├─ game1_coin_rush/      # GDD · ART_DIRECTION · ARCHITECTURE · ASSETS
│  ├─ game2_tower_defense/  # GDD · ARCHITECTURE · ASSETS
│  ├─ ASSET_MANIFEST.md     # สมุดบัญชี asset+โควตา key (รัวมทั้ง 2 เกม, พยานบันทึกทั้งหมด)
│  └─ MCP_SETUP.md          # MCP ทั้งหมด + ตำแหน่งตั้งค่า + บทเรียน 401/422/timeout
├─ HOME_SETUP.md            # คู่มือเตรียมเครื่องใหม่ (ติดตั้ง → clone → เปิดเกม → MCP)
├─ opencode.json            # MCP: godot-mcp (GODOT_PATH ชี้ตามเครื่อง)
└─ .vscode/mcp.json         # MCP ตั้งค่าเดียวกันสำหรับ VS Code AI
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
$godot = "C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
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
