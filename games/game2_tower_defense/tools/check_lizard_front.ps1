# เช็คพื้นหลังโปร่งของ lizard_front_raw แล้วตัดพื้นขาวถ้ามี
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$b = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\lizard_front_raw.png")
$t = 0
for ($y = 0; $y -lt $b.Height; $y++) {
  for ($x = 0; $x -lt $b.Width; $x++) {
    if ($b.GetPixel($x, $y).A -lt 100) { $t++ }
  }
}
Write-Output ("transparent <100: {0} / {1} ({2}%)" -f $t, ($b.Width * $b.Height), [int]($t * 100 / ($b.Width * $b.Height)))
$b.Dispose()
