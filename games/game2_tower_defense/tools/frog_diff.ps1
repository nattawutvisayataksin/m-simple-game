# เทียบ f0..f8 กับ frog.png (เฟรมอ้างอิงจะต่างน้อยสุด)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$ref = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\frog.png")
$dir = "C:\m-simple-game\tower-defend\assets\art\gen\frog_frames"
for ($i = 0; $i -lt 9; $i++) {
  $f = [System.Drawing.Bitmap]::FromFile("$dir\f$i.png")
  $diff = 0
  for ($y = 0; $y -lt 64; $y++) {
    for ($x = 0; $x -lt 64; $x++) {
      $a = $ref.GetPixel($x, $y); $b = $f.GetPixel($x, $y)
      if ([math]::Abs($a.R - $b.R) + [math]::Abs($a.G - $b.G) + [math]::Abs($a.B - $b.B) -gt 40) { $diff++ }
    }
  }
  Write-Output ("f$i diff pixels = $diff")
  $f.Dispose()
}
$ref.Dispose()
