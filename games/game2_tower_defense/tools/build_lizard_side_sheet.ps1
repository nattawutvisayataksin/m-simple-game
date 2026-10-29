# lizard_side_sheet.png จากฟรีมเก่าประเภทหันข้าง (lizard_frames f1..f8) + วัดแถวเท้าล่างสุด
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_frames"
$sheet = New-Object System.Drawing.Bitmap 512, 64
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::Transparent)
$n = 0
$global:feetRow = -1
foreach ($i in 1..8) {
  $img = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png")
  $g.DrawImage($img, [System.Drawing.Rectangle]::new($n * 64, 0, 64, 64))
  if ($n -eq 0) {
    for ($y = 63; $y -ge 0; $y--) {
      $hit = $false
      for ($x = 0; $x -lt 64; $x++) { if ($img.GetPixel($x, $y).A -gt 40) { $hit = $true; break } }
      if ($hit) { $global:feetRow = $y; break }
    }
  }
  $img.Dispose()
  $n++
}
$g.Dispose()
$sheet.Save("C:\m-simple-game\tower-defend\assets\art\gen\lizard_side_sheet.png", [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output ("lizard_side_sheet saved 512x64 (f1-f8) ; feet row = {0}" -f $global:feetRow)
