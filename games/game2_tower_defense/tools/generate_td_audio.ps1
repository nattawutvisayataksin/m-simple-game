# สร้างไฟล์เสียงทั้งหมดของเกม 2 (หอคอยคู่ฟ้า) — สังเคราะห์สัญญาณล้วน ฟรี ไม่กีนโควตา gen
# ใช้: pwsh -File tools/generate_td_audio.ps1
# ผลลัพธ์: assets/audio/*.wav
#   music_prep.wav  = เพลงระหว่างเตรียมคลื่น (สงบ วงลูปได้)
#   music_wave.wav  = เพลงยามคลื่นบุก (ตึงเครียด วงลูปได้)
#   + SFX: shoot_arrow, shoot_cannon, shoot_mage, explosion, enemy_die, coin,
#          leak_alarm, wave_horn, build, sell, hero_slash, click, win, lose

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $PSScriptRoot '..\assets\audio'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$sr = 22050

function Save-Wav([string]$file, [double[]]$samples, [bool]$Normalize = $false) {
    if ($Normalize) {
        $peak = 0.0
        foreach ($v in $samples) { $a = [Math]::Abs($v); if ($a -gt $peak) { $peak = $a } }
        if ($peak -gt 1e-9) {
            $g = 32000.0 / $peak
            for ($i = 0; $i -lt $samples.Length; $i++) { $samples[$i] *= $g }
        }
    }
    $dataLen = $samples.Length * 2
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $ascii = [System.Text.Encoding]::ASCII
    $bw.Write($ascii.GetBytes("RIFF")); $bw.Write([int]($dataLen + 36))
    $bw.Write($ascii.GetBytes("WAVE")); $bw.Write($ascii.GetBytes("fmt "))
    $bw.Write([int]16); $bw.Write([Int16]1); $bw.Write([Int16]1)
    $bw.Write([int]$sr); $bw.Write([int]($sr * 2)); $bw.Write([Int16]2); $bw.Write([Int16]16)
    $bw.Write($ascii.GetBytes("data")); $bw.Write([int]$dataLen)
    foreach ($v in $samples) {
        $x = [Math]::Max(-32767.0, [Math]::Min(32767.0, $v))
        $bw.Write([Int16][Math]::Round($x))
    }
    $bw.Flush(); [System.IO.File]::WriteAllBytes($file, $ms.ToArray()); $bw.Dispose(); $ms.Dispose()
    Write-Host ("สร้าง " + (Split-Path $file -Leaf) + " ($($samples.Length) samples)")
}

# --- สัญญาณพื้นฐาน ---
function Sq([double]$freq, [int]$n, [double]$vol, [double]$duty = 0.5) {
    $s = New-Object 'double[]' $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $ph += $freq / $sr
        if ($ph -ge 1.0) { $ph -= [Math]::Floor($ph) }
        if (($ph % 1.0) -lt $duty) { $s[$i] = $vol } else { $s[$i] = -$vol }
    }
    return $s
}
function Tri([double]$freq, [int]$n, [double]$vol) {
    $s = New-Object 'double[]' $n
    $ph = 0.0
    for ($i = 0; $i -lt $n; $i++) {
        $ph = ($ph + $freq / $sr) % 1.0
        $w = $ph * 2.0; if ($w -gt 1.0) { $w = 2.0 - $w }
        $s[$i] = ($w * 2.0 - 1.0) * $vol
    }
    return $s
}
function Noise([int]$n, [double]$vol) {
    $s = New-Object 'double[]' $n
    $rnd = New-Object System.Random 20261
    for ($i = 0; $i -lt $n; $i++) { $s[$i] = ($rnd.NextDouble() * 2.0 - 1.0) * $vol }
    return $s
}
# เข้าเสียง: attack สั้น + decay ตาม progress + release กันตัด
function ADS([double[]]$s, [double]$a = 0.005, [double]$r = 0.03, [double]$decay = 0.6) {
    $n = $s.Length
    $an = [int]($a * $sr); $rn = [int]($r * $sr)
    for ($i = 0; $i -lt $n; $i++) {
        $eg = 1.0 - $decay * ($i / $n)
        if ($i -lt $an -and $an -gt 0) { $eg *= $i / $an }
        if ($i -gt $n - $rn) { $eg *= ($n - $i) / $rn }
        $s[$i] *= $eg
    }
    return $s
}
function Mix([double[][]]$tracks) {
    $len = 0
    foreach ($t in $tracks) { if ($t.Length -gt $len) { $len = $t.Length } }
    $out = New-Object 'double[]' $len
    foreach ($t in $tracks) { for ($i = 0; $i -lt $t.Length; $i++) { $out[$i] += $t[$i] } }
    return $out
}
function At([double[]]$s, [double[]]$into, [int]$offset) {
    for ($i = 0; $i -lt $s.Length; $i++) {
        $j = $offset + $i
        if ($j -lt $into.Length) { $into[$j] += $s[$i] }
    }
}
function Freq([double]$midi) { return 440.0 * [Math]::Pow(2.0, ($midi - 69.0) / 12.0) }

