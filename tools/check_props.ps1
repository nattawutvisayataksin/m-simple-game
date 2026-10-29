# ตัดพร็อปที่ใช้เป็นไฟล์แยก เพื่อเห็นขอบเขตจริงก่อนรีคลุกล้า
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dl = "C:\m-simple-game\download_asset_opengameart"
$out = "C:\m-simple-game\tower-defend\assets\art\gen\tmp"

# 1) atlas pine ตาม bbox เดิม -> crop แสดงเอง
$atlas = [System.Drawing.Bitmap]::FromFile("$dl\Atlas\terrain_atlas.png")
function Save-Crop ($img, $x, $y, $w, $h, $name, $scale) {
  $c = [System.Drawing.Bitmap]::new($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($c)
  $g.DrawImage($img, [System.Drawing.Rectangle]::new(0, 0, $w, $h), [System.Drawing.Rectangle]::new($x, $y, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $big = New-Object System.Drawing.Bitmap ($w * $scale), ($h * $scale)
  $g2 = [System.Drawing.Graphics]::FromImage($big)
  $g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
  $g2.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g2.DrawImage($c, 0, 0, $w * $scale, $h * $scale)
  $g2.Dispose()
  $big.Save("$out\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $big.Dispose(); $c.Dispose()
}
Save-Crop $atlas 958 8 66 292 "prop_pine_check" 1
$atlas.Dispose()

# 2) hyptosis batch-1 ซูมโซนต้นไม้
$hy = [System.Drawing.Bitmap]::FromFile("$dl\hyptosis_tile_art\hyptosis_tile-art-batch-1.png")
Write-Output ("hyptosis size: {0}x{1}" -f $hy.Width, $hy.Height)
Save-Crop $hy 300 560 420 300 "hyptosis_trees_zoom" 2
$hy.Dispose()
Write-Output "saved"
