# วางสไปรต์บนพื้นสีเพื่อทดสอบความโปร่ง
param([string]$Png, [string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Png).Path)
$sheet = New-Object System.Drawing.Bitmap ($src.Width * 6), ($src.Height * 6)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.Clear([System.Drawing.Color]::FromArgb(255, 180, 90, 190))
$g.DrawImage($src, [System.Drawing.Rectangle]::new(0, 0, $sheet.Width, $sheet.Height))
$g.Dispose()
$src.Dispose()
$sheet.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output "check saved: $Out"