# ============ เพลงเตรียมคลื่น (สงบ) — 116 BPM, 8 บาร์ ปิดขอบลูปสนุกเดิม ============
function Build-PrepMusic {
    $bpm = 116.0
    $beat = [int][Math]::Round($sr * 60.0 / $bpm)      # samples/beat
    $bar = $beat * 4
    $total = $bar * 8
    $mix = New-Object 'double[]' $total
    # คอร์ดแนวอบอุ่นมาเกมเก็บแผน: C – Am – F – G  (root octave 2/3)
    $chords = @(
        @{root = 48; third = 4}, @{root = 45; third = 3},
        @{root = 41; third = 4}, @{root = 43; third = 4},
        @{root = 48; third = 4}, @{root = 45; third = 3},
        @{root = 41; third = 4}, @{root = 43; third = 4}
    )
    for ($b = 0; $b -lt 8; $b++) {
        $c = $chords[$b]; $base = $c.root
        $r = $base; 
        # bass: root ยshaft 1 ทีต่อบาร์ (tri นุ่ม)
        At (ADS (Tri (Freq $r) $bar 0.20) 0.01 0.05 0.35) $mix ($b * $bar)
        # pad: root+2 เข้าไปไต่เดิม (square เบา ๆ)
        At (ADS (Sq (Freq ($r + 12)) $bar 0.055 0.35) 0.08 0.1 0.25) $mix ($b * $bar)
        # arpeggio 8th: root+12, +14, +16, +19 กลายเป็นดนตรีไข่ต้มเดิม ๆ มีชีวิตต่างกัน
        $a1 = ($r + 12); $a2 = ($r + 14); $a3 = ($r + 16); $a4 = ($r + 19)
        $arpIdx = @($a1, $a2, $a3, $a2, $a4, $a3, $a2, $a1)
        for ($k = 0; $k -lt 8; $k++) {
            $n = [int]($beat / 2)
            At (ADS (Sq (Freq $arpIdx[$k]) $n 0.07 0.45) 0.004 0.02 0.5) $mix ($b * $bar + [int]($k * $n))
        }
        # hi-hat เบาบนสองจังหวะของหลัง
        $sn = Noise ([int]($beat / 2)) 0.05
        ADS $sn 0.001 0.02 0.92 | Out-Null
        At $sn $mix ($b * $bar + [int]($beat * 3))
    }
    # เสียงอาจถ้าไม่ใช่ loop เปล้ทิ้ง: หุบ tail ท้ายท่อนให้ปลาย = ต้น (0 เล) เงียบสุดแต่มันไถงแฟลซ
    return ($mix | ForEach-Object { $_ })
}

