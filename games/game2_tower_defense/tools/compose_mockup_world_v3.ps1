# mockup v3 บนโลกใหญ่ 1152x1296: มอนเฟรมเดินจริง 2 สายพันธุ์ + ป้อม 2 สาย + ฮีโร่ + HUD strip
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$art = "C:\m-simple-game\tower-defend\assets"

$canvas = [System.Drawing.Bitmap]::FromFile("$art\art\kub_world.png")  # 1152x1296
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

function Stamp ($path, $x, $y, $scale) {
  $s = [System.Drawing.Bitmap]::FromFile($path)
  $w = [int]($s.Width * $scale); $h = [int]($s.Height * $scale)
  $g.DrawImage($s, [System.Drawing.Rectangle]::new([int]($x - $w / 2), [int]($y - $h), $w, $h))
  $s.Dispose()
}
function CutStamp ($path, $x, $y, $scale, $flip) {
  # จากเฟรมเดิน (ทั้งชิ้น 64x64 มีขอบว่างบน) จัดปลายเท้าที่ y
  $s = [System.Drawing.Bitmap]::FromFile($path)
  $w = [int]($s.Width * $scale); $h = [int]($s.Height * $scale)
  $g.DrawImage($s, [System.Drawing.Rectangle]::new([int]($x - $w / 2), [int]($y - $h * 0.82), $w, $h))
  $s.Dispose()
}

# เส้นทาง A (ประตูบน): จุด waypoint วงพลูเล็กให้เห็นเส้นทางใหม่
$penA = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 180, 90, 255)), 3
$ptsA = @(@(261,250), @(261,420), @(285,500), @(430,548), @(560,545), @(700,545), @(816,500))
foreach ($p in $ptsA) { $g.DrawEllipse($penA, $p[0] - 5, $p[1] - 5, 10, 10) }
# เส้นทาง C (ประตูล่าง)
$ptsC = @(@(843,1125), @(843,960), @(843,800), @(816,500))
foreach ($p in $ptsC) { $g.DrawEllipse($penA, $p[0] - 5, $p[1] - 5, 10, 10) }

# ลานจุดวางป้อม 5 จุด (วงทอง)
foreach ($s in @(@(110,380), @(420,615), @(620,350), @(700,620), @(950,1150))) {
  $g.FillEllipse([System.Drawing.Brushes]::Goldenrod, $s[0] - 26, $s[1] - 26, 52, 52)
  $g.DrawEllipse([System.Drawing.Pens]::DarkSlateGray, $s[0] - 26, $s[1] - 26, 52, 52)
}

# มอนสเตอร์เฟรมเดินจริง (ตัวอย่าง 1 เฟรมตำแหน่งบนถนน)
CutStamp "$art\art\gen\frog_frames\f1.png"   300 430 1.5 $false
CutStamp "$art\art\gen\frog_frames\f5.png"   560 560 1.5 $false
CutStamp "$art\art\gen\lizard_frames\f2.png" 843 900 1.5 $true
CutStamp "$art\art\gen\lizard_frames\f6.png" 660 585 1.5 $true

# ป้อม 2 สาย + ฮีโร่บล็อกหน้าปราสาท
Stamp "$art\art\gen\tower_archer.png" 110 380 1.5
Stamp "$art\art\gen\tower_cannon.png" 700 620 1.5
Stamp "$art\art\gen\kubi_hero_neutral.png" 816 505 1.5

# HUD strip ทด (รูปไอคอนจริงจะเป็น TextureRect แนบ CanvasLayer)
$hudBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(200, 24, 14, 6))
$g.FillRectangle($hudBrush, 12, 12, 300, 84)
$icons = @("$art\art\icons\bow.png", "$art\art\icons\hammer.png", "$art\art\icons\coin.png", "$art\art\icons\heart.png")
$ix = 24
foreach ($ic in $icons) {
  $ic2 = [System.Drawing.Bitmap]::FromFile($ic)
  $g.DrawImage($ic2, [System.Drawing.Rectangle]::new($ix, 20, 64, 64))
  $ic2.Dispose()
  $ix += 72
}

$g.Dispose()
$canvas.Save("$art\art\gen\tmp\mockup_world_v3.png", [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "mockup_world_v3 saved"
