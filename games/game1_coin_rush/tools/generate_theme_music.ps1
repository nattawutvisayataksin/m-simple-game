# สร้างเพลงรายธีม 3 ชุดของเกม 1 — chiptune square-wave loop (ฟรี ไม่ใช้ gen)
# ต่อแนวจาก generate_music.ps1 แต่ตัวแปรคอร์ด/BPM/ออกเทพต่อธีม:
#   music_sewer.wav  — 90 BPM, D-m/B♭/F/C เชื่องบู้ (บรรยากาศใต้ท่อ)
#   music_sky.wav    — 126 BPM, C/F/G/F สดใสลอยฟ้า (เร็วกว่าเพลงหลัก)
#   music_castle.wav — 105 BPM, A-m/E/F-m/E ครึ่งลังกล (ปราสาทกลางคืน)
# (beat samples = 22050*60/BPM ต้องได้จำนวนเต็ม — 90/126/105 เป็นไปตามนั้น ลูปเนียน)
$ErrorActionPreference = 'Stop'
$ErrorActionPreference = 'Stop'
$sr = 22050
$audioDir = Join-Path $PSScriptRoot '..\assets\audio'

function Note-Sq([double]$freq, [int]$n, [double]$vol, [double]$duty) {
	$s = New-Object 'object[]' $n
	for ($i = 0; $i -lt $n; $i++) {
		$t = $i / $sr
		$progress = $i / $n
		$env = (1.0 - 0.3 * $progress)
		if ($i -lt 96) { $env *= $i / 96.0 }
		if ($i -gt ($n - 128)) { $env *= ($n - $i) / 128.0 }
		$ph = ($freq * $t) % 1.0
		$raw = if ($ph -lt $duty) { 1.0 } else { -1.0 }   # pulse duty-shape แต่งโทนเสียง
		$s[$i] = $raw * $vol * $env
	}
	return $s
}

function Write-Wav([double[]]$mix, [string]$path) {
	$dataLen = $mix.Length * 2
	$ms = New-Object System.IO.MemoryStream
	$bw = New-Object System.IO.BinaryWriter($ms)
	$ascii = [System.Text.Encoding]::ASCII
	$bw.Write($ascii.GetBytes("RIFF"))
	$bw.Write([int]($dataLen + 36))
	$bw.Write($ascii.GetBytes("WAVE"))
	$bw.Write($ascii.GetBytes("fmt "))
	$bw.Write([int]16)
	$bw.Write([Int16]1)
	$bw.Write([Int16]1)
	$bw.Write([int]$sr)
	$bw.Write([int]($sr * 2))
	$bw.Write([Int16]2)
	$bw.Write([Int16]16)
	$bw.Write($ascii.GetBytes("data"))
	$bw.Write([int]$dataLen)
	foreach ($v in $mix) { $bw.Write([Int16][Math]::Round([Math]::Max(-32000.0, [Math]::Min(32000.0, $v)))) }
	$bw.Flush()
	[System.IO.File]::WriteAllBytes($path, $ms.ToArray())
	$bw.Dispose()
	Write-Host ("สร้าง {0} ({1:N1} วิ)" -f (Split-Path $path -Leaf), ($mix.Length / $sr))
}

