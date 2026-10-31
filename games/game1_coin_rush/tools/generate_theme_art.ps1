# เครื่องมือสร้างศิลป์ใหม่ของเกม 1 (ธีม: ท่อระบาย/ท้องฟ้า/ปราสาท + มอนสเตอร์บัต/ชาร์เจอร์)
# วาดแบบพิกเซลจากแผนที่ ASCII → upscale nearest → PNG ที่ขนาดเทียบ asset เดิม
# รัน:  pwsh -File tools/generate_theme_art.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$genDir = Join-Path $PSScriptRoot '..\assets\art\gen'
New-Item -ItemType Directory -Force -Path $genDir | Out-Null

function New-Canvas([int]$w, [int]$h) { return New-Object System.Drawing.Bitmap($w, $h) }

function New-Palette([string]$spec) {
    # spec เช่น "B#4a2d7a,b#8a63d8" → Dictionary อ่านตัวอักษรโดแต่บรึยากรต้องระวังให้ตรงเรียงตัวอักษร
    $d = New-Object 'System.Collections.Generic.Dictionary[string,string]'([System.StringComparer]::Ordinal)
    foreach ($pair in $spec.Split(',')) {
        $d[$pair[0].ToString()] = $pair.Substring(1)
    }
    return $d
}

function Save-Ascii([object[]]$map, [System.Collections.Generic.Dictionary[string,string]]$pal, [string]$path, [int]$scale) {
    $h = $map.Count
    $w = $map[0].Length
    $bmp = New-Canvas $w $h
    for ($y = 0; $y -lt $h; $y++) {
        $row = $map[$y]
        for ($x = 0; $x -lt $w; $x++) {
            $c = [string]$row[$x]
            if ($pal.ContainsKey($c)) {
                $col = [System.Drawing.ColorTranslator]::FromHtml($pal[$c])
                $bmp.SetPixel($x, $y, $col)
            }
        }
    }
    $out = New-Canvas ($w * $scale) ($h * $scale)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($bmp, 0, 0, $out.Width, $out.Height)
    $g.Dispose()
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose(); $bmp.Dispose()
    Write-Host ("สร้าง {0} ({1}x{2})" -f (Split-Path $path -Leaf), $out.Width, $out.Height)
}

# ---------- มอนสเตอร์ 1: บัตบิต (ค้างคาวไวรัสบินลอย ปักกระทบเหลื่อมพิกเซลไฟฟ้า) ----------
$chaNear = $null
$batMap = @(
    '................',
    '..W...........W.',
    '.Www.........wwW',
    '.Wwww.......wwwW',
    '.WwwwwBbbbBwwwwW',
    '..WwwBBBBBBBww..',
    '...WBbBBBBBbw...',
    '....BEBBBBEB....',
    '....BBBBBBBB....',
    '....BBGGMGGB....',
    '....bbbGGGbbb...',
    '.....BbGGGgb....',
    '.....BbbbbbB....',
    '......BBbbbb....',
    '.......mB..Bm...',
    '...........m....'
)

# ---------- มอนสเตอร์ 2: ชาร์เจอร์ (แมลงแอกรีชกดเร่งชน โครงแข็งมีต่วมหนาม) ----------
$chaMap = @(
    '................',
    '.......RrRR.....',
    '......RrrrrR....',
    '..OOOORrrrrR....',
    '.OOOOORrrrrROO..',
    'CRROOORRYYRROO..',
    'CCrRRRYYWWYYRR..',
    'CCrRRRRRRRRRR...',
    '.RRRDDDDDDRR....',
    '.RRDDDRRRDDO....',
    '..RDDRRRRDDO....',
    '..RRDDDDRRR.....',
    '...KKKKKKKK.....',
    '..KKKKKKKKKKK...',
    '..KKKKKKKKKK....',
    '................'
)

# ---------- แหล่งช่วยวาดฉากระดับพิกเซล (แคนวาเล็ก แล้ว upscale) ----------
function Bg([int]$w, [int]$h, [object]$draw) {
    $bmp = New-Canvas $w $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
    & $draw $g $w $h
    $g.Dispose()
    return $bmp
}

