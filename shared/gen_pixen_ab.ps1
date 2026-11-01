# gen_pixen_ab.ps1 - สร้างภาพ pixel-art ผ่าน Pixellab REST v2 ด้วย key A หรือ B (ใช้โบนัสรายวันของ key ที่ plan หมด)
# ใช้: powershell -File shared\gen_pixen_ab.ps1 -KeyName pixellab-a -OutFile path.png -Description "..." [-W 32 -H 32] [-View "side"] [-DownscaleTo 0]
param(
	[Parameter(Mandatory=$true)][string]$KeyName,   # pixellab-a | pixellab-b
	[Parameter(Mandatory=$true)][string]$OutFile,
	[Parameter(Mandatory=$true)][string]$Description,
	[int]$W = 32,
	[int]$H = 32,
	[string]$View,
	[string]$Detail = "medium detail",
	[string]$Outline = "single color black outline",
	[switch]$HasBackground,
	[int]$DownscaleTo = 0,
	[string]$Direction
)
$ErrorActionPreference = 'Stop'
$envName = 'PIXELLAB_API_KEY_' + ($KeyName.Split('-')[1].ToUpper())
$key = [Environment]::GetEnvironmentVariable($envName)
if (-not $key) {
	$cfg = Get-Content "C:\Users\Administrator\.config\opencode\opencode.json" -Raw | ConvertFrom-Json
	$key = $cfg.mcp.servers.$KeyName.headers.Authorization -replace '^Bearer ',''
}
if (-not $key) { Write-Output "GEN-FAIL: no key for $KeyName"; exit 4 }
$sz = @{ width = $W; height = $H }
$body = @{ description = $Description; image_size = $sz; no_background = (-not $HasBackground) }
if ($Detail) { $body.detail = $Detail }
if ($Outline) { $body.outline = $Outline }
if ($View) { $body.view = $View }
if ($Direction) { $body.direction = $Direction }
$json = $body | ConvertTo-Json -Depth 5
try {
	$r = Invoke-RestMethod -Uri 'https://api.pixellab.ai/v2/create-image-pixen' `
		-Headers @{ Authorization = "Bearer $key" } -Method Post `
		-Body $json -ContentType 'application/json' -TimeoutSec 110
} catch {
	$detail = ''
	try { $detail = $_.ErrorDetails.Message } catch {}
	Write-Output ("GEN-FAIL " + $_.Exception.Message + " :: " + $detail)
	exit 2
}
$img = $r.image
$b64 = $null
if ($img -is [string]) {
	if ($img -match '^data:[^;]+;base64,(.*)$') { $b64 = $Matches[1] }
	elseif ($img -match '^https?://') {
		Invoke-WebRequest -Uri $img -OutFile $OutFile -TimeoutSec 60
	} else { $b64 = $img }
} else {
	foreach ($p in @('base64','b64','data','image','content')) {
		$v = $img.$p
		if ($v -and $v.Length -gt 50) {
			if ($v -match '^data:[^;]+;base64,(.*)$') { $b64 = $Matches[1] } else { $b64 = $v }
			break
		}
	}
}
if (-not $b64 -and -not (Test-Path $OutFile)) {
	Write-Output "GEN-FAIL: no image data in response"
	Write-Output ($r | ConvertTo-Json -Depth 4 | Out-String | ForEach-Object { $_.Substring(0, [Math]::Min(1200, $_.Length)) })
	exit 3
}
if ($b64) { [IO.File]::WriteAllBytes($OutFile, [Convert]::FromBase64String($b64)) }
Add-Type -AssemblyName System.Drawing
$img2 = [System.Drawing.Image]::FromFile((Resolve-Path $OutFile))
$w = $img2.Width; $h = $img2.Height; $img2.Dispose()
if ($DownscaleTo -gt 0 -and $w -ne $DownscaleTo) {
	$src = [System.Drawing.Image]::FromFile((Resolve-Path $OutFile))
	$bmp = New-Object System.Drawing.Bitmap($DownscaleTo, $DownscaleTo)
	$g = [System.Drawing.Graphics]::FromImage($bmp)
	$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
	$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
	$g.DrawImage($src, 0, 0, $DownscaleTo, $DownscaleTo)
	$g.Dispose(); $src.Dispose()
	$bmp.Save((Resolve-Path $OutFile).Path, [System.Drawing.Imaging.ImageFormat]::Png)
	$bmp.Dispose()
	$w = $DownscaleTo; $h = $DownscaleTo
}
$tr = $null
$bmp2 = New-Object System.Drawing.Bitmap((Resolve-Path $OutFile).Path)
$cx = $bmp2.Width / 2; $cy = $bmp2.Height / 2
$tr = @($bmp2.GetPixel(0,0).A, $bmp2.GetPixel($bmp2.Width-1,0).A, $bmp2.GetPixel($bmp2.Width-1,$bmp2.Height-1).A, $bmp2.GetPixel(0,$bmp2.Height-1).A, $bmp2.GetPixel($cx,$cy).A, $bmp2.GetPixel($cx, [int]($bmp2.Height*0.75)).A) -join ','
$bmp2.Dispose()
Write-Output ("GEN-OK[" + $KeyName + "] " + (Split-Path $OutFile -Leaf) + " ${w}x${h} alpha[corn,ctr..]=$tr gens_now=$($r.usage.usd)")
