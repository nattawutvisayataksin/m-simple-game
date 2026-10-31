# ประกอบเฟรมที่ดาวน์โหลดแล้ว (name.frames_NN.png) ให้เป็นspritesheetแถวเดียว
# ใช้: powershell -File build_sprite_sheet.ps1 -Name coin -Out coin_sheet.png
param(
  [Parameter(Mandatory=$true)][string]$Name,
  [Parameter(Mandatory=$true)][string]$Out
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$genDir = "$PSScriptRoot\..\assets\art\gen"
$files = Get-ChildItem "$genDir\$Name.frames_*.png" | Sort-Object Name
if (-not $files) { Write-Output "NO FRAMES for $Name"; exit 1 }

$first = [System.Drawing.Bitmap]::FromFile($files[0].FullName)
$w = $first.Width; $h = $first.Height
$first.Dispose()

$sheet = New-Object System.Drawing.Bitmap(([int]($w * $files.Count)), $h)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.Clear([System.Drawing.Color]::Transparent)

$n = 0
foreach ($f in $files) {
  $img = [System.Drawing.Bitmap]::FromFile($f.FullName)
  if ($img.Width -ne $w -or $img.Height -ne $h) {
    # บีบให้ทุกเฟรมกณีกัน (central crop/resize แบบใกล้เคียง)
    $img = New-Object System.Drawing.Bitmap($img, $w, $h)
  }
  $g.DrawImage($img, [System.Drawing.Rectangle]::new($n * $w, 0, $w, $h))
  $img.Dispose()
  $n++
  Write-Output "frame $n <- $($f.Name)"
}
$g.Dispose()
$outPath = "$genDir\$Out"
$sheet.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "SHEET saved: $outPath ($($files.Count) frames, ${w}x${h}/each)"