# ============ เพลงคลื่นบุก (ตึงเครียด) — 150 BPM, 8 บาร์โพเกชัน ============
function Build-WaveMusic {
    $bpm = 150.0
    $beat = [int][Math]::Round($sr * 60.0 / $bpm)
    $bar = $beat * 4
    $total = $bar * 8
    $mix = New-Object 'double[]' $total
    # Am – F – G – E  กลมายึดดึงเครียด (อายุดชึ้งท้ายก่อนกลับเดิม)
    $chords = @(
        @{root = 45; third = 3}, @{root = 41; third = 4},
        @{root = 43; third = 4}, @{root = 40; third = 4},
        @{root = 45; third = 3}, @{root = 41; third = 4},
        @{root = 43; third = 4}, @{root = 40; third = 3}
    )
    for ($b = 0; $b -lt 8; $b++) {
        $c = $chords[$b]; $r = $c.root
        # ด้านพนัน: bass 8th ย้าย root ถี่เพื่อขับทั้งทางดีด
        for ($k = 0; $k -lt 8; $k++) {
            $n = [int]($beat / 2)
            $m = $r - 12
            if ($k % 2 -eq 1) { $m = $r + 7 - 12 }
            At (ADS (Sq (Freq $m) $n 0.22 0.55) 0.003 0.01 0.35) $mix ($b * $bar + [int]($k * $n))
        }
        # lead 4th ย้ายสายเปลี่ยนทิศ: แนวโขนการตึงทางขึ้นสู่ปราสาท
        $mel = 0, 2, 3, 2, 5, 3, 2, 0
        for ($k = 0; $k -lt 8; $k++) {
            $n = [int]($beat / 2)
            At (ADS (Sq (Freq ($r + 12 + $mel[$k])) $n 0.075 0.4) 0.004 0.02 0.55) $mix ($b * $bar + [int]($k * $n))
        }
        # snare noise ทุก beat หนัก ๆ จังหวะที่ 2,4 ของแคซ
        foreach ($q in @(1, 3)) {
            $sn = Noise ([int]($beat / 2)) 0.16
            ADS $sn 0.001 0.04 0.85 | Out-Null
            At $sn $mix ($b * $bar + [int]($q * $beat))
        }
        # kick: จังหวะแรกของทุก beat (ต่ำ 60Hz ไส้สั้น)
        for ($q = 0; $q -lt 4; $q++) {
            $n = [int]($beat / 3)
            $s = New-Object 'double[]' $n
            for ($i = 0; $i -lt $n; $i++) {
                $t = $i / $sr
                $f = 110.0 * [Math]::Exp(-24.0 * $t)
                $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.35 * (1.0 - $i / $n)
            }
            At $s $mix ($b * $bar + [int]($q * $beat))
        }
    }
    return $mix
}

# ============ SFX ============

# ธนู: pluck เรปา + whoosh
function Sfx-Arrow {
    $s = Mix @((ADS (Sq 2200 1300 0.5 0.5) 0.001 0.01 0.9), (ADS (Noise 900 0.5) 0.001 0.03 0.9))
    $down = New-Object 'double[]' 1400
    for ($i = 0; $i -lt 1400; $i++) { $down[$i] += ([Math]::Exp(-6.0 * $i / 1400.0)) * 0.25 * [Math]::Sin(2 * [Math]::PI * (600 - 300 * $i / 1400.0) * ($i / $sr)) }
    return (Mix @($s, $down))
}
# ปืนใหญ่: กระหน่ำต่ำ + แหลม souff
function Sfx-Cannon {
    $n = [int]($sr * 0.5)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 240.0 * [Math]::Exp(-18.0 * $t) + 50.0
        $s[$i] += [Math]::Sin(2 * [Math]::PI * $f * $t) * (1.0 - 3.0 * $t) * 0.9
    }
    $nz = Noise ([int]($sr * 0.25)) 0.55
    ADS $nz 0.001 0.09 0.88 | Out-Null
    return (Mix @($s, $nz))
}
# เวท: ชิมเมอร์ขึ้นสูง
function Sfx-Mage {
    $n = [int]($sr * 0.45)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 500.0 + 2600.0 * ($t / 0.45)
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.5 * (1.0 - 0.85 * ($t / 0.45))
    }
    $sh = Noise ([int]($sr * 0.2)) 0.12
    ADS $sh 0.002 0.05 0.85 | Out-Null
    return (Mix @($s, $sh))
}
# ระเบิด: กระจุกดุ้นขึ้น + แตกตื้นเนิน
function Sfx-Explosion {
    $n = [int]($sr * 0.6)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 180.0 * [Math]::Exp(-9.0 * $t)
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * (1.0 - 1.6 * $t) * 0.85
    }
    $nz = Noise ([int]($sr * 0.5)) 0.75
    ADS $nz 0.001 0.15 0.9 | Out-Null
    return (Mix @($s, $nz))
}
# มอนตาย: ป๊อป + hat สั้น
function Sfx-Die {
    return (Mix @(
        (ADS (Sq 350 900 0.5 0.5) 0.002 0.02 0.85),
        (ADS (Noise 500 0.35) 0.001 0.04 0.9)
    ))
}
# เหรียญฆ่า +: สำรวงคลาสซิก
function Sfx-Coin {
    return (Mix @((ADS (Sq 988 1300 0.4 0.5) 0.001 0.01 0.55), (ADS (Sq 1319 2500 0.5 0.5) 0.001 0.01 0.65)))
}
# รั่ว (โคลาสสิล): อีอหมาย + แจ้งเตือนอ่อนสั้น
function Sfx-Leak {
    return (Mix @(
        (ADS (Sq 240 2200 0.55 0.3) 0.005 0.05 0.4),
        (ADS (Sq 170 2200 0.45 0.3) 0.005 0.05 0.45)
    ))
}
# คลื่นบุก: แตรล่าง 2 ย้ายขึ้น
function Sfx-Horn {
    return @(ADS (Sq (Freq 45) 4000 0.4 0.5) 0.01 0.08 0.35) +
           @(ADS (Sq (Freq 52) 5000 0.4 0.5) 0.01 0.08 0.4)
}
# สร้างป้อม: เง้า่าผล่า
function Sfx-Build {
    return (Mix @(
        (ADS (Sq 150 900 0.55 0.5) 0.002 0.02 0.8),
        (ADS (Noise 400 0.3) 0.001 0.05 0.9)
    ))
}
# ขายป้อม: เชา-ชิง 2 ตัว
function Sfx-Sell {
    return (Mix @(
        (ADS (Sq 1100 1000 0.4 0.4) 0.002 0.02 0.6),
        (ADS (Sq 1660 1200 0.4 0.4) 0.002 0.02 0.6)
    ))
}
# ฮีนฟันด้วย: วูบไปด้่า
function Sfx-Slash {
    return (Mix @((ADS (Noise 1300 0.5) 0.002 0.02 0.9), (ADS (Sq 1900 700 0.3 0.25) 0.001 0.01 0.9)))
}
# กีคภายหลังป้อน
function Sfx-Click {
    return (ADS (Sq 1600 700 0.3 0.5) 0.001 0.01 0.9)
}
# ชนะ: ไต่ 4 โน้ตคอม
function Sfx-Win {
    return @(ADS (Sq 523 3000 0.4 0.45) 0.005 0.05 0.35) +
           @(ADS (Sq 659 3000 0.4 0.45) 0.005 0.05 0.35) +
           @(ADS (Sq 784 3000 0.4 0.45) 0.005 0.05 0.35) +
           @(ADS (Sq 1047 5500 0.45 0.45) 0.005 0.08 0.4)
}
# แพ้: ไหลลง
function Sfx-Lose {
    return @(ADS (Sq 392 3600 0.4 0.4) 0.005 0.05 0.35) +
           @(ADS (Sq 311 3600 0.4 0.4) 0.005 0.05 0.35) +
           @(ADS (Sq 233 5500 0.45 0.4) 0.005 0.08 0.4)
}

