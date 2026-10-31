# วิเคราะห์คลิกจริง: เปิดเกม (จับ stdout), foregound, คลิกจุดที่เห็นจริง, อ่านค่าที่ Godot เห็น
$ErrorActionPreference = 'Stop'
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool f);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, int e);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
}
"@
$dir = "C:\m-simple-game"
Remove-Item "$dir\tmp_gd_out.txt" -ErrorAction SilentlyContinue

Get-Process | Where-Object { $_.ProcessName -like "*Godot*" } | Stop-Process -Force
Start-Sleep -Seconds 1
$g = "C:\Users\admin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
$p = Start-Process -FilePath $g -ArgumentList "--path", "$dir\tower-defend" -RedirectStandardOutput "$dir\tmp_gd_out.txt" -PassThru
Start-Sleep -Seconds 6
$p.Refresh()
$hwnd = $p.MainWindowHandle
Write-Output ("hwnd={0}" -f $hwnd)
[W]::SwitchToThisWindow($hwnd, $true)
Start-Sleep -Milliseconds 800

$pt = New-Object W+POINT
$pt.X = 336; $pt.Y = 492   # พิกัดภาพจริงของลาน (420,615) ตอน DPI 125%
[W]::ClientToScreen($hwnd, [ref]$pt) | Out-Null
$cr = New-Object W+RECT
[W]::GetClientRect($hwnd, [ref]$cr) | Out-Null
Write-Output ("client {0}x{1}; click screen {2},{3}" -f $cr.Right, $cr.Bottom, $pt.X, $pt.Y)
[W]::SetCursorPos($pt.X, $pt.Y) | Out-Null
Start-Sleep -Milliseconds 200
[W]::mouse_event(0x0002, 0, 0, 0, 0)
Start-Sleep -Milliseconds 80
[W]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 900
# คลิกรอบสอง (จุดเดียวกัน) เพื่อเช็คกรณีคลิกแรกใช้โฟกัส
[W]::mouse_event(0x0002, 0, 0, 0, 0)
Start-Sleep -Milliseconds 80
[W]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 900
Stop-Process -Id $p.Id -Force
Start-Sleep -Milliseconds 500
Get-Content "$dir\tmp_gd_out.txt" | Select-String "CLICK|OPEN_MENU|ERROR|SCRIPT" | Select-Object -First 20