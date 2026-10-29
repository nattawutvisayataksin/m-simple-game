# ประกอบโลกใหญ่: master v2 (บน 384x216) + แผงทุ่งหญ้า (ล่าง 384x216)
# + วาดถนนแนวตั้งเชื่อมรอยต่อลงประตูใหม่ (ประตูตัดจาก master, ตัดพื้นหญ้าออก)
# ผล = world_raw 384x432 -> upscale 3x = 1152x1296
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$raw = "C:\m-simple-game\tower-defend\assets\art\gen\raw"

$master = [System.Drawing.Bitmap]::FromFile("$raw\kub_kingdom_map_v2_raw.png")
$panel = [System.Drawing.Bitmap]::FromFile("$raw\meadow_panel_raw.png")

$world = New-Object System.Drawing.Bitmap 384, 432
$g = [System.Drawing.Graphics]::FromImage($world)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$g.DrawImage($master, 0, 0, 384, 216)
$g.DrawImage($panel, 0, 216, 384, 216)
$g.Dispose()

# ---- กองถนนแนวตั้ง (ตัวถนนจริงของ master ที่ seam x=280 กว้าง ~19px) ----
# สีจาก sampling ของ master: เท dd = R247 G193 B132, และอาจใช้เส้นเข้มโครง outlin
$roadFill = [System.Drawing.Color]::FromArgb(255, 247, 193, 132)
$roadDark = [System.Drawing.Color]::FromArgb(255, 214, 159, 99)
$edgeDark = [System.Drawing.Color]::FromArgb(255, 176, 118, 68)
$rand = New-Object System.Random 20261029
$x0 = 271; $x1 = 290   # ขอบถนน: นอก 20px กว้าง

# เชิงตรวจ: สี road ที่ x 272-290 ใส่ fill ทั้งแถวทุกแถว (แทนสี)
# ระยะถนนใหม่: จากรอยต่อ (y=216) ลงถึงปากประตู (y=348)
for ($y = 216; $y -le 347; $y++) {
  for ($x = $x0; $x -le $x1; $x++) {
    $c = $roadFill
    if ($x -eq $x0 -or $x -eq $x1) { $c = $edgeDark }
    elseif (($x + $y) % 11 -eq 0 -and $rand.Next(3) -ne 0) { $c = $roadDark }
    $world.SetPixel($x, $y, $c)
  }
}

# ---- ตัดประตูม่วงจาก master (พื้นที่มี cliff เราจะตัดสีเขียว/ถนนออก) ----
$portal = $master.Clone([System.Drawing.Rectangle]::new(52, 6, 60, 84), $master.PixelFormat)
# ตัดทุกพิกเซลสว่าง (หญ้า lum>=150) ที่ติดกับขอบ - ให้เหลือ cliff + ประตู + ปากถนน
$w = $portal.Width; $h = $portal.Height
$visited = New-Object 'bool[,]' $w, $h
$stack = New-Object System.Collections.Stack
function Push-Bright ($x, $y) {
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $script:w -or $y -ge $script:h) { return }
  if ($script:visited[$x, $y]) { return }
  $c = $script:portal.GetPixel($x, $y)
  $lum = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
  if ($lum -ge 150) {
    $script:visited[$x, $y] = $true
    $script:stack.Push(@($x, $y))
    $script:clr.Add(@($x, $y)) | Out-Null
  }
}
$clr = New-Object System.Collections.Generic.List[object]
for ($x = 0; $x -lt $w; $x++) { Push-Bright $x 0; Push-Bright $x ($h - 1) }
for ($y = 0; $y -lt $h; $y++) { Push-Bright 0 $y; Push-Bright ($w - 1) $y }
while ($stack.Count -gt 0) {
  $p = $stack.Pop()
  Push-Bright ($p[0] + 1) $p[1]; Push-Bright ($p[0] - 1) $p[1]
  Push-Bright $p[0] ($p[1] + 1); Push-Bright $p[0] ($p[1] - 1)
}
foreach ($p in $clr) {
  $c = $portal.GetPixel($p[0], $p[1])
  $portal.SetPixel($p[0], $p[1], [System.Drawing.Color]::FromArgb(0, $c.R, $c.G, $c.B))
}

# แปะประตูแกนกลาง x=281 ชิดขอบล่าง: บน y=348, ล่างยึดขอบ 432 พอดี
$gx = [int](281 - $portal.Width / 2)
$portalAttrs = New-Object System.Drawing.Imaging.ImageAttributes
$g2 = [System.Drawing.Graphics]::FromImage($world)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g2.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
$g2.DrawImage($portal, [System.Drawing.Rectangle]::new($gx, 348, $portal.Width, $portal.Height))
$g2.Dispose()

# ---- ยูนิฟอร์มหญ้าแผงล่างทั้งแผง: ตัวเขียวมาตรฐานแผง (160,204,69)±6 -> หญ้า master (150,203,70) ----
for ($y = 216; $y -lt 432; $y++) {
  for ($x = 0; $x -lt 384; $x++) {
    $c = $world.GetPixel($x, $y)
    if ([math]::Abs($c.R - 160) -le 6 -and [math]::Abs($c.G - 204) -le 6 -and [math]::Abs($c.B - 69) -le 9) {
      $world.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 150, 203, 70))
    }
    elseif ([math]::Abs($c.R - 188) -le 8 -and [math]::Abs($c.G - 216) -le 8 -and [math]::Abs($c.B - 77) -le 12) {
      $world.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, 150, 203, 70))
    }
  }
}

# ---- กลืนสีหญ้าแถบรอยต่อ (y 216-239): เฟดหญ้าฝั่งแผงให้เข้าหาสีหญ้า master (R150 G203 B70) ----
for ($y = 216; $y -le 239; $y++) {
  $f = 1.0 - ($y - 216) / 24.0   # 1 ที่รอยต่อ -> 0 ที่ปลายแถบ
  for ($x = 0; $x -lt 384; $x++) {
    $c = $world.GetPixel($x, $y)
    $lum = 0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B
    if ($lum -lt 100) { continue }               # ขอบเข้ม/เงา คงเดิม
    if ($c.G -gt $c.R -and $c.G -gt $c.B -and $c.G -ge 195) {
      # หญ้าทุกเฉด (150-210) คูณตาม f ไปหาสี master
      $nr = [int][math]::Round($c.R * (1 - $f) + 150 * $f)
      $ng = [int][math]::Round($c.G * (1 - $f) + 203 * $f)
      $nb = [int][math]::Round($c.B * (1 - $f) + 70 * $f)
      $world.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $nr, $ng, $nb))
    }
  }
}

# ยืนยันพรีวิวย่อมาก.locks ประหยัด: ตัดช้ม้
$world.Save("$raw\world_raw.png", [System.Drawing.Imaging.ImageFormat]::Png)
$master.Dispose(); $panel.Dispose(); $portal.Dispose(); $world.Dispose()
Write-Output "world_raw saved (384x432)"