Save-Wav (Join-Path $outDir 'music_prep.wav')  (Build-PrepMusic) $true
Save-Wav (Join-Path $outDir 'music_wave.wav')  (Build-WaveMusic) $true
Save-Wav (Join-Path $outDir 'sfx_arrow.wav')     (Sfx-Arrow) $true
Save-Wav (Join-Path $outDir 'sfx_cannon.wav')    (Sfx-Cannon) $true
Save-Wav (Join-Path $outDir 'sfx_mage.wav')    (Sfx-Mage) $true
Save-Wav (Join-Path $outDir 'sfx_explosion.wav') (Sfx-Explosion) $true
Save-Wav (Join-Path $outDir 'sfx_die.wav')     (Sfx-Die) $true
Save-Wav (Join-Path $outDir 'sfx_coin.wav')      (Sfx-Coin) $true
Save-Wav (Join-Path $outDir 'sfx_leak.wav')      (Sfx-Leak) $true
Save-Wav (Join-Path $outDir 'sfx_horn.wav')      (Sfx-Horn) $true
Save-Wav (Join-Path $outDir 'sfx_build.wav')     (Sfx-Build) $true
Save-Wav (Join-Path $outDir 'sfx_sell.wav')     (Sfx-Sell) $true
Save-Wav (Join-Path $outDir 'sfx_slash.wav')    (Sfx-Slash) $true
Save-Wav (Join-Path $outDir 'sfx_click.wav')    (Sfx-Click) $true
Save-Wav (Join-Path $outDir 'sfx_win.wav')      (Sfx-Win) $true
Save-Wav (Join-Path $outDir 'sfx_lose.wav')     (Sfx-Lose) $true
Write-Host "เสร็จสิ้น — เสียงครบทั้งเกม 2"
