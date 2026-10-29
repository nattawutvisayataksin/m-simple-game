# mockup ฉากใหญ่ 4 เท่า 2304x1296 (อ่างทดลอง): พื้นหญ้า master + ถนนวาดมือ + master บนซ้ายเต็ม
# ตกแต่งด้วยพร็อพ Atlas (LPC CC-BY-SA 3.0) + กลุ่มต้นไม้จาก hyptosis (OpenGameArt)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$art = "C:\m-simple-game\tower-defend\assets"
$dl  = "C:\m-simple-game\download_asset_opengameart"

$W = 2304; $H = 1296
$canvas = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($canvas)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

# ---- พื้นหญ้า master + speckle ----
$grassB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 150, 203, 70))
$g.FillRectangle($grassB, 0, 0, $W, $H)
$rand = New-Object System.Random 777
$darkB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 147, 202, 59))
$liteB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 160, 204, 69))
for ($i = 0; $i -lt 5200; $i++) {
  $x = $rand.Next($W); $y = $rand.Next($H)
  $sz = 2 + $rand.Next(4)
  $bb = $darkB; if ($rand.Next(2) -eq 0) { $bb = $liteB }
  $g.FillRectangle($bb, $x, $y, $sz, $sz)
}

# ---- master bg v2 วางเต็มภาคบนซ้าย (1152x648) ----
$master = [System.Drawing.Bitmap]::FromFile("$art\art\kub_kingdom_map_v2.png")
$g.DrawImage($master, [System.Drawing.Rectangle]::new(0, 0, 1152, 648))
$master.Dispose()

# ---- ถนนวาดมือ (สีวัดจาก master R247 G193 B132 + ขอบเข้ม) ----
function Draw-Road ($pts) {
  $edgeB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 176, 118, 68))
  $fillB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 247, 193, 132))
  for ($pass = 0; $pass -lt 2; $pass++) {
    $r = 34; if ($pass -eq 1) { $r = 30 }
    $b = $edgeB; if ($pass -eq 1) { $b = $fillB }
    for ($i = 0; $i -lt ($pts.Count - 1); $i++) {
      $a = $pts[$i]; $c = $pts[$i + 1]
      $len = [math]::Sqrt([math]::Pow($c[0] - $a[0], 2) + [math]::Pow($c[1] - $a[1], 2))
      $steps = [int]($len / 6) + 1
      for ($s = 0; $s -le $steps; $s++) {
        $t = $s / $steps
        $x = $a[0] + ($c[0] - $a[0]) * $t
        $y = $a[1] + ($c[1] - $a[1]) * $t
        $g.FillEllipse($b, [float]($x - $r), [float]($y - $r), [float](2 * $r), [float](2 * $r))
      }
    }
  }
  # เม็ดดินเข้มเล็ก ๆ โปรยในถนน
  $dirtB = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 214, 159, 99))
  for ($i = 0; $i -lt ($pts.Count - 1); $i++) {
    $a = $pts[$i]; $c = $pts[$i + 1]
    $len = [math]::Sqrt([math]::Pow($c[0] - $a[0], 2) + [math]::Pow($c[1] - $a[1], 2))
    $steps = [int]($len / 4)
    for ($s = 0; $s -le $steps; $s++) {
      if ($rand.Next(3) -ne 0) { continue }
      $t = $s / $steps
      $x = $a[0] + ($c[0] - $a[0]) * $t + $rand.Next(-22, 22)
      $y = $a[1] + ($c[1] - $a[1]) * $t + $rand.Next(-22, 22)
      $g.FillRectangle($dirtB, [float]($x), [float]($y), 4, 3)
    }
  }
}
Draw-Road @(@(843, 640), @(843, 880), @(1300, 1050), @(1600, 1120), @(1600, 1292))

# ---- ประตูม่วง (ตัดจาก master raw, flood ตัดหญ้าเล็งสี) ----
$mw = [System.Drawing.Bitmap]::FromFile("$art\art\gen\raw\kub_kingdom_map_v2_raw.png")
$portal = $mw.Clone([System.Drawing.Rectangle]::new(52, 6, 60, 84), $mw.PixelFormat)
$vis = New-Object 'bool[,]' 60, 84
$st = New-Object System.Collections.Stack
function Push-B ($x, $y) {
  if ($x -lt 0 -or $x -ge 60 -or $y -lt 0 -or $y -ge 84) { return }
  if ($script:vis[$x, $y]) { return }
  $script:vis[$x, $y] = $true
  $c = $script:portal.GetPixel($x, $y)
  $lum = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
  if ($lum -ge 150) {
    $script:st.Push(@($x, $y))
    $script:portal.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, $c.R, $c.G, $c.B))
  }
}
for ($x = 0; $x -lt 60; $x++) { Push-B $x 0; Push-B $x 83 }
for ($y = 0; $y -lt 84; $y++) { Push-B 0 $y; Push-B 59 $y }
while ($st.Count -gt 0) {
  $p = $st.Pop()
  Push-B ($p[0] + 1) $p[1]; Push-B ($p[0] - 1) $p[1]
  Push-B $p[0] ($p[1] + 1); Push-B $p[0] ($p[1] - 1)
}
$g.DrawImage($portal, [System.Drawing.Rectangle]::new(1510, 1044, 180, 252))
$portal.Dispose(); $mw.Dispose()

