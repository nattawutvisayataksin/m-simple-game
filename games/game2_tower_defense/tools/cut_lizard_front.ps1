# ตัดพื้นหลัง lizard_front_raw (โปร่ง) - flood fill จากขอบด้วยสีมุม (รองรับเช็คเกอร์ 2 สี)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$srcPath = "C:\m-simple-game\tower-defend\assets\art\gen\raw\lizard_front_raw.png"
$outPath = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_front.png"
$b = [System.Drawing.Bitmap]::FromFile($srcPath)
# สุ่มสีมุมทั้ง 4
foreach ($p in @(@(0,0), @(63,0), @(0,63), @(63,63), @(5,5), @(58,58))) {
  $c = $b.GetPixel($p[0], $p[1])
  Write-Output ("corner ({0},{1}) R{2} G{3} B{4} A{5}" -f $p[0], $p[1], $c.R, $c.G, $c.B, $c.A)
}
# ชุดสีพื้น = สีของ 3 มุมที่เหมือนกันมุกเช็คเกอร์
$cA = $b.GetPixel(0, 0)
$cB = $b.GetPixel(63, 63)
Write-Output ("cA R{0} G{1} B{2} / cB R{3} G{4} B{5}" -f $cA.R, $cA.G, $cA.B, $cB.R, $cB.G, $cB.B)

function IsBg($c) {
  return (([math]::Abs($c.R - $cA.R) -le 8 -and [math]::Abs($c.G - $cA.G) -le 8 -and [math]::Abs($c.B - $cA.B) -le 8) -or
          ([math]::Abs($c.R - $cB.R) -le 8 -and [math]::Abs($c.G - $cB.G) -le 8 -and [math]::Abs($c.B - $cB.B) -le 8))
}
$w = 64; $h = 64
$visited = New-Object 'bool[,]' $w, $h
$stack = New-Object System.Collections.Stack
function Push-IfBg ($x, $y) {
  if ($x -lt 0 -or $x -ge $script:w -or $y -lt 0 -or $y -ge $script:h) { return }
  if ($script:visited[$x, $y]) { return }
  $script:visited[$x, $y] = $true
  if (-not (IsBg $script:b.GetPixel($x, $y))) { return }
  $script:stack.Push(@($x, $y))
}
for ($x = 0; $x -lt $w; $x++) { Push-IfBg $x 0; Push-IfBg $x ($h - 1) }
for ($y = 0; $y -lt $h; $y++) { Push-IfBg 0 $y; Push-IfBg ($w - 1) $y }
$n = 0
while ($stack.Count -gt 0) {
  $p = $stack.Pop()
  $b.SetPixel($p[0], $p[1], [System.Drawing.Color]::FromArgb(0, 255, 255, 255))
  $n++
  Push-IfBg ($p[0] + 1) $p[1]; Push-IfBg ($p[0] - 1) $p[1]
  Push-IfBg $p[0] ($p[1] + 1); Push-IfBg $p[0] ($p[1] - 1)
}
Write-Output "cleared $n pixels"
$b.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()
Write-Output "saved $outPath"
