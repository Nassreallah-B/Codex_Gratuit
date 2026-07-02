# codex-openai.ps1 — Lance Codex sur TON COMPTE OpenAI (home ~/.codex, par defaut, intact).
# Bascule CODEX_HOME vers ~/.codex puis demarre l'app desktop.
# Pendant du launcher gratuit (codex-launch.ps1 -> home ~/.codex-openai).
$OPENAI_HOME = "$env:USERPROFILE\.codex"
$AUMID = "OpenAI.Codex_2p2nqsd0c76g0!App"

[Environment]::SetEnvironmentVariable('CODEX_HOME', $OPENAI_HOME, 'User')
$env:CODEX_HOME = $OPENAI_HOME
Write-Host "[ok] CODEX_HOME -> $OPENAI_HOME (compte OpenAI)" -ForegroundColor Green

# L'app ne lit CODEX_HOME qu'a SON demarrage : si une instance tourne (ex. mode gratuit),
# Start-Process ne ferait que la refocaliser -> on la ferme d'abord.
# Filtre sur le chemin du package Store pour ne PAS tuer le CLI 'codex' (codex exec).
$procs = Get-Process Codex -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'OpenAI\.Codex' }
if ($procs) {
  Write-Host "[..] app Codex deja ouverte — fermeture pour appliquer le home..." -ForegroundColor Yellow
  $procs | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object { $null = $_.CloseMainWindow() }
  Start-Sleep -Seconds 2
  Get-Process Codex -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'OpenAI\.Codex' } | Stop-Process -Force -ErrorAction SilentlyContinue
  for ($i = 0; $i -lt 10; $i++) {
    if (-not (Get-Process Codex -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'OpenAI\.Codex' })) { break }
    Start-Sleep -Milliseconds 500
  }
  Write-Host "[ok] app fermee" -ForegroundColor Green
}

Write-Host "[go] demarrage de Codex sur ton compte OpenAI..." -ForegroundColor Cyan
Start-Process "shell:AppsFolder\$AUMID"
