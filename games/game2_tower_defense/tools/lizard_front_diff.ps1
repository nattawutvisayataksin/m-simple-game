# ปерпรยต แอนิกิ้งก่าหน้าตรง: diff เทียบ lizard_front.png หาเฟรมอ้างอิง + contact sheet
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_front_frames"
$ref = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\lizard_front.png")
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

# contact 3x3
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
  $g.DrawImage($img, [System.Drawing.Rectangle]::new((($i % 3) * $cell), ([int][math]::Floor($i / 3) * $cell), $cell, $cell))
  $g.DrawString("F$i", $font, $brush, [float](($i % 3) * $cell + 4), [float]([int][math]::Floor($i / 3) * $cell + 4))
  $img.Dispose()
}
$g.Dispose()
$s.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\lizard_front_contact.png", [System.Drawing.Imaging.ImageFormat]::Png)
$s.Dispose()
Write-Output "contact saved"
