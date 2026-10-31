# สุ่มสีหญ้าขอบรอยต่อจาก world_raw.png (master edge raw y 210-215 vs panel edge raw y 216-221)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\raw\world_raw.png")
$xs = @(30, 60, 100, 150, 200, 240, 310, 350)
foreach ($x in $xs) {
  foreach ($y in @(210, 213, 215, 216, 218, 221)) {
    $c = $src.GetPixel($x, $y)
    Write-Output ("({0},{1}) R{2} G{3} B{4}" -f $x, $y, $c.R, $c.G, $c.B)
  }
  Write-Output "---"
}
$src.Dispose()