# ---- พร็อพจาก Atlas terrain (LPC CC-BY-SA 3.0) ----
$atlas = [System.Drawing.Bitmap]::FromFile("$dl\Atlas\terrain_atlas.png")
# ต้นสนใหญ่ (958,8) w66 h150 ย่อ 0.8
function Stamp-Atlas ($x0, $y0, $w, $h, $tx, $ty, $scale) {
  $crop = [System.Drawing.Bitmap]::new($w, $h)
  $gc = [System.Drawing.Graphics]::FromImage($crop)
  $gc.DrawImage($script:atlas, [System.Drawing.Rectangle]::new(0, 0, $w, $h), [System.Drawing.Rectangle]::new($x0, $y0, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
  $gc.Dispose()
  $tw = [int]($w * $scale); $th = [int]($h * $scale)
  $script:g.DrawImage($crop, [System.Drawing.Rectangle]::new([int]($tx - $tw / 2), [int]($ty - $th), $tw, $th))
  $crop.Dispose()
}
# ต้นสนแนวขอบขวาล่าง (จุดแห้งจากที่ตรวจ)
foreach ($p in @(@(1700, 900), @(1830, 990), @(1980, 1060), @(2120, 890), @(2230, 700), @(1960, 690), @(1450, 480), @(2050, 400))) {
  Stamp-Atlas 958 8 66 150 $p[0] $p[1] 0.8
}
# ก้อนหญ้าจริง (36,738) w72 h54 ตารอง 1
foreach ($p in @(@(300, 800), @(150, 1060), @(460, 960), @(720, 1120), @(1250, 1000), @(1420, 1200), @(1900, 500), @(1750, 350))) {
  Stamp-Atlas 36 738 72 54 $p[0] $p[1] 1.0
}
$atlas.Dispose()

# ---- กลุ่มต้นไม้ป่าเข้ม hyptosis batch-1 (แนวขอบล่างซ้าย-ขวาเป็นริมป่า) ----
$hy = [System.Drawing.Bitmap]::FromFile("$dl\hyptosis_tile_art\hyptosis_tile-art-batch-1.png")
function Stamp-Hy ($rgx, $rgy, $w, $h, $tx, $ty, $scale) {
  $crop = [System.Drawing.Bitmap]::new($w, $h)
  $gc = [System.Drawing.Graphics]::FromImage($crop)
  $gc.DrawImage($script:hy, [System.Drawing.Rectangle]::new(0, 0, $w, $h), [System.Drawing.Rectangle]::new($rgx, $rgy, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
  $gc.Dispose()
  $tw = [int]($w * $scale); $th = [int]($h * $scale)
  $script:g.DrawImage($crop, [System.Drawing.Rectangle]::new([int]($tx - $tw / 2), [int]($ty - $th), $tw, $th))
  $crop.Dispose()
}
# ต้นไม้ใหญ่ (385,560) w125 h235 ย่อ 0.55 = 69x129 แถวขนานขอบล่าง
foreach ($p in @(@(60, 1296), @(260, 1280), @(760, 1250), @(1020, 1240), @(1900, 1250), @(2140, 1260))) {
  Stamp-Hy 385 560 125 235 $p[0] $p[1] 0.55
}
# ดงสีเข้มกลม (515,708) w133 h132 ย่อ 0.6 กระจายกลาง
foreach ($p in @(@(500, 1180), @(980, 1120), @(1300, 760), @(2150, 1150))) {
  Stamp-Hy 515 708 133 132 $p[0] $p[1] 0.6
}
$hy.Dispose()

$g.Dispose()
$canvas.Save("$art\art\gen\tmp\big_world_mockup.png", [System.Drawing.Imaging.ImageFormat]::Png)
$canvas.Dispose()
Write-Output "big_world_mockup saved (2304x1296)"
