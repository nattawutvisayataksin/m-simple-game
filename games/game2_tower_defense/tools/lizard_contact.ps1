# contact sheet 3x3 ของเฟรมกิ้งก่า + เทียบกับ lizard.png เพื่อหาเฟรมอ้างอิง
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_frames"
$cell = 128
$s = New-Object System.Drawing.Bitmap (3 * $cell), (3 * $cell)
$g = [System.Drawing.Graphics]::FromImage($s)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255, 90, 140, 200))
$font = New-Object System.Drawing.Font ("Consolas"), 14
$brush = [System.Drawing.Brushes]::Yellow
for ($i = 0; $i -lt 9; $i++) {
  $img = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png")
  $cx = ($i % 3) * $cell
  $cy = [int][math]::Floor($i / 3) * $cell
  $g.DrawImage($img, [System.Drawing.Rectangle]::new($cx, $cy, $cell, $cell))
  $g.DrawString("F$i", $font, $brush, [float]($cx + 4), [float]($cy + 4))
  $img.Dispose()
}
$g.Dispose()
$s.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\lizard_contact.png", [System.Drawing.Imaging.ImageFormat]::Png)
$s.Dispose()

$ref = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\lizard.png")
for ($i = 0; $i -lt 9; $i++) {
  $f = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png")
  $diff = 0
  for ($y = 0; $y -lt 64; $y++) {
    for ($x = 0; $x -lt 64; $x++) {
      $a = $ref.GetPixel($x, $y); $b = $f.GetPixel($x, $y)
      if ([math]::Abs($a.R - $b.R) + [math]::Abs($a.G - $b.G) + [math]::Abs($a.B - $b.B) -gt 40) { $diff++ }
    }
  }
  Write-Output ("f$i diff = $diff")
  $f.Dispose()
}
$ref.Dispose()
