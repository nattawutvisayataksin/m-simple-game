# contact sheet 3x3 ของเฟรมกบ (zoom 2x) + grid เพื่อหาเฟรมอ้างอิง/เฟรมซ้ำ
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\frog_frames"
$cell = 128
$sheetSheet = New-Object System.Drawing.Bitmap (3 * $cell), (3 * $cell)
$g = [System.Drawing.Graphics]::FromImage($sheetSheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::FromArgb(255, 90, 140, 200))  # พื้นน้ำเงินให้เห็นขอบโปร่งชัด
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
$sheetSheet.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\frog_contact.png", [System.Drawing.Imaging.ImageFormat]::Png)
$sheetSheet.Dispose()
# เทียบพิกเซล f8 กับ frog.png เดิม (เปอร์เซ็นต์ต่าง)
$ref = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\frog.png")
$refW = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\frog_raw.png")
Write-Output ("frog.png {0}x{1} ; frog_raw.png {2}x{3}" -f $ref.Width, $ref.Height, $refW.Width, $refW.Height)
$ref.Dispose(); $refW.Dispose()
Write-Output "contact saved"
