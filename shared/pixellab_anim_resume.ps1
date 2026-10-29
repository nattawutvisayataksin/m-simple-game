# Resume: poll job เหรียญที่ส่งไปแล้ว แล้ว gen ผู้เล่น/ศัตรู ต่อ (ทำงานให้ ID ถูกต้อง)
$ErrorActionPreference = 'Continue'
$KEY = (Get-Content -Raw "$PSScriptRoot\..\.mcp.json" | ConvertFrom-Json).mcpServers.pixellab.headers.Authorization -replace '^Bearer ', ''
$api = "https://api.pixellab.ai/v2"
$outDir = "C:\m-simple-game\assets\art\gen"

function Poll-Job($name, $jobId) {
  for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 20
    try {
      $st = Invoke-RestMethod -Uri "$api/background-jobs/$jobId" -Headers @{ Authorization = "Bearer $KEY" }
      Write-Output "[$name] poll#$i status=$($st.status)"
      if ($st.status -in @('completed', 'complete', 'succeeded')) {
        [IO.File]::WriteAllText("$outDir\$name.result.json", ($st | ConvertTo-Json -Depth 10))
        # ดาวน์โหลดทุกเฟรม png ที่เจอใน last_response (รู้สึกง่าย: คูณสร้าง URL ตามลำดับ)
        $jsonText = $st.last_response | ConvertTo-Json -Depth 10
        $urls = [regex]::Matches($jsonText, 'https://[^"\\ ]+\.png') | ForEach-Object { $_.Value } | Select-Object -Unique
        $n = 0
        foreach ($u in $urls) {
          $n++
          Invoke-WebRequest -Uri $u -OutFile "$outDir\$name.frames_$("{0:d2}" -f $n).png"
        }
        Write-Output "[$name] DONE frames=$n"
        return $true
      }
      if ($st.status -in @('failed', 'error')) {
        [IO.File]::WriteAllText("$outDir\$name.result.json", ($st | ConvertTo-Json -Depth 10))
        Write-Output "[$name] FAILED"
        return $false
      }
    } catch {
      Write-Output "[$name] poll error: $($_.Exception.Message)"
    }
  }
  Write-Output "[$name] TIMEOUT"
  return $false
}

function Run-Anim($name, $png, $desc, $subject, $pose, $frames) {
  if (Test-Path "$outDir\$name.result.json") { Write-Output "[$name] already have result"; return }
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($png))
  $body = @{
    first_frame         = @{ type = "base64"; base64 = $b64; format = "png" }
    description         = $desc
    subject_description = $subject
    initial_pose        = $pose
    frame_count         = $frames
    no_background       = $true
    view                = "low top-down"
  } | ConvertTo-Json -Depth 4
  $res = Invoke-RestMethod -Uri "$api/animate-pixminimax" -Method Post -Headers @{ Authorization = "Bearer $KEY" } -ContentType "application/json" -Body $body
  $jobId = $res.background_job_id
  Write-Output "[$name] submitted job=$jobId"
  Poll-Job $name $jobId
}

# 1) งานเหรียญส่งไปแล้ว (055ce4b1-...) — รอผลเท่านั้น
Poll-Job 'coin' '055ce4b1-b693-49a2-9ecf-f3e9c2b05ad6'

# 2) Player: Kubi เดิน (8 เฟรม — REST รับเฉพาะทุก 4)
Run-Anim 'player' "$PSScriptRoot\..\assets\art\sprites\player_kubi.png" `
  'orange round robot mascot walking towards the camera with tiny stubby legs and gentle body bob' `
  'a cute round orange robot mascot with visor eyes and a small gold antenna badge' `
  'standing upright facing the viewer' 8

# 3) Enemy: ไวรัสหนามกระพือ + ประกายไฟ (8 เฟรม)
Run-Anim 'enemy' "$PSScriptRoot\..\assets\art\sprites\enemy_glitch.png" `
  'evil virus orb pulsating menacingly, spikes flexing, electric sparks flickering around it' `
  'a menacing dark red spiky glitch orb virus with angry glowing eyes' `
  'hovering in place, face toward the viewer' 8

Write-Output "ALL DONE"
