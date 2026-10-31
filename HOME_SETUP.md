# คู่มือทำงานต่อบนคอมพิวเตอร์ที่บ้าน

เอกสารนี้ใช้สำหรับเตรียมเครื่องที่บ้านและนำโปรเจกต์ `m-sample-game` (2 เกม + เครื่องมือใช้ร่วม) ไปพัฒนาต่อ
รายละเอียด MCP ทั้งหมด (เซิร์ฟเวอร์ไหน ตั้งค่าอยู่ไหน บทเรียน 401/422) อยู่ที่ [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md) — เอกสารนี้สรุปขั้นที่ต้องติดตั้งตามลำดับ

## 1. โปรแกรมที่ต้องติดตั้ง

- Godot Engine 4.x (โปรเจกต์ทั้ง 2 เกมเทสกับ **4.7.2**)
- Git
- Visual Studio Code (ตัวเลือก — ใช้แก้โค้ด/รับ MCP จาก VS Code)
- Node.js 18 ขึ้นไป (ใช้ MCP `godot-mcp` ผ่าน `npx`)

ตรวจสอบการติดตั้งบน Windows ด้วย PowerShell:

```powershell
git --version
godot --version
node --version
npm --version
```

## 2. ดาวน์โหลดโปรเจกต์

```powershell
git clone https://github.com/nattawutvisayataksin/m-simple-game.git
Set-Location m-simple-game
```

จะได้โครงแบบนี้: `games/game1_coin_rush/` (ชิงเหรียญทอง) · `games/game2_tower_defense/` (หอคอยคู่ฟ้า) · `shared/` (เครื่องมือภาพ) · `docs/` (แยกต่อเกม)

## 3. เปิด/เล่นเกม (สำคัญ: เปิดที่ "โฟลเดอร์เกม" ไม่ใช่ราก repo)

```powershell
# เล่น
godot --path games/game1_coin_rush
godot --path games/game2_tower_defense

# เปิดตัวแก้ไข
godot --editor --path games/game1_coin_rush
godot --editor --path games/game2_tower_defense
```

หรือเปิดไฟล์ `games/game1_coin_rush/project.godot` ผ่าน Godot Project Manager — และเกมทั้งสองมี `play.bat` ดับเบิลคลิกได้
นี้คือจุดเตือน: **ราก repo ไม่มี `project.godot`** — เปิดผิดที่จะเจอข้อว่า "ไม่พบ project.godot"; ต้องเปิดที่โฟลเดอร์เกมแต่ละตัว)

**หลัง clone ครั้งแรก รัน import ให้ Godot สร้างแคช: **

```powershell
godot --headless --path games/game1_coin_rush --import
godot --headless --path games/game2_tower_defense --import
```

## 4. ตั้งค่า MCP ที่บ้าน (ถ้าต้องการใช้ AI ช่วยพัฒนา)

จุดตรวจหลัก **2 ไฟล์** (รายละเอียดครบที่ [`docs/MCP_SETUP.md`](docs/MCP_SETUP.md)):

### 4.1 godot-mcp — ตั้งด้วยสคริปต์ครั้งเดียว (ยกเลิกการแก้ path มือแล้ว)

```powershell
powershell -ExecutionPolicy Bypass -File shared\setup_machine.ps1
```

มันทำให้ครบ: หา Godot อัตโนมัติ → ตั้ง env `GODOT_PATH` (ระดับ User) → ใส่ godot-mcp ลง global config นอก repo →
build แคช import ทุกเกม → เติมแถวเครื่องนี้ลง [`docs/MACHINE_PATHS.md`](docs/MACHINE_PATHS.md) จากนั้น **เปิด VS Code / OpenCode ใหม่อีกครั้ง** เพื่ออ่าน env

- ห้าม hardcode `C:\Users\<ชื่อ>\...` ในไฟล์ที่ commit อีก — path เครื่องจริงเก็บที่ `docs/MACHINE_PATHS.md` อย่างเดียว
- Path ตามเครื่องที่รู้จัก (เครื่องหลัก Administrator / เครื่องบ้าน admin) อยู่ในตาราง `docs/MACHINE_PATHS.md`
- เปลี่ยนเวอร์ชัน Godot แล้ว รัน setup_machine.ps1 ใหม่ (มันเลือกเวอร์ชันสูงสุดเอง)

### 4.2 pixellab-a/b/c — อยู่ **global config นอก repo**: `~/.config/opencode/opencode.json`

