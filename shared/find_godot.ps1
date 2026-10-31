# หา Godot exe บนเครื่องนี้ แล้วพิมพ์ absolute path ออกทาง stdout (ตัวเดียว)
# ใช้ต่อ:  $godot = (& (Join-Path $PSScriptRoot 'find_godot.ps1'))
# ดูทุกตัวที่พบ:  & .\shared\find_godot.ps1 -All
# ลำดับค้น: 1) env GODOT_PATH   2) winget package (เวอร์ชันล่าสุด, ตัวคอนโซลก่อน)   3) godot บน PATH
# ห้าม hardcode path ไหน ๆ ไว้ที่นี่ — สคริปต์ต้องหาเจอเอง (โครงห้ามฝัง path ตาม docs/MACHINE_PATHS.md)

param([switch]$All)

$candidates = New-Object System.Collections.Generic.List[string]

# 1) env GODOT_PATH ที่ setup_machine.ps1 ตั้งไว้ (ถ้าไฟล์จริงยังอยู่)
if ($env:GODOT_PATH -and (Test-Path $env:GODOT_PATH -PathType Leaf)) {
  $candidates.Add($env:GODOT_PATH)
}

# 2) Godot จาก winget — หาทุกเวอร์ชันในโฟลเดอร์ Packages ของผู้ใช้ปัจจุบัน
$wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
if (Test-Path $wingetRoot) {
  $exes = @(Get-ChildItem -Path $wingetRoot -Filter 'Godot_v*_win64*.exe' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^Godot_v(\d+(?:\.\d+)+)[^_]*_win64(_console)?\.exe$' })

  $ranked = @($exes | Sort-Object `
    @{ Expression = { [version]([regex]::Match($_.Name, 'v(\d+(?:\.\d+)+)').Groups[1].Value) }; Descending = $true }, `
    @{ Expression = { [int]$_.Name.EndsWith('_console.exe') }; Descending = $true })

  foreach ($e in $ranked) { $candidates.Add($e.FullName) }
}

# 3) ติดตั้งแบบอื่นที่พิมพ์ godot บน PATH ได้ (ตัวเลือกสุดท้าย)
$cmd = Get-Command godot -ErrorAction SilentlyContinue
if ($cmd) { $candidates.Add($cmd.Source) }

if ($candidates.Count -eq 0) {
  Write-Error ("ไม่พบ Godot บนเครื่องนี้ - ติดตั้งด้วย winget install GodotEngine.GodotEngine แล้วรันใหม่")
  exit 1
}

if ($All) { $candidates | ForEach-Object { Write-Output $_ } }
else      { Write-Output $candidates[0] }
