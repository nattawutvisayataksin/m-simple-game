# ตัดพื้นหลังสีมืดของภาพเอฟเฟกต์ให้โปร่งใส — เหมาะกับภาพทองอำพันบนพื้นเกือบดำล้วน
# ใช้งาน: powershell -File tools/make_transparent.ps1 -SrcPng a.png -DstPng b.png [-LumThreshold 70]
param(
  [Parameter(Mandatory=$true)][string]$SrcPng,
  [Parameter(Mandatory=$true)][string]$DstPng,
  [int]$LumThreshold = 70
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$srcBmp = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SrcPng).Path)
$dstBmp = New-Object System.Drawing.Bitmap($srcBmp.Width, $srcBmp.Height)
for ($y = 0; $y -lt $srcBmp.Height; $y++) {
  for ($x = 0; $x -lt $srcBmp.Width; $x++) {
    $col = $srcBmp.GetPixel($x, $y)
    $lum = $col.R * 0.30 + $col.G * 0.59 + $col.B * 0.11
    if ($lum -lt $LumThreshold) {
      $dstBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    } else {
      $dstBmp.SetPixel($x, $y, $col)
    }
  }
}
$srcBmp.Dispose()
$dstBmp.Save($DstPng, [System.Drawing.Imaging.ImageFormat]::Png)
$dstBmp.Dispose()
Write-Output "saved: $DstPng"
