# สร้างไฟล์เสียงทั้งหมดของเกม 4 (แท็กซี่คู่ฟ้า) — สังเคราะห์สัญญาณล้วน ฟรี ไม่กินโควตา gen
# ใช้: pwsh -File tools/generate_audio.ps1
# ผลลัพธ์: assets/audio/*.wav
#   music_day.wav   = เพลงขับเมือง (สนุก funky วงลูปได้)
#   + SFX: pickup (ลูกค้าขึ้นรถ), drop (เงินเข้า/ชา-ชิง), fail (หมดเวลาทริป),
#          squeal (ยางดริฟท์), whoosh (เฉียดรถจราจร), boing (แรมพ์),
#          thud (ชนโกเลม), squish (สไลม์), horn (ฮอร์นแท็กซี่),
#          click (เมนู), win (จอบสำเร็จ), lose (จอบไม่ค่อยสวย)

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

# --- สัญญาณพื้นฐาน (เดียวกับ generate_td_audio.ps1 เกม 2) ---
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
function Noise([int]$n, [double]$vol, [int]$seed = 20261) {
    $s = New-Object 'double[]' $n
    $rnd = New-Object System.Random $seed
    for ($i = 0; $i -lt $n; $i++) { $s[$i] = ($rnd.NextDouble() * 2.0 - 1.0) * $vol }
    return $s
}
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
        if ($j -lt $into.Length -and $j -ge 0) { $into[$j] += $s[$i] }
    }
}
function Freq([double]$midi) { return 440.0 * [Math]::Pow(2.0, ($midi - 69.0) / 12.0) }

# ============ เพลงขับเมือง (funky) — 124 BPM, 8 บาร์, C–Am–F–G ============
function Build-DayMusic {
    $bpm = 124.0
    $beat = [int][Math]::Round($sr * 60.0 / $bpm)
    $bar = $beat * 4
    $total = $bar * 8
    $mix = New-Object 'double[]' $total
    $prog = 48, 45, 41, 43, 48, 45, 41, 43    # C Am F G สองรอบ
    for ($b = 0; $b -lt 8; $b++) {
        $r = $prog[$b]
        # funky bass: 8th ลุกเด้ง root / root+7
        for ($k = 0; $k -lt 8; $k++) {
            $n = [int]($beat / 2)
            $m = $r - 12
            if ($k % 4 -eq 2) { $m = $r }         # ซ้อนขึ้นออคเตฟปล้ำ
            elseif ($k % 2 -eq 1) { $m = $r - 5 }  # ก้าวไป 2 องศา (เอวปนยาว)
            At (ADS (Sq (Freq $m) $n 0.20 0.55) 0.003 0.01 0.35) $mix ($b * $bar + [int]($k * $n))
        }
        # pad บาง ๆ ให้เมืองนุ่ม
        At (ADS (Tri (Freq ($r + 12)) $bar 0.06) 0.08 0.1 0.25) $mix ($b * $bar)
        # arpeggio 8th — เมาม้าสุดวาลๆ
        $arpIdx = @((12), (16), (14), (16), (19), (16), (14), (12))
        for ($k = 0; $k -lt 8; $k++) {
            $n = [int]($beat / 2)
            At (ADS (Sq (Freq ($r + $arpIdx[$k])) $n 0.065 0.4) 0.004 0.02 0.5) $mix ($b * $bar + [int]($k * $n))
        }
        # hat ทุก 8th เบา (backbeat หนักหน่องช่วง 2,4)
        for ($q = 0; $q -lt 4; $q++) {
            $v = 0.05; if ($q % 2 -eq 1) { $v = 0.11 }
            $sn = Noise ([int]($beat / 2)) $v 20261
            ADS $sn 0.001 0.02 0.9 | Out-Null
            At $sn $mix ($b * $bar + [int]($q * $beat))
        }
        # kick 4-on-floor: ต่ำซ้อนยาง
        for ($q = 0; $q -lt 4; $q++) {
            $n = [int]($beat / 4)
            $s = New-Object 'double[]' $n
            for ($i = 0; $i -lt $n; $i++) {
                $t = $i / $sr
                $f = 105.0 * [Math]::Exp(-20.0 * $t) + 40.0
                $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.32 * (1.0 - $i / $n)
            }
            At $s $mix ($b * $bar + [int]($q * $beat))
        }
    }
    return $mix
}

