# วัดขอบเท้า (แถวพิกเซลโปร่งล่างสุดที่มีเนื้อภาพ) ของกบ/กิ้งก่า จาก sheet เฟรมแรก
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
foreach ($name in @("frog_sheet", "lizard_sheet")) {
  $b = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\$name.png")
  $maxY = -1; $minY = 64
  for ($y = 0; $y -lt 64; $y++) {
    for ($x = 0; $x -lt 64; $x++) {
      if ($b.GetPixel($x, $y).A -gt 40) {
        if ($y -gt $maxY) { $maxY = $y }
        if ($y -lt $minY) { $minY = $y }
        break
      }
    }
  }
  Write-Output ("{0}: body rows {1}..{2} -> feet_y = {3}" -f $name, $minY, $maxY, (64 - $maxY))
  $b.Dispose()
}