function Build-Track([string]$outName, [int]$bpm, [object[]]$bars, [object[]]$arp, [double]$patty) {
	# patty: ความลึกออกเทพ lead (1.0 = กลาง, 0.5 = ต่ำหนึบ)
	$barSamples = [int]($sr * 60.0 / $bpm * 4.0)
	$totalLen = $barSamples * $bars.Count
	$lead = New-Object 'double[]' $totalLen
	$bass = New-Object 'double[]' $totalLen
	$leadNoteLen = [int]($barSamples / $arp.Count)
	$bassNoteLen = [int]($barSamples / 4)
	for ($b = 0; $b -lt $bars.Count; $b++) {
		$bar = $bars[$b]
		$off = $b * $barSamples
		# lead: arp ต่อบาร์ (สูง 1 ออกเทพ) — semitone ตามรูปแบบ; 101 = เงียบ
		for ($step = 0; $step -lt $arp.Count; $step++) {
			$semis = $arp[$step]
			if ($semis -ge 100) { continue }
			$freq = $bar.root * 2.0 * $patty * [Math]::Pow(2.0, $semis / 12.0)
			$note = Note-Sq $freq $leadNoteLen 1200 0.3
			$nOff = $off + $step * $leadNoteLen
			for ($i = 0; $i -lt $leadNoteLen; $i++) { $lead[$nOff + $i] += $note[$i] }
		}
		# bass: quarter root / root / ออกเทพต่ำ / root
		$bassSeq = @($bar.root, $bar.root, ($bar.root / 2.0), $bar.root)
		for ($q = 0; $q -lt 4; $q++) {
			$note = Note-Sq $bassSeq[$q] $bassNoteLen 1100 0.5
			$nOff = $off + $q * $bassNoteLen
			for ($i = 0; $i -lt $bassNoteLen; $i++) { $bass[$nOff + $i] += $note[$i] }
		}
	}
	# เหลือมขอบลูป: ผสมเท้า-head 8ms กันคลิกรอบขอบ
	$cross = [int]($sr * 0.008)
	for ($i = 0; $i -lt $cross; $i++) {
		$w = $i / $cross
		$lead[$i] = $lead[$i] * $w + $lead[$totalLen - $cross + $i] * (1.0 - $w)
		$bass[$i] = $bass[$i] * $w + $bass[$totalLen - $cross + $i] * (1.0 - $w)
	}
	$mix = New-Object 'double[]' ($totalLen - $cross)
	for ($i = 0; $i -lt $mix.Length; $i++) { $mix[$i] = ($lead[$i] + 0.9 * $bass[$i]) * 0.85 }
	Write-Wav $mix (Join-Path $audioDir $outName)
}

# --- ธีมท่อระบาย: D-m บูบเชื่อง ---
$sewerBars = @(
	@{ root = 146.83; third = 3 },  # D-m
	@{ root = 116.54; third = 4 },  # B♭
	@{ root = 146.83; third = 3 },  # D-m
	@{ root = 130.81; third = 4 },  # C
	@{ root = 174.61; third = 4 },  # F
	@{ root = 116.54; third = 4 },  # B♭
	@{ root = 146.83; third = 3 },  # D-m
	@{ root = 110.00; third = 3 }   # A-m
)
Build-Track 'music_sewer.wav' 90 $sewerBars @(0, 3, 7, 12, 7, 3, 0, 3) 1.0

# --- ธีมท้องฟ้า: C สดใสเร็ว ---
$skyBars = @(
	@{ root = 261.63; third = 4 },  # C
	@{ root = 349.23; third = 4 },  # F
	@{ root = 392.00; third = 4 },  # G
	@{ root = 349.23; third = 4 },  # F
	@{ root = 261.63; third = 4 },  # C
	@{ root = 293.66; third = 4 },  # D
	@{ root = 392.00; third = 4 },  # G
	@{ root = 349.23; third = 4 }   # F
)
Build-Track 'music_sky.wav' 126 $skyBars @(0, 4, 7, 12, 16, 12, 7, 4) 1.0

# --- ธีมปราสาท: A-m/E/F-m ครึ่งลังกล ---
$castleBars = @(
	@{ root = 220.00; third = 3 },  # A-m
	@{ root = 220.00; third = 3 },  # A-m
	@{ root = 164.81; third = 4 },  # E
	@{ root = 164.81; third = 4 },  # E
	@{ root = 174.61; third = 3 },  # F-m
	@{ root = 174.61; third = 3 },  # F-m
	@{ root = 164.81; third = 4 },  # E
	@{ root = 195.99; third = 3 }   # G-m
)
Build-Track 'music_castle.wav' 105 $castleBars @(0, 101, 3, 7, 12, 7, 3, 101) 0.5
