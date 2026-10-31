# MCP ทั้งหมดที่ใช้ใน repo นี้ (เชื่อมกับ HOME_SETUP.md)

ขั้นตอนติดตั้งเครื่องใหม่อยู่ที่ [`HOME_SETUP.md`](../HOME_SETUP.md) — เอกสารนี้อธิบาย **มีอะไรบ้าง ตั้งค่าอยู่ไหน จุดพังที่พิสูจน์แล้ว (401/422/timeout)** ให้ครบ

## 1. สรุป MCP ทั้งหมด (3 ตระกูล — ยืนยันด้วย list_mcp_resources)

| เซิร์ฟเวอร์ | ตั้งค่าอยู่ที่ | หน้าที่ | เครื่องมือเด่น |
|---|---|---|---|
| `godot-mcp` | **global config นอก repo** (ตั้งโดย `shared/setup_machine.ps1` — ไฟล์ `.vscode/mcp.json` อ่าน env สำหรับ VS Code) | สั่ง Godot: สร้างฉาก/เพิ่มโหนด/เซฟฉาก/รันเกม | `run_project`, `get_debug_output`, `create_scene`, `add_node`, `get_uid`, `update_project_uids` |
| `pixellab-a` | **global** นอก repo | gen ศิลป์ AI ชุดที่ 1 (คนละ Key กับ B/C — โควตาเดียวกันแต่แยกนับ) | `pixelart_workbench` (ฟรี วาดพิกเซลเอง), `get_balance`, `list_projects` (git clone/push เกมโปรเจกต์): 103 เครื่องมือ |
| `pixellab-b` | **global** เดียวกัน | gen ศิลป์ AI ชุดที่ 2 — **นโยบายใช้ B ให้หมดก่อน** | เดียวกัน |
| `pixellab-c` | **global** เดียวกัน | gen ศิลป์ AI ชุดที่ 3 | เดียวกัน |
| `blender` | **global** เดียวกัน (`mcp.servers.blender`) | สั่ง **Blender 5.2** (3D): จัดฉาก/วัตถุ/วัสดุ/ส่งออกโมเดล .glb — โมเดล 3D ให้เกม | `setup`, `execute_script`, `get_viewport_screenshot`, `polyhaven_*(asset/texture/hdr)`, `get_scene_info` |

> 3 เซิร์ฟเวอร์ pixellab คือ base เดียวกันต่างกันแค่ API key — แยกไว้เผื่อโควตายืดอุ่นรวม quota เกินให้งบต่อรอบ

### บันทึกติดตั้ง `blender` (mcp-for-blender, commit 2026-10-29)

- **ประกอบ 2 ชิ้น**: (1) **Blender addon** ติดตั้งอยู่ `%APPDATA%\Blender Foundation\Blender\5.2\scripts\addons\blender_mcp.py` (setup CLI เปิดใช้ให้อัตโนมัติ) — เวลาใช้ต้อง**เปิด Blender ก่อน** (tab "MCP for Blender" แถบริม N, กดปุ่มเริ่ม server) ถึงจะคุยได้ (2) **MCP server** ผ่าน `uvx mcp-for-blender`
- **ตุ้กที่พิสูจน์แล้วบนเครื่องนี้ 2 ช่อง**:
  - installer เขียน server ลงผิดชั้นเป็น `mcp.blender` — **ต้องย้ายไปใต้ `mcp.servers.blender`** ตาม schema OpenCode (และ `$schema` อยู่ระดับบนสุดเสมอ)
  - `uvx` เรียกตัว default แล้วชน Python 3.15 ที่ uv จัดไว้ใน `%APPDATA%\Roaming\uv\python` — **โดน Application Control policy ของเครื่องบล็อก DLL** (`select`/`asyncio`) — วิธีแกยืนยัน: ผูก `--python 3.12` ใน args เสมอ (cpython-3.12 ของ uv ผ่าน)
