# สคริปต์สร้างเพลงประกอบ chiptune (loop) สำหรับเกม — สังเคราะห์คลื่นสี่เหลี่ยมล้วน ๆ
# ต่อแนวจาก generate_sfx.ps1 (ฟรี ไม่ต้องใช้ API key / ไม่กินโควตา gen)
# ใช้งาน:  pwsh -File tools/generate_music.ps1
# ผลลัพธ์: assets/audio/music.wav (loop ได้แน่นเนื่อง: เนื้อเพลงลงท้ายพอดีขอบลูป)
#
# สูตรเพลง: 8 บาร์ / 140 BPM — C, G, A-m, F (บลูสแคลชสนุกเหมาะเกมเก็บเหรียญ)
#   lead   = square wave สูง (arpeggio 8th note ต่อบาร์)
#   bass   = square wave เบา ต่ำ (root ตามจังหวะ quarter เข้าเทลง 1 ที = root+7)

$ErrorActionPreference = 'Stop'
$outFile = Join-Path $PSScriptRoot '..\assets\audio\music.wav'

$samples = @()
# จำนวน samples ต่อหน่วยจังหวะ (ต้องเป็นจำนวนเต็ม = ลูปเนียน)
#   beat = 60/140 = 0.42857 s → @ 22050 Hz = 9450 samples | 8th note = 4725
$sr = 22050
$beat = 9450
$eighth = 4725

# ตารางคอร์ด (บาร์ที่ 1-8) — [root, ใหญ่? major(4)/minor(3), ]
# (root freq ของ octave 3 เทียบ A3 = 220 Hz)
$bars = @(
    @{ root = 130.81; third = 4 },  # C
    @{ root = 196.00; third = 4 },  # G
    @{ root = 220.00; third = 3 },  # A-m
    @{ root = 174.61; third = 4 },  # F
    @{ root = 130.81; third = 4 },  # C
    @{ root = 196.00; third = 4 },  # G
    @{ root = 220.00; third = 3 },  # A-m
    @{ root = 174.61; third = 4 }   # F
)

# สร้างโน้ต square wave 1 เสียง: decay นุ่ม (กัน click: ramp แรก + release ท้าย)
function Note-Sq([double]$freq, [int]$n, [double]$vol) {
    $s = New-Object 'object[]' $n
    for ($i = 0; $i -lt $n; $i++) {
        $t = $i / $sr
        $progress = $i / $n
        # ซองเสียง: decay ตามเวลา + ramp/release สั้น ๆ ต้นจนของโน้ต
        $env = (1.0 - 0.25 * $progress)
        if ($i -lt 96) { $env *= $i / 96.0 }
        if ($i -gt ($n - 128)) { $env *= ($n - $i) / 128.0 }
        $raw = [Math]::Sin(2 * [Math]::PI * $freq * $t)
        $square = if ($raw -ge 0.0) { 1.0 } else { -1.0 }
        $s[$i] = $square * $vol * $env
    }
    return $s
}

# Track
$lead = New-Object 'object[]' ($beat * 32)
$bass = New-Object 'object[]' ($beat * 32)

# บันทึก + เล่น
$leadOffset = 0
$bassOffset = 0
foreach ($bar in $bars) {
    $root = $bar.root
    $minorThird = $bar.third
    # lead: octave ขึ้น 1 + arpeggio 8 โน้ต 8th
    $base = $root * 2.0
    # ลำดับตำแหน่งคอร์ด: r, r+third, r+7, r+12 (8ve) — ไล่ขึ้นลงให้เต่งตึง
    $pattern = @(
        0, $minorThird, 7, 12,
        $minorThird, 7, 12, $minorThird
    )
    for ($step = 0; $step -lt 8; $step++) {
        $freq = $base * [Math]::Pow(2.0, $pattern[$step] / 12.0)
        $note = Note-Sq $freq $eighth 1500
        for ($i = 0; $i -lt $eighth; $i++) { $lead[$leadOffset + $i] += $note[$i] }
        $leadOffset += $eighth
    }
    # bass: 4 โน้ต quarter (root, root, root-โอ๊กท์, root) เสียงเบาลง
    $bassSeq = @(
        $root, $root, ($root / 2.0), $root
    )
    foreach ($freq in $bassSeq) {
        $note = Note-Sq $freq $beat 1400
        for ($i = 0; $i -lt $beat; $i++) { $bass[$bassOffset + $i] += $note[$i] }
        $bassOffset += $beat
    }
}

# มิกซ์ lead + bass (หางเสียงหนึบ) — ปรับ gain กัน clipped
$totalLen = $beat * 32
$out = New-Object 'object[]' $totalLen
for ($i = 0; $i -lt $totalLen; $i++) {
    $out[$i] = [Math]::Max(-32000, [Math]::Min(32000, ($lead[$i] + 0.9 * $bass[$i])))
}

# เขียน WAV mono 16-bit (รูปแบบเดียวกับ generate_sfx.ps1)
$dataLen = $out.Length * 2
$ms = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($ms)
$ascii = [System.Text.Encoding]::ASCII
$bw.Write($ascii.GetBytes("RIFF"))
$bw.Write([int]($dataLen + 36))
$bw.Write($ascii.GetBytes("WAVE"))
$bw.Write($ascii.GetBytes("fmt "))
$bw.Write([int]16)
$bw.Write([Int16]1)    # PCM
$bw.Write([Int16]1)    # mono
$bw.Write([int]$sr)
$bw.Write([int]($sr * 2))
$bw.Write([Int16]2)
$bw.Write([Int16]16)
$bw.Write($ascii.GetBytes("data"))
$bw.Write([int]$dataLen)
foreach ($v in $out) { $bw.Write([Int16][Math]::Round($v)) }
$bw.Flush()
[System.IO.File]::WriteAllBytes($outFile, $ms.ToArray())
Write-Host ("Done: $outFile ({0} samples, {1:N1} sec - seamless loop)" -f $out.Length, ($out.Length / $sr))
