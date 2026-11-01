# COMMANDS — ชุดคำสั่งใช้งานจริง (reusable ทุกเกม)

> อัปเดต 2026-11-01 · ทั้งหมดรันจาก root repo (PowerShell)
> แทน `<gameX>` ด้วยโฟลเดอร์เกมจริง เช่น `game2_tower_defense`, `game3_...`

## 1. ตั้งค่าเครื่อง (ทำครั้งเดียวต่อเครื่องใหม่)

```powershell
powershell -ExecutionPolicy Bypass -File shared\setup_machine.ps1
```

## 2. หา / ใช้ Godot

ผลลัพธ์คือ path ของ `godot.exe` (console) — แนะนำห่อเป็นตัวแปร:

```powershell
$godot = (& shared\find_godot.ps1).Trim()   # ลำดับ: env GODOT_PATH → winget → PATH
& $godot --version
```

- เครื่องปัจจุบัน (winget): `C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`
- ยืนยันทุก path: `& shared\find_godot.ps1 -All`

## 3. Import โปรเจกต์ (รันครั้งแรกหลังแก้ asset/โครงสร้าง)

```powershell
& $godot --headless --path games\<gameX> --import
```

## 4. รันชุดเทส (SceneTree headless — ต้อง exit-code check)

สคริปต์เทสอยู่ที่ `games\<gameX>\tools\test_*.gd` (รูปแบบ SceneTree + `_process` frame แรก):

```powershell
$proj = (Get-Location).Path + "\games\<gameX>"
$fail = 0
foreach ($t in @("test_1_save", "test_2_waves", "test_3_towers", "test_4_hero")) {
  & $godot --headless --path $proj --script (Join-Path $proj "tools\$t.gd")
  if ($LASTEXITCODE -ne 0) { Write-Output "FAIL: $t"; $fail++ }
}
if ($fail -gt 0) { Write-Output "== $fail test(s) failed ==" } else { Write-Output "== ALL PASS ==" }
```

- ต้อง `--script` ชี้ path ไฟล์จริง (ไม่ใช่ res://)
- เทสที่แตะ save ผู้เล่นจริง (`user://...json`) ต้อง backup/restore ไฟล์ก่อน-หลังในสคริปต์เอง

## 5. แคปหน้าจอเกมจริง (shot_debug — ไม่ headless)

```powershell
& $godot --path games\<gameX> --script (Join-Path (Resolve-Path "games\<gameX>\tools\shot_debug.gd"))
```

- จะเปิดหน้าต่างจริง แคปภาพถึงที่กำหนด แล้วปิดเอง (ผลรอจนไฟล์เด้ง)

## 6. สร้างภาพ pixel-art (PixelLab Key C — synchronous REST)

```powershell
powershell -File shared\gen_pixen_c.ps1 -OutFile games\<gameX>\assets\sprites\foo.png -Description "tiny red fox warrior, front view" -W 64 -H 64
# ตัวเลือก: -View "side" | "low top-down" | "high top-down"  ·  -DownscaleTo 32  ·  -HasBackground (ถ้าไม่ใส่ = โปร่ง)
```

- Key อ่านจาก env `PIXELLAB_API_KEY_C` ก่อน แล้ว fallback ไฟล์ `~/.config/opencode/opencode.json`
- ต้องตั้ง timeout ≥ 90 วิ (ยิง REST ตรง รอซิงค์)
- โปร่งพื้นหลัง (no_background) ขนาดรวม canvas ห้ามเกิน 65,536px²

### เช็คยอดเครดิต Key C

ผ่าน MCP `execute`:  `tools["pixellab-c"].get_balance()` — ล่าสุด 2026-11-01 (ผู้โดยสาร 2 สายพันธุ์) = **21/40 ใช้ 19**

### อนิเมชันตัวละคร (animate-pixminimax)

```powershell
powershell -File shared\pixellab_anim.ps1 ...
```

- ⚠ ก่อนใช้ให้ซ่อม hardcoded output path เก่าในไฟล์ (เดิม `C:\m-simple-game\...` → ต้องชี้ repo ปัจจุบัน) และเช็ค key/pa. ใน `.mcp.json`

## 7. เครื่องมือภาพ (ท้องถิ่น ครอบง่าย)

```powershell
powershell -File shared\upscale_nearest.ps1 -SrcPng a.png -DstPng b.png -Scale 4   # ขยาย nearest (คมพิกเซล)
powershell -File shared\make_transparent.ps1 ...                                    # ตัดพื้นหลังเป็นโปร่ง
```

## 8. Git rhythm (ใช้ทุก commit)

```powershell
git pull --rebase --autostash origin main
git add <ไฟล์>
git commit -m "..."
git push origin main
```

- ผ่านเกณฑ์ = ดูบรรทัด `main -> main` (PS NativeCommandError noise ไม่ใช่ error จริง)
- commit + push บ่อย ๆ กันไฟฟ้าดับ / token หมด

## 9. บทเรียนข้อห้าม (ต้องจำ)

1. **FileAccess ต้องเรียก `close()` ทุกครั้ง** — Windows ล็อกไฟล์เงียบ ๆ ทำให้เทสถัดไปพัง
2. **SceneTree สั่งเปลี่ยน/เรียกฉากใน `_initialize` ไม่ได้** — ต้องรอ `_process` เฟรมแรกแล้วค่อยทำ
3. **typed `Array[Vector2]` ไม่รับ PackedVector2Array ตรง ๆ** — ต้อง assign ทีละสมาชิกหรือ copy
4. **ข้อความไทยยาว** — เขียนผ่าน write/edit tool เสมอ (PS heredoc เสี่ยง BOM/มอจิบาเกะ)
5. **ตัวเลขในเอกสาร** — ต้องยืนยันจากโค้ด/get_balance จริงก่อนลงเอกสาร

## 10. โครงสร้างเกมใหม่ (template เกม 4)

```
games/<game4>/
  project.godot             # copy pattern จากเกม 2: window 1152×648, stretch canvas_items
  scripts/                  # main.gd (ใหญ่เป็นหลักตามสไตล์ repo), ระบบรองแยกไฟล์
  tools/                    # test_*.gd (SceneTree) + shot_debug.gd
  assets/sprites|audio/
docs/<game4>/
  GDD.md · ARCHITECTURE.md · PLAYER_GUIDE.md · ROADMAP_12H.md · ASSETS.md
```

- play.bat แนบ root ของเกม (กด F5 ใน editor ก็ได้)
- ฟอนต์ไทย / ภาษา: ใช้ pattern เดียวกับเกม 2 (ถ้ามี custom font ให้แนบใน assets/fonts)