- **ตั้งค่าชุดสำเร็จ** (ใน global config): `command: [uvx.EXE, "--python", "3.12", "mcp-for-blender"]`, `enabled: true` — restart OpenCode ครั้งเดียวเพื่อโหลด server ใหม่
- บั๊กคอนโซลจิ๋ว (job ภายนอก): รัน `setup` บนคอนโซล cp874 จิ้ม crash พิมพ์เครื่องหมาย ✓ — แก้ด้วย `$env:PYTHONIOENCODING="utf-8"` (ไม่กระทบการตั้งค่า)
- โครง source ดาวน์โหลดไว้ (อ้างอิงสอบถามได้): `%TEMP%\opencode\mcp-for-blender` (clone ของ github.com/ahujasid/mcp-for-blender) — รุ่น pyproject `2.2.6`

## 2. ตำแหน่งไฟล์ตั้งค่า (ความเข้าใจให้ตรง)

```text
repo/opencode.json          ← โครง MCP โปรเจกต์เท่านั้น (ไม่ฝัง path — godot-mcp ย้ายออกแล้ว)
repo/.vscode/mcp.json       ← สำหรับใช้ MCP จาก AI ใน VS Code (อ่าน GODOT_PATH จาก env ระดับ User)
~/.config/opencode/opencode.json  ← pixellab-a/b/c (Bearer key ตรง ๆ ไม่มี {env:...}) + godot-mcp (ตั้งโดย shared/setup_machine.ps1 ต่อเครื่อง)
```

> **ทำไม pixellab ต้องอยู่ global config (นอก repo):** ถ้าคีย์ยังฝัง key ใน config ตัว MCP ตอนส่ง header `Authorization: Bearer {env:KEY}` จะ**ไม่ถูกแทนค่าอัตโนมัติ** ทำให้ header ว่าง → API ตอบ **401 Missing Authorization** (มันไม่ใช่ key หมด — โควตายังอยู่ครบแต่บัญชีไม่เห็นตัว key)
> แก้ตามเหตุจริง: ย้าย pixellab-a/b/c ไป global config + ใส่ Bearer key ตรง ๆ แล้ว ทำงานทันที ไม่ต้อง restart OpenCode (บันทึก 2026-10-29 ใน `docs/ASSET_MANIFEST.md` `mcp_fix_record`)
>
> **และตั้งแต่ 2026-10-31 godot-mcp ก็อยู่ global config ต่อเครื่องด้วย (เหตุผลคนละอัน):** เพราะ GODOT_PATH ต่างกันรายเครื่อง (`Administrator` vs `admin`) — hardcode ใน repo แล้วต้องแก้ไป-กลับทุกครั้งที่สลับเครื่อง ตอนนี้ตั้งโดย `shared/setup_machine.ps1` ครั้งเดียวต่อเครื่อง + สมุดรายเครื่องอยู่ที่ `docs/MACHINE_PATHS.md`

**สำเนื่องเครื่องอื่น:** คัดลอก pixellab config ที่พิสูจน์แล้วรันได้ชุดสำเนา: `C:\Users\Administrator\Desktop\opencode\opencode_global_for_other_pc.json` (มี 3 key พร้อมตั้งค่า PoC) นำไปวางแทน `~/.config/opencode/opencode.json` บนเครื่องใหม่

## 3. Godot MCP — ข้อต้องรู้

- `GODOT_PATH` (ตั้งโดย `shared/setup_machine.ps1` ใน global config ต่อเครื่อง) จะชี้ **เวอร์ชันคอนโซล** อัตโนมัติ (จับ stdout ได้):
  `Godot_v4.7.2-stable_win64_console.exe` (ติดตั้งผ่าน winget ชุด `GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe`)
- ใช้รันหน้าเกมจริงแล้วเห็น debug ผ่าน `run_project` → `get_debug_output()` — หยุดด้วย `stop_project()`
- เตือน: `stop_project()` มองไม่เห็นเกมที่เริ่มจากภายนอก (เช่นรันเองผ่าน shell) — ปิดเองด้วย `Stop-Process -Name "Godot*"`

## 4. Pixellab — การใช้โควตาได้ดี

### สถานะ 3 Key ล่าสุด (ตาม `docs/ASSET_MANIFEST.md` + นโยบายผู้อำนวยการ)

