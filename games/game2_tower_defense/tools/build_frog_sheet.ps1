# ประกอบ frog_sheet.png จาก f1..f8 (เฟรมเดิน 8) -> แถวเดียว 512x64
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\frog_frames"
$files = 1..8 | ForEach-Object { "$dir\f$_.png" }
$sheet = New-Object System.Drawing.Bitmap 512, 64
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::Transparent)
$n = 0
foreach ($f in $files) {
  $img = [System.Drawing.Bitmap]::FromFile($f)
  $g.DrawImage($img, [System.Drawing.Rectangle]::new($n * 64, 0, 64, 64))
  $img.Dispose()
  $n++
}
$g.Dispose()
$out = "C:\m-simple-game\tower-defend\assets\art\gen\frog_sheet.png"
$sheet.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "frog_sheet saved: 512x64 (frames f1-f8)"
