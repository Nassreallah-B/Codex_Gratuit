# Lance la stack proxy complete pour Codex :
#   pont Node (port 4001, fix /v1/models) + LiteLLM (port 4000, pont Responses->chat)
# Usage : pwsh -File "start-litellm.ps1"  (normalement lance par codex-launch.ps1)
$dir = $PSScriptRoot   # auto-localise : le script trouve son .env/config.yaml ou qu'il soit

function Port-Up([int]$p) {
  try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('127.0.0.1', $p); $t.Close(); return $true }
  catch { return $false }
}

# Force UTF-8 (sinon la banniere LiteLLM crashe la console Windows cp1252)
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

# config.yaml est genere par codex-launch.ps1 (wildcard '*' -> provider du menu)
if (-not (Test-Path "$dir\config.yaml")) {
  Write-Host "[!] config.yaml introuvable : lance d'abord codex-launch.ps1 (menu)" -ForegroundColor Red
  exit 1
}

# Charge les cles depuis .env dans l'environnement du process
Get-Content "$dir\.env" | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$') {
    $name = $matches[1]; $val = $matches[2]
    $val = $val.Trim().Trim('"').Trim("'")   # supprime les quotes optionnelles
    if ($val) { Set-Item -Path "Env:$name" -Value $val }
  }
}

# Valide que TOUTES les cles referencees par config.yaml sont presentes et non vides
$required = Select-String -Path "$dir\config.yaml" -Pattern 'os\.environ/([A-Z0-9_]+)' -AllMatches |
  ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missing = @($required | Where-Object { -not (Get-Item "Env:$_" -ErrorAction SilentlyContinue).Value })
if ($missing.Count -gt 0) {
  Write-Host "[!] cles manquantes ou vides dans .env : $($missing -join ', ')" -ForegroundColor Red
  exit 1
}
Write-Host "[ok] cles chargees : $($required -join ', ')"

# Pont Node 4001 : Codex attend {"models":[...]} sur /v1/models, LiteLLM renvoie {"data":[...]}.
# ~/.codex-openai/config.toml pointe sur 4001 ; le pont forwarde tout vers LiteLLM 4000.
if (-not (Port-Up 4001)) {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[!] node introuvable - le pont 4001 ne peut pas demarrer" -ForegroundColor Red
    exit 1
  }
  Start-Process node -ArgumentList "`"$dir\codex-litellm-proxy.js`"" -WindowStyle Hidden
  $up = $false
  for ($i = 0; $i -lt 20; $i++) { Start-Sleep -Milliseconds 500; if (Port-Up 4001) { $up = $true; break } }
  if (-not $up) { Write-Host "[!] pont 4001 pas pret apres 10s" -ForegroundColor Red; exit 1 }
}
Write-Host "[ok] pont Codex->LiteLLM actif sur 4001"

# Lance le proxy sur le port 4000
# IMPORTANT : Set-Location pour que Python trouve codex_deepseek_fix.py via le CWD
Set-Location -Path $dir
litellm --config "$dir\config.yaml" --port 4000
