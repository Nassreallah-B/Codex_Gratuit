# cx-free.ps1 — Pont Claude Code -> Codex CLI sur provider GRATUIT (DeepSeek/HF/NVIDIA via proxy LiteLLM).
# Modes : review (revue), critique (revue adversariale), task (demande libre), status (etat proxy/providers).
# Usage :
#   pwsh -NoProfile -File cx-free.ps1 -Mode review   -Provider deepseek [-Base main] [-Repo <dir>]
#   pwsh -NoProfile -File cx-free.ps1 -Mode critique  -Provider hf       [-Base main] [-Repo <dir>]
#   pwsh -NoProfile -File cx-free.ps1 -Mode task      -Provider nvidia -Prompt "..." [-Write] [-Repo <dir>]
#   pwsh -NoProfile -File cx-free.ps1 -Mode status
param(
  [ValidateSet('review','critique','task','status')] [string]$Mode = 'review',
  [string]$Provider = 'deepseek',
  [string]$Base = '',
  [string]$Prompt = '',
  [switch]$Write,
  [string]$Repo = (Get-Location).Path
)
$ErrorActionPreference = 'Stop'
$proxyDir = 'C:\Serveurs\Codex Gratuit\litellm-codex'
function Test-ProxyUp { [bool](Get-NetTCPConnection -LocalPort 4000 -State Listen -ErrorAction SilentlyContinue) }

# --- Mode status : etat du proxy + modeles, sans rien lancer ---
if ($Mode -eq 'status') {
  $up = Test-ProxyUp
  Write-Host ("Proxy LiteLLM (port 4000) : " + $(if ($up) { 'UP' } else { 'DOWN (demarre auto au prochain review/critique/task)' }))
  if ($up) {
    try {
      $m = Invoke-RestMethod -Uri 'http://127.0.0.1:4000/v1/models' -Headers @{ Authorization = 'Bearer sk-codex-local' } -TimeoutSec 8
      Write-Host ("Modeles servis : " + (($m.data | ForEach-Object { $_.id }) -join ', '))
    } catch { Write-Host "  (/v1/models injoignable : $($_.Exception.Message))" }
  }
  Write-Host "Providers cx-free : deepseek (defaut), deepseek-pro, hf, nvidia, glm"
  exit 0
}

# --- provider -> nom de modele LiteLLM (doit matcher config.yaml du proxy) ---
switch ($Provider.ToLower()) {
  { $_ -in 'deepseek','ds','deepseek-flash' } { $model = 'deepseek-flash' }
  'deepseek-pro'                              { $model = 'deepseek-pro' }
  { $_ -in 'hf','huggingface','qwen' }        { $model = 'hf' }
  { $_ -in 'nvidia','nvidia-deepseek','nv' }  { $model = 'nvidia-deepseek' }
  { $_ -in 'glm','nvidia-glm' }               { $model = 'nvidia-glm' }
  default { Write-Error "Provider inconnu '$Provider' (deepseek|deepseek-pro|hf|nvidia|glm)"; exit 2 }
}

# --- proxy LiteLLM 4000 up (sinon demarrage detache) ---
if (-not (Test-ProxyUp)) {
  Write-Host "[cx-free] proxy 4000 eteint -> demarrage..."
  $env:PYTHONUTF8 = '1'; $env:PYTHONIOENCODING = 'utf-8'
  if (Test-Path "$proxyDir\.env") {
    Get-Content "$proxyDir\.env" | ForEach-Object {
      if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$') {
        $v = $matches[2].Trim().Trim('"').Trim("'"); if ($v) { Set-Item -Path "Env:$($matches[1])" -Value $v }
      }
    }
  }
  Start-Process litellm -ArgumentList '--config','config.yaml','--port','4000' -WorkingDirectory $proxyDir -WindowStyle Hidden | Out-Null
  for ($i = 0; $i -lt 45; $i++) { Start-Sleep -Seconds 1; if (Test-ProxyUp) { Start-Sleep -Seconds 2; break } }
}
if (-not (Test-ProxyUp)) { Write-Error "[cx-free] proxy LiteLLM (port 4000) indisponible."; exit 1 }