function Save-Up([System.Drawing.Bitmap]$src, [string]$path, [int]$scale) {
    $out = New-Canvas ($src.Width * $scale) ($src.Height * $scale)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.DrawImage($src, 0, 0, $out.Width, $out.Height)
    $g.Dispose()
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose(); $src.Dispose()
    Write-Host ("สร้าง {0}" -f (Split-Path $path -Leaf))
}

function FillRect([System.Drawing.Graphics]$g, [string]$hex, [int]$x, [int]$y, [int]$w, [int]$h) {
    $g.FillRectangle((New-Object System.Drawing.SolidBrush(([System.Drawing.ColorTranslator]::FromHtml($hex)))), $x, $y, $w, $h)
}
function FillEllipse([System.Drawing.Graphics]$g, [string]$hex, [int]$x, [int]$y, [int]$w, [int]$h) {
    $g.FillEllipse((New-Object System.Drawing.SolidBrush(([System.Drawing.ColorTranslator]::FromHtml($hex)))), $x, $y, $w, $h)
}
function FillPoly([System.Drawing.Graphics]$g, [string]$hex, [object[]]$pts) {
    $g.FillPolygon((New-Object System.Drawing.SolidBrush(([System.Drawing.ColorTranslator]::FromHtml($hex)))), $pts)
}

# ---------- ธีมท่อระบาย (หลังไกล 200x112 → 400x224) ----------
$sewerFar = {
    param($g, $w, $h)
    FillRect $g '#0f2429' 0 0 $w $h
    FillRect $g '#14323a' 0 0 $w 40
    FillRect $g '#1a4048' 0 40 $w 16
    # ท่อปรปุนน้ำสีทอนแนวทับทิม. ไม่หย่อนขาด (ขอบซ้ายสุด/ขวาสุดเตล็ดรุ่นเชงง)
    for ($i = 0; $i -lt 3; $i++) {
        $py = 22 + $i * 26
        FillRect $g '#204c52' 0 $py $w 10
        FillRect $g '#2d6b70' 0 $py $w 3
        FillRect $g '#163a40' 0 ($py + 7) $w 3
        for ($x = 10; $x -lt $w; $x += 34) { FillRect $g '#33797f' $x ($py - 2) 6 14 }
    }
    # น้ำสับทผุดออกซีน ยังเป็นปลวกจุดสนับสนุนเยื้องโอโคคุม
    FillRect $g '#0a191d' 0 ($h - 18) $w 18
    for ($x = 4; $x -lt $w; $x += 52) {
        FillEllipse $g '#2e8b4f' $x ($h - 26) 14 10
        FillEllipse $g '#37a35a' ($x + 3) ($h - 24) 8 6
    }
    # เมืองกัลเลียเซลัสสลอด. (เส้นโค้งฉพทมาลรุ่น)
    for ($x = 18; $x -lt $w; $x += 44) {
        FillRect $g '#12323a' $x 58 10 40
        FillEllipse $g '#0e262c' ($x - 4) 62 18 12
    }
}

# ---------- ธีมถลองฟ้า (หลังไกล 200x112 → 400x224) ----------
$skyFar = {
    param($g, $w, $h)
    FillRect $g '#7ec8f5' 0 0 $w $h
    FillRect $g '#a8ddfa' 0 30 $w $h
    FillRect $g '#eef7ff' 0 62 $w $h
    # เมฆก้อนพักชแล้วกิ้งแบบสั้น... (แปลงกายเป็นก้อนเมฆงอาดชั้น)
    foreach ($c in @(@(18, 26, 30), @(70, 18, 40), @(130, 30, 46), @(176, 14, 34))) {
        FillEllipse $g '#ffffff' $c[0] $c[1] $c[2] ($c[2] / 2)
    }
    FillEllipse $g '#fff9d8' 168 8 22 22
    FillEllipse $g '#ffe27a' 170 10 18 18
}

