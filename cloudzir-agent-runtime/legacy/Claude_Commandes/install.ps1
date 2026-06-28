# install.ps1 — Installe les commandes cx-free dans Claude Code (+ prompts custom Codex).
# Usage : pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

$claudeCmd     = Join-Path $env:USERPROFILE '.claude\commands'
$claudeScripts = Join-Path $env:USERPROFILE '.claude\scripts'
$codexPrompts  = Join-Path $env:USERPROFILE '.codex\prompts'
New-Item -ItemType Directory -Force $claudeCmd, $claudeScripts, $codexPrompts | Out-Null

# 1) Slash-commandes Claude Code
Copy-Item "$src\commands\*.md" $claudeCmd -Force
# 2) Helper PowerShell
Copy-Item "$src\scripts\*.ps1" $claudeScripts -Force
# 3) Prompts custom de l'app Codex (bonus : /relire, /relire-critique dans l'app)
if (Test-Path "$src\prompts") { Copy-Item "$src\prompts\*.md" $codexPrompts -Force }

Write-Host "[ok] Slash-commandes Claude Code installees :" -ForegroundColor Green
Get-ChildItem "$claudeCmd\cx-free-*.md" | ForEach-Object { Write-Host ("   /" + $_.BaseName) }
Write-Host "[ok] Helper : $claudeScripts\cx-free.ps1" -ForegroundColor Green
Write-Host "[ok] Prompts app Codex : /relire, /relire-critique" -ForegroundColor Green

# 4) Verifs prerequis
Write-Host "`n=== Prerequis ===" -ForegroundColor Cyan
$codexOk = [bool](Get-Command codex -ErrorAction SilentlyContinue)
$litellmOk = [bool](Get-Command litellm -ErrorAction SilentlyContinue)
Write-Host ("  codex CLI    : " + $(if ($codexOk) { 'OK' } else { 'MANQUANT (npm i -g @openai/codex)' }))
Write-Host ("  litellm      : " + $(if ($litellmOk) { 'OK' } else { 'MANQUANT (uv tool install litellm)' }))
Write-Host ("  proxy 4000   : " + $(if (Get-NetTCPConnection -LocalPort 4000 -State Listen -ErrorAction SilentlyContinue) { 'UP' } else { 'DOWN (demarre auto au 1er appel)' }))

# 5) Rappel config Codex (la maj a supprime "max")
$cfg = Join-Path $env:USERPROFILE '.codex\config.toml'
if ((Test-Path $cfg) -and (Select-String -Path $cfg -Pattern '^\s*model_reasoning_effort\s*=\s*"max"' -Quiet)) {
  (Get-Content $cfg) -replace '^(\s*model_reasoning_effort\s*=\s*)"max"', '$1"xhigh"' | Set-Content -Path $cfg -Encoding utf8
  Write-Host "`n[ok] config.toml : model_reasoning_effort \"max\" -> \"xhigh\" (corrige auto ; max invalide depuis codex-cli 0.118.0)." -ForegroundColor Green
}

Write-Host "`nRedemarre Claude Code (ou recharge la session) pour voir les /cx-free-*." -ForegroundColor Cyan
