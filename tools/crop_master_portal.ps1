# crop โซนประตูม่วงใน master raw + ซูม 4x เพื่อหา bbox แน่ ๆ
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\kub_kingdom_map_v2_raw.png")
# ทั้งโซนซ้ายบน 0-160 x 0-110
$rect = [System.Drawing.Rectangle]::new(0, 0, 160, 110)
$crop = $src.Clone($rect, $src.PixelFormat)
$zoom = New-Object System.Drawing.Bitmap 640, 440
$g = [System.Drawing.Graphics]::FromImage($zoom)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.DrawImage($crop, 0, 0, 640, 440)
# grid ทุก 10px (แสดงพิกัด)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(90, 255, 0, 0)), 1
$font = New-Object System.Drawing.Font ("Consolas"), 9
$brush = [System.Drawing.Brushes]::Red
for ($x = 0; $x -le 160; $x += 10) {
  $g.DrawLine($pen, $x * 4, 0, $x * 4, 440)
  if ($x % 20 -eq 0) { $g.DrawString("$x", $font, $brush, [float]($x * 4 + 2), [float]($x + 0)) }
}
$g.Dispose()
$zoom.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\portal_zone.png", [System.Drawing.Imaging.ImageFormat]::Png)
$zoom.Dispose(); $crop.Dispose(); $src.Dispose()
Write-Output "portal_zone saved"