# ---------- ธีมปราสาท (หลังไกล 200x112 → 400x224) ----------
$castleFar = {
    param($g, $w, $h)
    FillRect $g '#241a35' 0 0 $w $h
    FillRect $g '#3a2550' 0 40 $w $h
    FillEllipse $g '#f4e7ff' 170 12 20 20
    # ปราสาททรงกลม (เปลทั้งทีผนึกคุมขาด: ขอบซ้าย/ขวาไม่ทำมเพดาน)
    foreach ($t in @(@(26, 88, 44), @(92, 78, 34), @(150, 92, 50))) {
        $x = $t[0]; $th = $t[1]; $tw = $t[2]
        FillRect $g '#1c1430' $x ($h - $th) $tw $th
        for ($b = 0; $b -lt $tw; $b += 8) { FillRect $g '#1c1430' ($x + $b) ($h - $th - 6) 5 7 }
        foreach ($wy in @(($h - $th + 12), ($h - $th + 34))) {
            FillRect $g '#ff4fd8' $x 0 0 0
            FillRect $g '#ff4fd8' ($x + [int]($tw / 2) - 3) $wy 6 10
        }
        FillPoly $g '#170f2b' @((New-Object System.Drawing.Point(($x - 3), ($h - $th))), (New-Object System.Drawing.Point(($x + [int]($tw / 2)), ($h - $th - 22))), (New-Object System.Drawing.Point(($x + $tw + 3), ($h - $th))))
    }
}

# ---------- แถบ "ไรล์" ระยะใกล้ 120x112 → 240x224 (โปร่างด้านบน) ----------
$sewerNear = {
    param($g, $w, $h)
    for ($x = 0; $x -lt $w; $x += 26) {
        FillRect $g '#10222a' $x ($h - 46) 22 46
        FillPoly $g '#0c1a21' @((New-Object System.Drawing.Point(($x + 6), ($h - 46))), (New-Object System.Drawing.Point(($x + 11), ($h - 60))), (New-Object System.Drawing.Point(($x + 16), ($h - 46))))
    }
    FillRect $g '#0a171c' 0 ($h - 20) $w 20
}

$skyNear = {
    param($g, $w, $h)
    foreach ($c in @(@(0, 78, 66), @(58, 66, 58), @(118, 70, 62))) {
        FillEllipse $g '#e9f7dd' $c[0] ($h - $c[1] + 8) $c[2] ($c[1])
        FillEllipse $g '#c8ecb4' $c[0] ($h - $c[1] + 26) $c[2] ($c[1])
    }
    FillRect $g '#4aa66e' 0 ($h - 16) $w 16
}

$castleNear = {
    param($g, $w, $h)
    for ($x = 0; $x -lt $w; $x += 34) {
        FillPoly $g '#150f22' @((New-Object System.Drawing.Point($x, $h)), (New-Object System.Drawing.Point(($x + 17), ($h - 64))), (New-Object System.Drawing.Point(($x + 34), $h)))
        FillRect $g '#150f22' ($x + 13) ($h - 40) 8 40
    }
    FillRect $g '#100b1a' 0 ($h - 18) $w 18
}

Save-Ascii $batMap (New-Palette 'W#2c1a4d,w#5a3d92,B#4a2d7a,b#8a63d8,E#35f0ff,M#fff8f0,G#38d9ff,m#ff4fd8') (Join-Path $genDir 'enemy_bat.png') 2
Save-Ascii $chaMap (New-Palette 'R#d43a2f,r#f26a4a,D#7a1f16,Y#ffd23f,C#f5e9d0,K#3a2a22,O#f8d67a,W#ffffff') (Join-Path $genDir 'enemy_charger.png') 2
Save-Up (Bg 200 112 $sewerFar) (Join-Path $genDir 'bg_sewer.png') 2
Save-Up (Bg 200 112 $skyFar) (Join-Path $genDir 'bg_sky.png') 2
Save-Up (Bg 200 112 $castleFar) (Join-Path $genDir 'bg_castle.png') 2
Save-Up (Bg 120 112 $sewerNear) (Join-Path $genDir 'hills_sewer.png') 2
Save-Up (Bg 120 112 $skyNear) (Join-Path $genDir 'hills_sky.png') 2
Save-Up (Bg 120 112 $castleNear) (Join-Path $genDir 'hills_castle.png') 2
