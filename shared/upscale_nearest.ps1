# ขยายภาพพิกเซลแบบ nearest-neighbor (ไม่เบลอ — สำหรับภาพจาก gen ที่ต้องยกกำลัง)
# ใช้: powershell -File tools/upscale_nearest.ps1 -SrcPng a.png -DstPng b.png -Scale 3
param(
  [Parameter(Mandatory=$true)][string]$SrcPng,
  [Parameter(Mandatory=$true)][string]$DstPng,
  [int]$Scale = 3
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcBmp = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SrcPng).Path)
$dstBmp = New-Object System.Drawing.Bitmap ($srcBmp.Width * $Scale), ($srcBmp.Height * $Scale)
$g = [System.Drawing.Graphics]::FromImage($dstBmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($srcBmp, 0, 0, $dstBmp.Width, $dstBmp.Height)
$g.Dispose()
$w = $srcBmp.Width * $Scale
$h = $srcBmp.Height * $Scale
$srcBmp.Dispose()
$dstBmp.Save($DstPng, [System.Drawing.Imaging.ImageFormat]::Png)
$dstBmp.Dispose()
Write-Output ("saved: {0} ({1}x{2})" -f $DstPng, $w, $h)