# --- construire le prompt selon le mode ---
if ($Mode -eq 'review' -or $Mode -eq 'critique') {
  if ($Base) { $cible = "Compare la branche a la reference '$Base' : ``git diff $Base...HEAD`` (+ ``git log --oneline $Base..HEAD``)." }
  else       { $cible = "Relis le travail NON COMMITE : ``git status --short --untracked-files=all``, puis ``git diff`` et ``git diff --cached``, et lis les fichiers non suivis." }

  if ($Mode -eq 'review') {
    $promptText = @"
Tu es un relecteur de code senior. Fais une revue de code RIGOUREUSE des changements git de ce depot, EN LECTURE SEULE (ne modifie rien, ne committe rien).
$cible
Lis les fichiers concernes pour le contexte, pas seulement le diff. Ne signale que des problemes REELS et verifiables (zero invention).
Rends en francais :
1. Resume (1-3 phrases).
2. Findings tries du plus grave au plus leger : [CRITIQUE|ELEVEE|MOYENNE|FAIBLE] fichier:ligne - probleme - correctif propose (extrait de code si utile). Couvre : bugs/logique, securite (injection, secrets, authz, validation), cas limites et erreurs non gerees, regressions, concurrence, perf, puis qualite (lisibilite, duplication, nommage).
3. Recommandation finale : OK a merger / a corriger avant merge / bloquant.
Si rien de notable : dis-le clairement.
"@
  } else {
    $promptText = @"
Tu es un relecteur de code ADVERSARIAL (red team). Cherche ACTIVEMENT le pire bug cache dans les changements git de ce depot, comme si un incident de prod en dependait. EN LECTURE SEULE (ne modifie rien, ne committe rien).
$cible
Lis les fichiers concernes pour comprendre le contexte d'execution reel. Pour chaque finding, donne un scenario concret de reproduction. Zero hallucination : chaque finding pointe un fichier:ligne reel ; si non prouvable, classe "a verifier".
Rends en francais :
1. Le bug le plus dangereux (s'il existe) : fichier:ligne, scenario de repro, impact, correctif.
2. Autres findings tries par gravite : [CRITIQUE|ELEVEE|MOYENNE|FAIBLE] fichier:ligne - probleme - repro - correctif. Vise : valeurs limites, null/undefined, erreurs reseau/timeout, races, ordres d'await, secrets, contournement authz, injection (SQL/commande/prompt), dates/fuseaux, argent/arrondis, idempotence, retries.
3. Angles verifies sans probleme trouve (couverture).
4. Verdict : bloquant / a corriger / OK.
"@
  }
  $sandbox = 'read-only'
} else {
  # task
  if (-not $Prompt) { Write-Error "[cx-free] -Prompt requis en mode task."; exit 2 }
  $promptText = $Prompt
  $sandbox = if ($Write) { 'workspace-write' } else { 'read-only' }
}

# --- executer codex exec force sur le provider gratuit ---
$outFile = Join-Path $env:TEMP ("cx-free-" + [System.Guid]::NewGuid().ToString('N') + ".txt")
$logFile = Join-Path $env:TEMP ("cx-free-log-" + [System.Guid]::NewGuid().ToString('N') + ".txt")
Write-Host "[cx-free] mode=$Mode provider=$Provider modele=$model sandbox=$sandbox repo=$Repo"
Write-Host "[cx-free] codex exec en cours (via proxy LiteLLM)..."
$codexArgs = @(
  'exec',
  '-c','model_provider=litellm',
  '-m', $model,
  '--sandbox', $sandbox,
  '--skip-git-repo-check',
  '--color','never',
  '-C', $Repo,
  '-o', $outFile,
  $promptText
)
# stdin vide ferme (sinon codex exec bloque sur "Reading additional input from stdin...").
# Tout le bruit de codex (logs MCP/skills) -> fichier ; on n'affiche que le rapport final.
$null | & codex @codexArgs *> $logFile
$code = $LASTEXITCODE

Write-Host ""
Write-Host "===== RAPPORT CODEX ($Provider / $model) ====="
if ((Test-Path $outFile) -and ((Get-Item $outFile).Length -gt 0)) {
  Get-Content -Raw $outFile
} else {
  Write-Host "(aucun rapport final capture)"
}
if ($code -ne 0) {
  Write-Host ""
  Write-Host "----- codex a quitte (code $code) ; fin du log : -----"
  if (Test-Path $logFile) { Get-Content -Tail 15 $logFile }
}
Remove-Item $outFile, $logFile -ErrorAction SilentlyContinue
exit $code
