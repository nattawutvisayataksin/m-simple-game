# ตั้งค่าเครื่องนี้ให้พร้อมทำงาน (รันครั้งเดียวต่อเครื่อง — ดู docs/MACHINE_PATHS.md)
#
#  powershell -ExecutionPolicy Bypass -File shared\setup_machine.ps1        (ตั้งค่าครบชุด)
#  ...File shared\setup_machine.ps1 -NoImport                               (ไม่ build แคช import)
#
# ทำ 5 อย่าง: (1) หา Godot อัตโนมัติ (2) ตั้ง env GODOT_PATH ระดับ User
# (3) ใส่ godot-mcp ลง global config นอก repo พร้อม GODOT_PATH ของเครื่องนี้ (แนวเดียวกับ pixellab)
# (4) รัน --import ทุกเกมเพื่อสร้างแคช .godot  (5) เติมแถวเครื่องนี้ลง docs/MACHINE_PATHS.md
#
# ระเบียบ repo: ห้าม hardcode path ตามเครื่องลงไฟล์ที่ commit (ไฟล์เดียวที่อนุญาต = docs/MACHINE_PATHS.md)

param([switch]$NoImport)

# คอนโซลไทยบน cp874 อ่าน output ผัง — สลับเป็น UTF-8 ถ้าทำได้ (ต้องทำใน try เพราะผ่าน pipe ค่าบางครั้ง)
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

Write-Host "=== setup_machine.ps1 ==="
Write-Host ("เครื่อง: {0} / ผู้ใช้: {1}" -f $env:COMPUTERNAME, $env:USERNAME)

# --- (1) หา Godot ---
$godotPath = $(& (Join-Path $PSScriptRoot 'find_godot.ps1'))
if (-not $godotPath) {
  Write-Host "ติดตั้ง Godot ก่อน: winget install GodotEngine.GodotEngine แล้วรันสคริปต์นี้ใหม่"
  exit 1
}
Write-Host "(1) พบ Godot: $godotPath"

# --- (2) env GODOT_PATH ระดับ User (VS Code อ่านค่านี้ตอนเปิดครั้งถัดไป + สคริปต์อื่นใช้ต่อ) ---
[Environment]::SetEnvironmentVariable('GODOT_PATH', $godotPath, 'User')
$env:GODOT_PATH = $godotPath
Write-Host "(2) ตั้ง env GODOT_PATH ระดับ User แล้ว"

# --- (3) godot-mcp ลง global config นอก repo (~/.config/opencode/opencode.json) ---
$globalDir = Join-Path $HOME '.config\opencode'
$globalCfg = Join-Path $globalDir 'opencode.json'
New-Item -ItemType Directory -Force -Path $globalDir | Out-Null

if (Test-Path $globalCfg) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  Copy-Item $globalCfg (Join-Path $globalDir ("opencode.json.bak-$stamp"))
  $cfg = Get-Content -Raw -Encoding UTF8 $globalCfg | ConvertFrom-Json
}
else {
  $cfg = New-Object PSObject
}

if (-not $cfg.PSObject.Properties['mcp']) {
  $cfg | Add-Member 'mcp' (New-Object PSObject) -Force
}
if (-not $cfg.mcp.PSObject.Properties['servers']) {
  $cfg.mcp | Add-Member 'servers' (New-Object PSObject) -Force
}
$node = New-Object PSObject
$node | Add-Member 'type' 'local'
$node | Add-Member 'command' @('npx', '-y', '@coding-solo/godot-mcp')
$node | Add-Member 'environment' ((New-Object PSObject) | %{ $_ | Add-Member 'GODOT_PATH' $godotPath -PassThru })
$cfg.mcp.servers | Add-Member 'godot-mcp' $node -Force

$json = $cfg | ConvertTo-Json -Depth 32
[System.IO.File]::WriteAllText($globalCfg, ($json + "`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "(3) global config วาง godot-mcp แล้ว: $globalCfg (สำรองไว้ .bak ในโฟลเดอร์เดียวกัน)"

# --- (4) build แคช import --- 
if ($NoImport) {
  Write-Host "(4) ข้าม import ตามสวิตช์ -NoImport"
}
elseif (@(Get-Process Godot* -ErrorAction SilentlyContinue).Count -gt 0) {
  Write-Host "(4) ข้าม import: Godot กำลังเปิดอยู่ (เกม/เอดิเตอร์) — ปิดแล้วรัน setup_machine.ps1 ใหม่อีกครั้งเพื่อสร้างแคช"
}
else {
  foreach ($g in @('game1_coin_rush', 'game2_tower_defense', 'game3_car')) {
    $dir = Join-Path $repoRoot ("games\" + $g)
    Write-Host "(4) import: $g ..."
    & $godotPath --headless --path $dir --import | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "    เตือน: import $g exit=$LASTEXITCODE — ดูรายละเอียดด้วยรันตรง ๆ ที่ HOME_SETUP.md" }
  }
  Write-Host "(4) แคช import ทุกเกมสร้างแล้ว"
}

# --- (5) เติมแถวเครื่องนี้ลง docs/MACHINE_PATHS.md ถ้ายังไม่มีชื่อเครื่องนี้ ---
$doc = Join-Path $repoRoot 'docs\MACHINE_PATHS.md'
$lines = [System.IO.File]::ReadAllLines($doc)
$hasRow = @($lines | Where-Object { $_ -like "*$($env:COMPUTERNAME)*" }).Count -gt 0
if ($hasRow) {
  Write-Host "(5) ตาราง MACHINE_PATHS.md มีเครื่องนี้แล้ว — ข้ามการเติมแถว"
}
else {
  $secIdx = -1
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^## ตาราง path') { $secIdx = $i; break } }
  if ($secIdx -lt 0) {
    Write-Host "(5) เตือน: ไม่พบหัวตารางใน MACHINE_PATHS.md — กรอกแถวด้วยมือทีหลัง"
  }
  else {
    $lastRow = $secIdx
    for ($i = $secIdx; $i -lt $lines.Count; $i++) {
      if ($i -gt $secIdx -and $lines[$i] -match '^## ') { break }
      if ($lines[$i] -match '^\|') { $lastRow = $i }
    }
    $date = Get-Date -Format 'yyyy-MM-dd'
    $row = "| $env:COMPUTERNAME | ``$env:USERNAME`` | ``$godotPath`` | $date อัตโนมัติโดย setup_machine.ps1 |"
    $newLines = @($lines[0..$lastRow]) + @($row) + @($lines[($lastRow + 1)..($lines.Count - 1)])
    [System.IO.File]::WriteAllLines($doc, $newLines, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "(5) เติมแถวเครื่องนี้ลง docs/MACHINE_PATHS.md แล้ว — วางชื่อช่วงเรียกเป็น 'เครื่อง X' ได้ภายหลัง"
  }
}

Write-Host "=== เสร็จสิ้น ==="
Write-Host "จำเป็นต่อ: เปิด (restart) VS Code และ OpenCode ครั้งใหม่เพื่ออ่านค่า env ใหม่"
Write-Host "เช็ค: & .\shared\find_godot.ps1 → พิมพ์ path = ผ่าน"