- Key A `pixl_44b0…`: **หมด** 0/50 (รอ bonus รื้นรายวัน +5, สูงสุดกองได้ 20)
- Key B `pixl_9ca…`: **0/40 plan (daily bonus ยังมี)** หลังรอบ Game 1 platformer — **นโยบายล่าสุด: ใช้ Key B (plan+bonus) ให้หมดก่อน → หมดแล้วใช้ Key A daily bonus → ค่อยใช้ Key C**
- Key C `pixl_0b5…`: **40/40 + โบนัสรายวัน 5** (รื้นรายวัน, รวมสูงสุดสะสม 20)

### บทเรียนที่พิสูจน์แล้ว (ห้ามทำซ้ำ)

| บทเรียน | รายละเอียด |
|---|---|
| **401 Missing Authorization** | ไม่ใช่ key หมด! `{env:...}` ใน headers จาก MCP config ไม่ถูกแทนค่า — ใส่ Bearer key ตรง ๆ ใน global config |
| **422 view enum** | `create-image-pixen` รับ view ได้แค่ `side` / `low top-down` / `high top-down` (ทดลอง "straight-on front view" → 422 — **ไม่เสียโควตา**) → ผ่านไปโดยไม่ส่ง view |
| **เผาโควตาเงียบจาก timeout** | `create-image-pixen` แบบ REST เป็น synchronous ลาก 30-40 วิ — ต้องตั้ง timeout ≥ 90s (ดูตัวอย่างใน `shared/gen_pixen.ps1`); ตั้ง timeout สั้นเกินไป: จาวาไม่คืนให้เรา แต่ job gen บนฝั่ง API ไปเรียบร้อยแล้ว = โควตาถูกหักเปล่า |
| **1 job/key/ช่วงเดียว** | cooldown ~45 วิ — อย่ายิงต่อเนื่องแทคเป็นแนว burn เครื่อง gen |
| **จุดต่ำ (view) ที่ยังไม่มีใน sheet** | จะได้มุมที่ต้องการต้อง gen ภาพจากมุมของตัวจริง ยิง animate หมุนตัวไปที่มุมที่ไม่มีในต้นฉบับไม่ได้ (บันทึก T2.7 ใน GDD เกม 2) |
| **animate-pixminimax ไม่หมุนตัว** | animate จากภาพหันข้างได้แค่ frame หันข้าง — ต้องการหน้าตรงต้อง gen ภาพนิ่งหน้าตรงแยกก่อน |

### เครื่องมือพิกเซล/ภาพ (ฟรี ไม่กิน gen) — ที่ `shared/`

| สคริปต์ | หน้าที่ |
|---|---|
| `shared/gen_pixen.ps1` | ยิง create-image-pixen ด้วย Key B: อ่านจาก env `PIXELLAB_API_KEY_B` ก่อน, fallback จาก global config; ไม่เขียน key ลงไฟล์ใด ๆ |
| `shared/pixellab_anim.ps1` / `_resume.ps1` | เฟรมแอนิเมชัน (animate REST + เฟรมจาก job เดิม) |
| `shared/upscale_nearest.ps1` | ขยายภาพพิกเซลแบบ nearest (ห้ามเบลอ) |
| `shared/cut_white_bg.ps1` / `make_transparent.ps1` | ตัดพื้นขาวให้โปร่ง |
| `shared/zoom_atlas.ps1` | ซูม atlas เพื่อตรวจเฟรม (ใช้ตรวจก่อนแก้โค้ด) |
| `shared/transparency_check.ps1` | วางสไปรต์บนพื้นสีเพื่อตรวจความโปร่ง |

**ทางสำรองพิสูจน์แล้ว:** ยิง REST ตรง `https://api.pixellab.ai/v2/` ด้วย Bearer key ใช้ได้เสมอ (spec ที่ `https://api.pixellab.ai/v2/llms.txt`) — ใช้เมื่อ MCP เองงง/กันพาธเยอะ

## 5. ตรวจใช้งานด่วน

```powershell
# godot-mcp: ทดสอบผ่าน opencode (เรียก get_godot_version) — ตอบเวอร์ชัน = MCP ต่อผ่าน
# pixellab: เช็คโควตาด้วย get_balance ผ่าน opencode หรือยิง REST v2/balance ตรงด้วย Bearer key
```
