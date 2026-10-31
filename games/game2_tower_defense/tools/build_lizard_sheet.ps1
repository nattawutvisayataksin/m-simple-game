# lizard_sheet.png จาก f0..f7 (8 เฟรม, f8 = ซ้ำ f0 เพื่อปิดลูป) -> 512x64
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_frames"
$sheet = New-Object System.Drawing.Bitmap 512, 64
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::Transparent)
$n = 0
foreach ($i in 0..7) {
  $img = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png")
  $g.DrawImage($img, [System.Drawing.Rectangle]::new($n * 64, 0, 64, 64))
  $img.Dispose()
  $n++
}
$g.Dispose()
$sheet.Save("C:\m-simple-game\tower-defend\assets\art\gen\lizard_sheet.png", [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "lizard_sheet saved 512x64 (f0-f7)"
