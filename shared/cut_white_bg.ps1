# ตัดพื้นหลังขาว/สว่างของภาพ gen ที่ gen มาบนพื้นขาว
# วิธี: flood-fill จากโพิกเซลริมขอบ เดินทะลุเฉพาะพิกเซลสว่าง (lum >= threshold)
# กันตัดทับลึก: พิกเซลภายในที่แยกจากขอบด้วยเส้น outline เข้มไม่โดน
# ใช้: powershell -File tools/cut_white_bg.ps1 -SrcPng a.png -DstPng b.png [-LumThreshold 150]
param(
  [Parameter(Mandatory=$true)][string]$SrcPng,
  [Parameter(Mandatory=$true)][string]$DstPng,
  [int]$LumThreshold = 150
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::FromFile((Resolve-Path $SrcPng).Path)
$w = $bmp.Width; $h = $bmp.Height
$visited = New-Object 'bool[,]' $h, $w

$stack = New-Object System.Collections.Stack
function Push-Bright ($x, $y) {
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $script:w -or $y -ge $script:h) { return }
  if ($script:visited[$y, $x]) { return }
  $c = $script:bmp.GetPixel($x, $y)
  $lum = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
  if ($lum -ge $script:LumThreshold) {
    $script:visited[$y, $x] = $true
    $script:stack.Push(@($x, $y))
    $script:clear.Add(@($x, $y)) | Out-Null
  }
}

$clear = New-Object System.Collections.Generic.List[object]
for ($x = 0; $x -lt $w; $x++) { Push-Bright $x 0; Push-Bright $x ($h - 1) }
for ($y = 0; $y -lt $h; $y++) { Push-Bright 0 $y; Push-Bright ($w - 1) $y }

while ($stack.Count -gt 0) {
  $p = $stack.Pop()
  Push-Bright ($p[0] + 1) $p[1]; Push-Bright ($p[0] - 1) $p[1]
  Push-Bright $p[0] ($p[1] + 1); Push-Bright $p[0] ($p[1] - 1)
}

foreach ($p in $clear) {
  $c = $bmp.GetPixel($p[0], $p[1])
  $c = [System.Drawing.Color]::FromArgb(0, $c.R, $c.G, $c.B)
  $bmp.SetPixel($p[0], $p[1], $c)
}

$bmp.Save($DstPng, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("cut {0} -> {1} ({2}px cleared)" -f $SrcPng, $DstPng, $clear.Count)