# ============ เพลงราตรี (chill) — 88 BPM, 4 บาร์, Am–F–C–G ============
function Build-NightMusic {
    $bpm = 88.0
    $beat = [int][Math]::Round($sr * 60.0 / $bpm)
    $bar = $beat * 4
    $total = $bar * 4
    $mix = New-Object 'double[]' $total
    $prog = 45, 41, 48, 43    # Am F C G
    for ($b = 0; $b -lt 4; $b++) {
        $r = $prog[$b]
        # bass sine นุ่ม: 2 โน้ตต่อบาร์ (root เกาะ 2 บีทต่อโน้ต)
        for ($k = 0; $k -lt 2; $k++) {
            $n = $beat * 2
            $s = New-Object 'double[]' $n
            for ($i = 0; $i -lt $n; $i++) {
                $t = $i / $sr
                $s[$i] = [Math]::Sin(2 * [Math]::PI * (Freq ($r - 12)) * $t) * 0.22
            }
            At (ADS $s 0.02 0.08 0.3) $mix ($b * $bar + $k * $n)
        }
        # pad ยามดึก: คอร์ดบางค้างทั้งบาร์ (r+5 คู่ห้า + r+12 ออคเตฟ)
        At (ADS (Tri (Freq ($r + 5)) $bar 0.05) 0.15 0.2 0.2) $mix ($b * $bar)
        At (ADS (Tri (Freq ($r + 12)) $bar 0.04) 0.15 0.2 0.2) $mix ($b * $bar)
        # arp สโลว์ 4 ต่อบาร์ (1 บีทต่อโน้ต)
        $arpIdx = @(12, 16, 19, 16)
        for ($k = 0; $k -lt 4; $k++) {
            At (ADS (Sq (Freq ($r + $arpIdx[$k])) $beat 0.05 0.45) 0.01 0.05 0.5) $mix ($b * $bar + $k * $beat)
        }
        # hat เบา เฉพาะจังหวะ 3
        $sn = Noise ([int]($beat / 4)) 0.07 20262
        ADS $sn 0.001 0.01 0.9 | Out-Null
        At $sn $mix ($b * $bar + 2 * $beat)
        # kick นุ่ม 2 ต่อบาร์ (1 และ 3)
        for ($k = 0; $k -lt 2; $k++) {
            $n2 = [int]($beat / 4)
            $s2 = New-Object 'double[]' $n2
            for ($i = 0; $i -lt $n2; $i++) {
                $t = $i / $sr
                $f = 90.0 * [Math]::Exp(-16.0 * $t) + 38.0
                $s2[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.26 * (1.0 - $i / $n2)
            }
            At $s2 $mix ($b * $bar + $k * 2 * $beat)
        }
    }
    return $mix
}

# ============ SFX ============

# จิ้งหรีดยามดึก: 4 ชิรปใน ~2 วิ แต่ละชิรป 3 พัลส์เสียงสูงบาง ๆ
function Sfx-Cricket {
    $n = [int]($sr * 2.0)
    $m = New-Object 'double[]' $n
    $rnd = New-Object System.Random 20263
    for ($c = 0; $c -lt 4; $c++) {
        $start = [int]($c * 0.5 * $sr)
        for ($p = 0; $p -lt 3; $p++) {
            $pn = [int]($sr * 0.03)          # พัลส์ 30ms
            $f = 4200.0 + ($rnd.NextDouble() * 2.0 - 1.0) * 300.0
            $off = $start + [int]($p * $sr * 0.055)
            $s = New-Object 'double[]' $pn
            for ($i = 0; $i -lt $pn; $i++) {
                $t = $i / $sr
                $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * [Math]::Exp(-60.0 * $t) * 0.3
            }
            At $s $m $off
        }
    }
    return $m
}

# ปิ๊งสอน (กะฝึกผ่านขั้น): 2 โน้ตขึ้นสั้น ๆ ให้รู้ว่าผ่านหรือยัง
function Sfx-TutPing {
    $n = [int]($sr * 0.28)
    $m = New-Object 'double[]' $n
    At (ADS (Sq 988 500 0.4 0.5) 0.002 0.03 0.5) $m 0
    At (ADS (Sq 1319 700 0.45 0.5) 0.002 0.04 0.5) $m 120
    return $m
}

# ลูกค้าขึ้นรถ: เหนี่ยวเขา 2 โน้ต (E5 → A5) ต้อนรับ
function Sfx-PickupReal {
    $n = [int]($sr * 0.4)
    $m = New-Object 'double[]' $n
    At (ADS (Sq (Freq 76) 700 0.5 0.35) 0.004 0.05 0.5) $m 0
    At (ADS (Sq (Freq 81) 1500 0.5 0.35) 0.004 0.05 0.55) $m 700
    return $m
}
# เงินเข้า: ชา-ชิง 2 ครั้ง (คอยล์แรง + เบลล์สูง)
function Sfx-Drop {
    $n = [int]($sr * 0.55)
    $m = New-Object 'double[]' $n
    At (ADS (Sq 988 700 0.4 0.5) 0.001 0.02 0.55) $m 0
    At (ADS (Sq 1319 1400 0.5 0.5) 0.001 0.02 0.65) $m 400
    At (ADS (Sq (Freq 93) 1800 0.35 0.4) 0.001 0.03 0.5) $m 350
    return $m
}
# หมดเวลาทริป: โน้ตร่วง 2 ตัว + เสียงถอนใจระเบิดสั้น
function Sfx-Fail {
    $n = [int]($sr * 0.5)
    $m = New-Object 'double[]' $n
    At (ADS (Sq (Freq 70) 700 0.5 0.4) 0.005 0.05 0.45) $m 0
    At (ADS (Sq (Freq 65) 1200 0.5 0.4) 0.005 0.06 0.5) $m 700
    At (ADS (Noise 500 0.2) 0.002 0.05 0.85) $m 1200
    return $m
}
# ยางครีตหรือเหนี่ยวเวล (drift): สแควย์ฟิลปีด FM พันยางแหลมใต้
function Sfx-Squeal {
    $n = [int]($sr * 0.35)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 780.0 + 90.0 * [Math]::Sin(2 * [Math]::PI * 11.0 * $t)
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.4
    }
    $nz = Noise ([int]($sr * 0.08)) 0.12
    ADS $nz 0.001 0.03 0.9 | Out-Null
    return (Mix @( (ADS $s 0.01 0.05 0.3), $nz ))
}
# เฉียดรถจราจร (whoosh): นวดเสียงแหลมตาแปรเดียวตกลง
function Sfx-Whoosh {
    $n = [int]($sr * 0.3)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 900.0 + 1500.0 * ($t / 0.3)
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * [Math]::Exp(-4.0 * ($t / 0.3)) * 0.35
    }
    $nz = Noise ([int]($sr * 0.28)) 0.2
    for ($i = 0; $i -lt $nz.Length; $i++) { $nz[$i] *= [Math]::Exp(-5.0 * ($i / $nz.Length)) }
    return (Mix @($s, $nz))
}
# แรมพ์ (boing): ไจรออสโคป สไลด์ขึ้นสูง เก็บหลังนุ่ม
function Sfx-Boing {
    $n = [int]($sr * 0.35)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 180.0 + 620.0 * ($t / 0.35)
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * 0.5 * (1.0 - 0.7 * ($t / 0.35))
    }
    return (ADS $s 0.005 0.05 0.35)
}
# ชนโกเลม (thud หนัก): ดีบเบสโφοรปา + กระแทกตึง
function Sfx-Thud {
    $n = [int]($sr * 0.5)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 140.0 * [Math]::Exp(-14.0 * $t) + 45.0
        $s[$i] += [Math]::Sin(2 * [Math]::PI * $f * $t) * (1.0 - 2.0 * $t) * 0.9
    }
    $nz = Noise ([int]($sr * 0.3)) 0.5
    ADS $nz 0.001 0.09 0.88 | Out-Null
    return (Mix @($s, $nz))
}
# สไลม์ (squish): ป๊อปเปียดเสียงสะบั้งลม + ขยำ
function Sfx-Squish {
    $n = [int]($sr * 0.3)
    $s = New-Object 'double[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $f = 420.0 * [Math]::Exp(-10.0 * $t) + 90.0
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $f * $t) * (1.0 - 2.6 * $t) * 0.6
    }
    $nz = Noise ([int]($sr * 0.25)) 0.25
    ADS $nz 0.002 0.07 0.9 | Out-Null
    return (Mix @($s, $nz))
}
# ฮอร์นแท็กซี่: โทนลสเต็ป 2 จังหวะ (ที-ที-ทู เมือง)
function Sfx-Horn {
    $n = [int]($sr * 0.55)
    $m = New-Object 'double[]' $n
    $t1 = [int]($sr * 0.26)
    At (Mix @((Sq 440 $t1 0.3 0.5), (Sq 554 $t1 0.25 0.5))) $m 0
    $t2 = [int]($sr * 0.22)
    $off2 = [int]($sr * 0.3)
    At (Mix @((Sq 440 $t2 0.3 0.5), (Sq 554 $t2 0.25 0.5))) $m $off2
    $out = ADS $m 0.01 0.06 0.2
    return $out
}
# กดปุ่มเมนู
function Sfx-Click {
    return (ADS (Sq 1600 700 0.3 0.5) 0.001 0.01 0.9)
}
# จอบ (shram สวย): ไต่ 4 โน้ตคอม
function Sfx-Win {
    $n = [int]($sr * 1.4)
    $m = New-Object 'double[]' $n
    $notes = @(72, 76, 79, 84)
    for ($i = 0; $i -lt 4; $i++) {
        $len = 2100; if ($i -eq 3) { $len = 4200 }
        At (ADS (Sq (Freq $notes[$i]) $len 0.4 0.4) 0.005 0.06 0.3) $m ([int]($i * 2100))
    }
    return $m
}
# จอบที่โดนตัด (อารมณร้อน): หล่น
function Sfx-Lose {
    $n = [int]($sr * 1.4)
    $m = New-Object 'double[]' $n
    $notes = @(67, 60, 55)
    for ($i = 0; $i -lt 3; $i++) {
        $len = 2700; if ($i -eq 2) { $len = 4500 }
        At (ADS (Sq (Freq $notes[$i]) $len 0.4 0.4) 0.005 0.06 0.3) $m ([int]($i * 2400))
    }
    return $m
}

