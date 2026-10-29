# ซูมตรวจ 4 โซนจาก terrain_atlas เพื่อหยิบไทล์จริง (พร้อมกริดโชว์พิกัด)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$srcPath = "C:\m-simple-game\download_asset_opengameart\Atlas\terrain_atlas.png"
$src = [System.Drawing.Bitmap]::FromFile($srcPath)
Write-Output ("atlas size: {0}x{1}" -f $src.Width, $src.Height)

function Zoom-Region($x0, $y0, $w, $h, $scale, $name) {
  $crop = [System.Drawing.Bitmap]::new($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($crop)
  $g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $w, $h), [System.Drawing.Rectangle]::new($x0, $y0, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $big = New-Object System.Drawing.Bitmap ($w * $scale), ($h * $scale)
  $g2 = [System.Drawing.Graphics]::FromImage($big)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g2.DrawImage($crop, 0, 0, $w * $scale, $h * $scale)
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(130, 255, 0, 0)), 1
  $font = New-Object System.Drawing.Font ("Consolas"), 11
  $brush = [System.Drawing.Brushes]::Red
  for ($gx = 0; $gx -le $w; $gx += 16) {
    $g2.DrawLine($pen, $gx * $scale, 0, $gx * $scale, $h * $scale)
    if ($gx % 32 -eq 0) { $g2.DrawString("$($x0 + $gx)", $font, $brush, [float]($gx * $scale + 2), 2) }
  }
  for ($gy = 0; $gy -le $h; $gy += 16) {
    $g2.DrawLine($pen, 0, $gy * $scale, $w * $scale, $gy * $scale)
    if ($gy % 32 -eq 0 -and $gy -gt 0) { $g2.DrawString("$($y0 + $gy)", $font, $brush, 2, [float]($gy * $scale + 2)) }
  }
  $g2.Dispose()
  $out = "C:\m-simple-game\tower-defend\assets\art\gen\tmp\$name.png"
  $big.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $big.Dispose(); $crop.Dispose()
  Write-Output "saved $name"
}

# โซน 1: หญ้า/บึงล่างซ้าย
Zoom-Region 0 600 300 400 2 "zoom_grass.png"
# โซน 2: ถนนดินโค้งบนกลาง
Zoom-Region 100 0 320 210 3 "zoom_dirt.png"
# โซน 3: ต้นไม้ขวาบน + ต้นสน
Zoom-Region 900 0 124 120 4 "zoom_tree.png"
# โซน 4: บ้าน/สิ่งปลูกสร้างขวากลาง
Zoom-Region 700 180 340 130 3 "zoom_builds.png"
$src.Dispose()
