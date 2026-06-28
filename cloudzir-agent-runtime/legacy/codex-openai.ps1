# codex-openai.ps1 — Lance Codex sur TON COMPTE OpenAI (home ~/.codex, par defaut, intact).
# Bascule CODEX_HOME vers ~/.codex puis demarre l'app desktop.
# Pendant du launcher gratuit (codex-launch.ps1 -> home ~/.codex-openai).
$OPENAI_HOME = "$env:USERPROFILE\.codex"
$AUMID = "OpenAI.Codex_2p2nqsd0c76g0!App"

[Environment]::SetEnvironmentVariable('CODEX_HOME', $OPENAI_HOME, 'User')
$env:CODEX_HOME = $OPENAI_HOME
Write-Host "[ok] CODEX_HOME -> $OPENAI_HOME (compte OpenAI)" -ForegroundColor Green
Write-Host "[go] demarrage de Codex sur ton compte OpenAI..." -ForegroundColor Cyan
Write-Host "    (si l'app etait deja ouverte, ferme-la et relance pour appliquer le home)" -ForegroundColor DarkGray
Start-Process "shell:AppsFolder\$AUMID"
