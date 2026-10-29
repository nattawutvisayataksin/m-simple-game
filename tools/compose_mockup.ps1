# ประกอบ mockup สนามเต็ม v2 - ตำแหน่งตามถนนจริงที่ยืนยันจากภาพ
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$art = "C:\m-simple-game\tower-defend\assets"

$canvas = [System.Drawing.Bitmap]::FromFile("$art\art\kub_kingdom_map.png")
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

function Stamp ($name, $x, $y, $scale, $alignBottom) {
  $s = [System.Drawing.Bitmap]::FromFile("$art\art\gen\$name")
  $w = [int]($s.Width * $scale); $h = [int]($s.Height * $scale)
  $py = if ($alignBottom) { [int]($y - $h) } else { [int]($y - $h / 2) }
  $g.DrawImage($s, [System.Drawing.Rectangle]::new([int]($x - $w / 2), $py, $w, $h))
  $s.Dispose()
}

# ป้อม 2 ตำแหน่ง: แนวนอนบน (2) + คลุมบันไดปราสาท (5)
Stamp "tower_archer.png" 385 300 1.5 $false
Stamp "tower_archer.png" 955 570 1.5 $false
# มอนสเตอร์เดินบนถนน: กบบนถนนล่างซ้าย (กำลังไต่ขึ้น) / กิ้งก่าบนถนนแนวนอน
Stamp "frog.png"   300 500 1.5 $true
Stamp "lizard.png" 480 385 1.5 $true
# ฮีโร่ Kubi ยืนบล็อกบันไดปราสาท
Stamp "kubi_hero_neutral.png" 855 505 1.5 $true

# จุดวางว่าง 3 วงทอง (1, 3, 4)
$spotsFree = @(@(150, 195), @(165, 430), @(520, 452))
foreach ($s in $spotsFree) {
  $g.FillEllipse([System.Drawing.Brushes]::Goldenrod, $s[0] - 26, $s[1] - 26, 52, 52)
  $g.DrawEllipse([System.Drawing.Pens]::DarkSlateGray, $s[0] - 26, $s[1] - 26, 52, 52)
}

$g.Dispose()
$canvas.Save("$art\mockup_field_v2.png", [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "mockup v2 saved"
