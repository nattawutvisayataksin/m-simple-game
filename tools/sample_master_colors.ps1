# สุ่มสีจาก master v2 raw (384x216) ที่จุดถนน/หญ้า เพื่อสร้าง palette วาดถนนแผงล่าง
# ใช้: powershell -File tools/sample_master_colors.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\kub_kingdom_map_v2_raw.png")
$p = @(
  @(100, 214), @(105, 214), @(112, 210), @(280, 214), @(287, 214), @(292, 214),
  @(100, 200), @(280, 200), @(300, 150), @(110, 160),
  @(60, 120), @(200, 120), @(320, 120), @(60, 30)
)
foreach ($q in $p) {
  if ($q[1] -ge $src.Height) { continue }
  $c = $src.GetPixel($q[0], $q[1])
  Write-Output ("({0},{1}) -> R{2} G{3} B{4}" -f $q[0], $q[1], $c.R, $c.G, $c.B)
}
$src.Dispose()
