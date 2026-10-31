# zoom 2x ทั้ง master raw + grid ทุก 20px เพื่อตามเส้นถนนแน่ ๆ
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\kub_kingdom_map_v2_raw.png")
$zoom = New-Object System.Drawing.Bitmap 768, 432
$g = [System.Drawing.Graphics]::FromImage($zoom)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.DrawImage($src, 0, 0, 768, 432)
$font = New-Object System.Drawing.Font ("Consolas"), 11
$brush = [System.Drawing.Brushes]::Red
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(110, 255, 0, 0)), 1
for ($x = 0; $x -le 384; $x += 20) {
  $g.DrawLine($pen, $x * 2, 0, $x * 2, 432)
  $g.DrawString("$x", $font, $brush, [float]($x * 2 + 2), [float]($x * 2 + 2))
}
for ($y = 0; $y -le 216; $y += 20) {
  $g.DrawLine($pen, 0, $y * 2, 768, $y * 2)
  if ($y -gt 0) { $g.DrawString("$y", $font, $brush, [float]($y * 2 + 2), 2) }
}
$g.Dispose()
$zoom.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\master_grid.png", [System.Drawing.Imaging.ImageFormat]::Png)
$zoom.Dispose(); $src.Dispose()
Write-Output "master_grid saved"
