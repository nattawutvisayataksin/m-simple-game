# สคริปต์สร้างไฟล์เสียง .wav สำหรับเกม โดยสังเคราะห์คลื่น sine ล้วน ๆ
# ใช้งาน:  เปิด PowerShell ที่โฟลเดอร์โปรเจกต์แล้วรัน  pwsh -File tools/generate_sfx.ps1
# ผลลัพธ์: assets/audio/pickup.wav, win.wav, lose.wav

$ErrorActionPreference = 'Stop'
$outDir = Join-Path $PSScriptRoot '..\assets\audio'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$sr = 22050  # sample rate (Hz)

# เขียนไฟล์ .wav mono 16-bit PCM
function Save-Wav([string]$file, [object[]]$samples) {
    $dataLen = $samples.Length * 2
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    $ascii = [System.Text.Encoding]::ASCII
    $bw.Write($ascii.GetBytes("RIFF"))
    $bw.Write([int]($dataLen + 36))
    $bw.Write($ascii.GetBytes("WAVE"))
    $bw.Write($ascii.GetBytes("fmt "))
    $bw.Write([int]16)          # ขนาดของ fmt chunk
    $bw.Write([Int16]1)         # PCM
    $bw.Write([Int16]1)         # mono
    $bw.Write([int]$sr)
    $bw.Write([int]($sr * 2))   # byte rate
    $bw.Write([Int16]2)         # block align
    $bw.Write([Int16]16)        # bits per sample
    $bw.Write($ascii.GetBytes("data"))
    $bw.Write([int]$dataLen)

    foreach ($v in $samples) { $bw.Write([Int16][Math]::Round($v)) }

    $bw.Flush()
    [System.IO.File]::WriteAllBytes($file, $ms.ToArray())
    Write-Host "สร้าง $file ($($samples.Length) samples)"
}

# สร้างโน้ต sine 1 เสียง พร้อม fade-out เบา ๆ ตอนท้าย
function Note([double]$freq, [double]$dur) {
    $n = [int]($sr * $dur)
    $s = New-Object 'object[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $env = 1.0 - ($i / $n) * 0.8   # เสียงค่อย ๆ เบาลง
        $s[$i] = [Math]::Sin(2 * [Math]::PI * $freq * $t) * 9000 * $env
    }
    return $s
}

# ต่อโน้ตเข้าด้วยกัน
function Chain {
    $all = @()
    foreach ($note in $args) { $all += $note }
    return $all
}

# เสียงเก็บเหรียญ: โน้ตขึ้น 2 จังหวะแบบคลาสสิก
Save-Wav (Join-Path $outDir 'pickup.wav') (Chain (Note 988 0.09) (Note 1319 0.14))

# เสียงชนะ: อัคคอร์ดไต่ขึ้น
Save-Wav (Join-Path $outDir 'win.wav') (Chain (Note 523 0.12) (Note 659 0.12) (Note 784 0.12) (Note 1047 0.25))

# เสียงแพ้: โน้ตไหลลง
Save-Wav (Join-Path $outDir 'lose.wav') (Chain (Note 330 0.18) (Note 262 0.18) (Note 196 0.30))

# เสียงกระโดด: โน้ตขึ้นสั้น
Save-Wav (Join-Path $outDir 'jump.wav') (Chain (Note 660 0.06) (Note 880 0.08))

# เสียงลงพื้น: โน้ตต่ำสั้น
Save-Wav (Join-Path $outDir 'land.wav') (Chain (Note 220 0.07))

# เสียงเหยียบศัตรู: โน้ตสูง 2 จังหวะ
Save-Wav (Join-Path $outDir 'stomp.wav') (Chain (Note 1047 0.06) (Note 1319 0.10))

Write-Host "เสร็จสิ้น"