- เครื่องตัวอย่างที่รันได้แล้ว: คัดลอกไฟล์ `C:\Users\Administrator\Desktop\opencode\opencode_global_for_other_pc.json` (สำเนาจากเครื่องหลัก) ไปเป็น `~/.config/opencode/opencode.json` แล้วแก้ path/ชื่อผู้ใช้ให้ตรงเครื่อง
- **ห้ามฝัง key ในไฟล์ที่ commit** — key ควรอยู่นอก repo เท่านั้น
- ข้อควรรู้: `{env:...}` ใน headers ของ config **ไม่ถูกแทนค่า** — สาเหตุ 401 ของ pixellab (อ่านพิสูจน์ที่ `docs/MCP_SETUP.md` §2)
- สถานะ key ล่าสุด/ลำดับการใช้: `docs/ASSET_MANIFEST.md`

## 5. โครงสร้างไฟล์หลัก

```text
m-simple-game/
├─ games/
│  ├─ game1_coin_rush/        # เกม 1: ชิงเหรียญทอง (scenes/scripts/assets/tools + play.bat)
│  └─ game2_tower_defense/    # เกม 2: หอคอยคู่ฟ้า (โครงเดียวกัน + สูทเทสใน tools/)
├─ shared/                    # เครื่องมือภาพใช้ร่วม (gen_pixen.ps1, pixellab_anim*.ps1, ... , LibreSprite)
├─ docs/
│  ├─ game1_coin_rush/        # GDD · ART_DIRECTION · ARCHITECTURE · ASSETS (เกม 1)
│  ├─ game2_tower_defense/    # GDD · ARCHITECTURE · ASSETS (เกม 2)
│  ├─ ASSET_MANIFEST.md       # สมุดบัญชี asset + โควตา key (รวมทุกเกม)
│  ├─ MACHINE_PATHS.md        # สมุด path รายเครื่อง + ระเบียบห้ามฝัง path ตามเครื่อง
│  └─ MCP_SETUP.md            # MCP: ใครอยู่ไหน + บทเรียน
├─ opencode.json              # MCP โครงโปรเจกต์ (godot-mcp อยู่ global config ต่อเครื่อง)
├─ shared/find_godot.ps1      # หา Godot บนเครื่องนี้อัตโนมัติ (ใช้แทนการพิมพ์ path)
├─ shared/setup_machine.ps1   # ตั้งค่าเครื่องครบชุดครั้งเดียว (สไตล์ 4.1 ข้างบน)
├─ HOME_SETUP.md              # ไฟล์นี้
└─ README.md                  # ภาพรวม + เรียงเอกสาร
```

## 6. เทสอัตโนมัติ (เกม 2) — รันหลังแก้โค้ดเกม 2

```powershell
$godot = (& .\shared\find_godot.ps1)   # หา Godot บนเครื่องนี้อัตโนมัติ — ไม่ hardcode path อีกแล้ว
foreach ($t in @('test_t3','test_t4','test_keys','test_t5')) {
  & $godot --headless --path games/game2_tower_defense --script (Join-Path (Resolve-Path .) "games\game2_tower_defense\tools\$t.gd")
}
```

ผ่าน = `ALL PASS` + exit 0 — ลดโอกาสแก้พังที่โหนดสายเกม

## 7. ขั้นตอนการทำงานประจำวัน

```powershell
git pull origin main
# แก้โค้ด + เทส
git add .
git commit -m "อธิบายสิ่งที่แก้ไข"
git push origin main

git status   # ก่อนปิดงาน — ต้องแสดง working tree clean
```

## 8. การแก้ปัญหาเบื้องต้น

- เปิดเกมไม่ได้: ตรวจว่ารันจาก **โฟลเดอร์ที่มี `project.godot`** (games/game1_coin_rush หรือ games/game2_tower_defense) ไม่ใช่ราก repo
- Godot MCP หา Godot ไม่พบ: รัน `shared\setup_machine.ps1` ใหม่ แล้วเปิด/รีสตาร์ต OpenCode + VS Code (ดู `docs/MACHINE_PATHS.md`)
- pixellab ตอบ 401: ไม่ใช่ key หมด — ปัญหา `{env:...}` ไม่เผยแร้งค่า; ใช้ global config + Bearer เต็ม ๆ (`docs/MCP_SETUP.md`)
- `git push` ขอรหัสผ่าน: ใช้ GitHub Personal Access Token (PAT) แทนรหัสผ่านบัญชี
- มี conflict หลัง `git pull`: หยุดแก้อย่างระมัดระวัง ตรวจไฟล์สีแดง/ús ที่ Git ตกลงแก้ไข

## 9. Repository

`https://github.com/nattawutvisayataksin/m-simple-game.git`
