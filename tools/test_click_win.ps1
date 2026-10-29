# Repro คลิกจริงบนวินโดว์ + diff ภาพ (ต้องรันจอแตะ/มีเดสก์ท็อปจริง)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint data, int extra);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
}
"@

Get-Process | Where-Object { $_.ProcessName -like "*Godot*" } | Stop-Process -Force
Start-Sleep -Seconds 1
$g = "C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
Start-Process -FilePath $g -ArgumentList "--path", "C:\m-simple-game\tower-defend"
Start-Sleep -Seconds 8

$procs = Get-Process | Where-Object { $_.ProcessName -like "*Godot*" -and $_.MainWindowHandle -ne 0 }
if ($procs.Count -eq 0) {
  Get-Process | Where-Object { $_.ProcessName -like "*Godot*" } | ForEach-Object { Write-Output ("proc {0} handle={1}" -f $_.ProcessName, $_.MainWindowHandle) }
  Write-Output "NO_WINDOW"
  exit 1
}
$proc = $procs | Select-Object -First 1
$hwnd = $proc.MainWindowHandle
Write-Output ("window found: {0} hwnd={1}" -f $proc.ProcessName, $hwnd)
[WinApi]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 800

$pt = New-Object WinApi+POINT
# DPI 125%: พิกัดโลก (420,615) อยู่ client (336,492)
$pt.X = 336; $pt.Y = 492
[WinApi]::ClientToScreen($hwnd, [ref]$pt) | Out-Null
$cr = New-Object WinApi+RECT
[WinApi]::GetClientRect($hwnd, [ref]$cr) | Out-Null
Write-Output ("client {0}x{1}; click screen {2},{3}" -f $cr.Right, $cr.Bottom, $pt.X, $pt.Y)

function Snap ([int]$x, [int]$y, [int]$w, [int]$h, [string]$name) {
  $b = New-Object System.Drawing.Bitmap $w, $h
  $gg = [System.Drawing.Graphics]::FromImage($b)
  $gg.CopyFromScreen($x, $y, 0, 0, [System.Drawing.Size]::new($w, $h))
  $gg.Dispose()
  $b.Save("C:\m-simple-game\tower-defend\assets\art\gen\tmp\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $b.Dispose()
}

$cx = $pt.X - 150; $cy = $pt.Y - 160
Snap $cx $cy 300 220 "click_before"
[WinApi]::SetCursorPos($pt.X, $pt.Y) | Out-Null
Start-Sleep -Milliseconds 150
[WinApi]::mouse_event(0x0002, 0, 0, 0, 0)
Start-Sleep -Milliseconds 80
[WinApi]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 800
Snap $cx $cy 300 220 "click_after"

# diff
$a = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\tmp\click_before.png")
$b = [System.Drawing.Bitmap]::FromFile("C:\m-simple-game\tower-defend\assets\art\gen\tmp\click_after.png")
$d = 0
for ($yy = 0; $yy -lt $a.Height; $yy += 2) {
  for ($xx = 0; $xx -lt $a.Width; $xx += 2) {
    $p = $a.GetPixel($xx, $yy); $q = $b.GetPixel($xx, $yy)
    if ([math]::Abs($p.R - $q.R) + [math]::Abs($p.G - $q.G) + [math]::Abs($p.B - $q.B) -gt 24) { $d++ }
  }
}
Write-Output ("diff pixels: {0} threshold-150" -f $d)
$a.Dispose(); $b.Dispose()