Save-Wav (Join-Path $outDir 'music_day.wav') (Build-DayMusic) $true
Save-Wav (Join-Path $outDir 'sfx_pickup.wav') (Sfx-PickupReal) $true
Save-Wav (Join-Path $outDir 'sfx_drop.wav')   (Sfx-Drop) $true
Save-Wav (Join-Path $outDir 'sfx_fail.wav')   (Sfx-Fail) $true
Save-Wav (Join-Path $outDir 'sfx_squeal.wav') (Sfx-Squeal) $true
Save-Wav (Join-Path $outDir 'sfx_whoosh.wav') (Sfx-Whoosh) $true
Save-Wav (Join-Path $outDir 'sfx_boing.wav')  (Sfx-Boing) $true
Save-Wav (Join-Path $outDir 'sfx_thud.wav')   (Sfx-Thud) $true
Save-Wav (Join-Path $outDir 'sfx_squish.wav') (Sfx-Squish) $true
Save-Wav (Join-Path $outDir 'sfx_horn.wav')   (Sfx-Horn) $true
Save-Wav (Join-Path $outDir 'sfx_click.wav')  (Sfx-Click) $true
Save-Wav (Join-Path $outDir 'sfx_win.wav')    (Sfx-Win) $true
Save-Wav (Join-Path $outDir 'sfx_lose.wav')   (Sfx-Lose) $true
Save-Wav (Join-Path $outDir 'music_night.wav') (Build-NightMusic) $true
Save-Wav (Join-Path $outDir 'sfx_cricket.wav') (Sfx-Cricket) $true
Save-Wav (Join-Path $outDir 'sfx_tut.wav')     (Sfx-TutPing) $true
Write-Host "เสร็จสิ้น — เสียงครบทั้งเกม 4"
