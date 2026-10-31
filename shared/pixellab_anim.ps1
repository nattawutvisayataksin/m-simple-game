# รันแอนิเมชัน 3 ชิ้นผ่าน Pixellab REST v2 (budget 3 generations)
# คัง key ไว้นอก git: อ่านจาก .mcp.json (ถูก gitignore อยู่แล้ว) ไม่ฝัง key ในไฟล์นี้
$ErrorActionPreference = 'Stop'
$mcpConfig = Get-Content -Raw "$PSScriptRoot\..\.mcp.json" | ConvertFrom-Json
$KEY = ($mcpConfig.mcpServers.pixellab.headers.Authorization) -replace '^Bearer ', ''
$api = "https://api.pixellab.ai/v2"
$outDir = "C:\m-simple-game\assets\art\gen"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Post-Anim($name, $png, $desc, $subject, $pose, $frames) {
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($png))
  $body = @{
    first_frame        = @{ type = "base64"; base64 = $b64; format = "png" }
    description        = $desc
    subject_description = $subject
    initial_pose       = $pose
    frame_count        = $frames
    no_background      = $true
    view               = "low top-down"
  } | ConvertTo-Json -Depth 4
  $res = Invoke-RestMethod -Uri "$api/animate-pixminimax" -Method Post -Headers @{ Authorization = "Bearer $KEY" } -ContentType "application/json" -Body $body
  [IO.File]::WriteAllText("$outDir\$name.submit.json", ($res | ConvertTo-Json -Depth 6))
  $jobId = $res.bg_job_id; if (-not $jobId) { $jobId = $res.job_id }; if (-not $jobId) { $jobId = $res.id }
  Write-Output "[$name] submitted job=$jobId"
  return $jobId
}

function Wait-Job($name, $jobId) {
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 20
    try {
      $st = Invoke-RestMethod -Uri "$api/background-jobs/$jobId" -Headers @{ Authorization = "Bearer $KEY" }
      $status = $st.status; if (-not $status) { $status = $st.bg_job_status }
      Write-Output "[$name] poll#$i status=$status progress=$($st.progress)"
      if ($status -eq 'completed' -or $status -eq 'complete') {
        [IO.File]::WriteAllText("$outDir\$name.result.json", ($st | ConvertTo-Json -Depth 8))
        Write-Output "[$name] DONE"
        return
      }
      if ($status -eq 'failed' -or $status -eq 'error') {
        [IO.File]::WriteAllText("$outDir\$name.result.json", ($st | ConvertTo-Json -Depth 8))
        Write-Output "[$name] FAILED: $($st | ConvertTo-Json -Depth 4)"
        return
      }
    } catch {
      Write-Output "[$name] poll error: $($_.Exception.Message)"
    }
  }
  Write-Output "[$name] TIMEOUT"
}

# 1) Coin: หมุนเหรียญ (8 เฟรม = 1 gen)
$coin = Post-Anim 'coin' 'C:\m-simple-game\assets\art\sprites\coin_kub.png' `
  'coin spinning clockwise around its center like a rolling wheel, steady gentle bobbing' `
  'a round golden-orange crypto token coin with a bold K letter mark' `
  'coin lying flat, K letter facing the viewer' 8
Wait-Job 'coin' $coin

# 2) Player: Kubi เดินด้วยเท้าสั้น (6 เฟรม = 1 gen)
$player = Post-Anim 'player' 'C:\m-simple-game\assets\art\sprites\player_kubi.png' `
  'orange round robot mascot walking towards the camera with tiny stubby legs and gentle body bob' `
  'a cute round orange robot mascot with visor eyes and a small gold antenna badge' `
  'standing upright facing the viewer' 6
Wait-Job 'player' $player

# 3) Enemy: ไวรัสกระพือหนาม + ประกายไฟ (6 เฟรม = 1 gen)
$enemy = Post-Anim 'enemy' 'C:\m-simple-game\assets\art\sprites\enemy_glitch.png' `
  'evil virus orb pulsating menacingly, spikes flexing, electric sparks flickering around it' `
  'a menacing dark red spiky glitch orb virus with angry glowing eyes' `
  'hovering in place, face toward the viewer' 6
Wait-Job 'enemy' $enemy

Write-Output "ALL DONE"
