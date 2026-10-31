# สร้างสกินฮีโร่ (palette hue-shift) จาก kubi_hero_run_sheet.png
# ผลลัพธ์: assets/art/gen/kubi_hero_run_sheet_cyan.png / _ember.png
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = Join-Path $PSScriptRoot '..\assets\art\gen'
$src = [System.Drawing.Bitmap]::FromFile((Join-Path (Join-Path $PSScriptRoot '..\assets\art\sprites') 'kubi_hero_run_sheet.png'))

function Make-Skin([System.Drawing.Bitmap]$base, [string]$path, [double]$hueDelta) {
    $out = New-Object System.Drawing.Bitmap($base.Width, $base.Height)
    for ($y = 0; $y -lt $base.Height; $y++) {
        for ($x = 0; $x -lt $base.Width; $x++) {
            $c = $base.GetPixel($x, $y)
            if ($c.A -le 0) { continue }
            $mn = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
            $mx = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
            $sat = if ($mx -gt 0) { 1.0 - ($mn / $mx) } else { 0.0 }
            # สกิน: หมุนฮิวเฉพาะพิกเซลสีสด (ออกไลน์/ขาวขอบนิ่ง)
            if ($sat -gt 0.35 -and $mx -gt 40) {
                $hue = $c.GetHue() + $hueDelta
                if ($hue -lt 0) { $hue += 360 }
                if ($hue -ge 360) { $hue -= 360 }
                $s = $c.GetSaturation()
                $v = $c.GetBrightness()
                $nc = From-Hsv $hue $s $v
                $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A, $nc[0], $nc[1], $nc[2]))
            } else {
                $out.SetPixel($x, $y, $c)
            }
        }
    }
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $out.Dispose()
    Write-Host "สร้าง $(Split-Path $path -Leaf)"
}

function From-Hsv([double]$h, [double]$s, [double]$v) {
    # HSV(0-360,0-1,0-1) → RGB 0-255
    $c = $v * $s
    $hp = $h / 60.0
    $x = $c * (1.0 - [Math]::Abs(($hp % 2.0) - 1.0))
    switch ([int]$hp) {
        0 { $r = $c; $g = $x; $b = 0.0 }
        1 { $r = $x; $g = $c; $b = 0.0 }
        2 { $r = 0.0; $g = $c; $b = $x }
        3 { $r = 0.0; $g = $x; $b = $c }
        4 { $r = $x; $g = 0.0; $b = $c }
        default { $r = $c; $g = 0.0; $b = $x }
    }
    $m = $v - $c
    return @([int](($r + $m) * 255), [int](($g + $m) * 255), [int](($b + $m) * 255))
}

Make-Skin $src (Join-Path $dir 'kubi_hero_run_sheet_cyan.png') 165.0
Make-Skin $src (Join-Path $dir 'kubi_hero_run_sheet_ember.png') -55.0
Make-Skin $src (Join-Path $dir 'kubi_hero_run_sheet_violet.png') 250.0
Make-Skin $src (Join-Path $dir 'kubi_hero_run_sheet_leaf.png') 95.0
$src.Dispose()
