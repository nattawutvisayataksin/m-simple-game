$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
foreach ($n in @("RollingFields .PNG", "SunnyRanch.PNG", "MiningSite.PNG", "HillyVillage.PNG")) {
  $b = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\download_asset_opengameart\randomcc0bgsbyzanin\$n")
  Write-Output ("{0} -> {1}x{2}" -f $n, $b.Width, $b.Height)
  $b.Dispose()
}
