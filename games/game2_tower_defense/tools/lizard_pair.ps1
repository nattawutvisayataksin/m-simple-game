# pairwise diff เฟรมกิ้งก่า (หาเฟรม ref ที่ซ้ำ/ใกล้ต้นฉบับมากสุด)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\lizard_frames"
$imgs = @{}
for ($i = 0; $i -lt 9; $i++) { $imgs[$i] = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png") }
function DiffPair($a, $b) {
  $d = 0
  for ($y = 0; $y -lt 64; $y++) {
    for ($x = 0; $x -lt 64; $x++) {
      $p = $imgs[$a].GetPixel($x, $y); $q = $imgs[$b].GetPixel($x, $y)
      if ([math]::Abs($p.R - $q.R) + [math]::Abs($p.G - $q.G) + [math]::Abs($p.B - $q.B) -gt 40) { $d++ }
    }
  }
  return $d
}
Write-Output "f0 vs f8 = $(DiffPair 0 8)"
Write-Output "f0 vs f1 = $(DiffPair 0 1)"
Write-Output "f7 vs f8 = $(DiffPair 7 8)"
Write-Output "f0 vs f7 = $(DiffPair 0 7)"
Write-Output "f0 vs f6 = $(DiffPair 0 6)"
Write-Output "f2 vs f7 = $(DiffPair 2 7)"
foreach ($v in $imgs.Values) { $v.Dispose() }
