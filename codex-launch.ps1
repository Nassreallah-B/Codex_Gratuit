# codex-launch.ps1 — Choisis un modele, l'APPLICATION Codex demarre dessus.
# DeepSeek/NVIDIA/HF (API chat) : MCP coupes auto (incompatibles). OpenAI/Ollama : MCP actifs.
# Double-clic sur le raccourci "Codex (menu)".

# Homes Codex isoles :
#  - FREE_HOME   = providers gratuits (LiteLLM/DeepSeek/NVIDIA/HF/Ollama) -> gere par CE launcher
#  - OPENAI_HOME = compte OpenAI par defaut (app desktop standard) -> jamais touche par ce launcher
$FREE_HOME = "$env:USERPROFILE\.codex-openai"
$OPENAI_HOME = "$env:USERPROFILE\.codex"
$CONFIG = "$FREE_HOME\config.toml"
$SCRIPT_ROOT = $PSScriptRoot   # repo deplacable : tous les chemins derivent de l'emplacement du script
$PROXY = Join-Path $SCRIPT_ROOT "litellm-codex\start-litellm.ps1"
$MCPBAK = Join-Path $SCRIPT_ROOT "mcp-backup.toml"
$LITELLM_CATALOG = Join-Path $SCRIPT_ROOT "litellm-codex\litellm-models.json"
$AUMID = "OpenAI.Codex_2p2nqsd0c76g0!App"

# Bascule le home Codex actif (variable User persistante = lue par l'app Store + la session)
function Set-CodexHome([string]$path) {
  [Environment]::SetEnvironmentVariable('CODEX_HOME', $path, 'User')
  $env:CODEX_HOME = $path
  Write-Host "[ok] CODEX_HOME -> $path" -ForegroundColor Green
}

# Verifications de base
if (-not (Test-Path $CONFIG)) {
  Write-Host "[!] config.toml introuvable : $CONFIG" -ForegroundColor Red
  Write-Host "    Lance l'app Codex une premiere fois pour le generer." -ForegroundColor Yellow
  exit 1
}
if (-not (Get-Command litellm -ErrorAction SilentlyContinue)) {
  Write-Host "[!] litellm non installe. Installe-le : uv tool install litellm" -ForegroundColor Red
  exit 1
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host "[!] node non installe (requis pour le pont 4001). Installe Node.js." -ForegroundColor Red
  exit 1
}

function Port-Up([int]$p) {
  try { $t = New-Object Net.Sockets.TcpClient; $t.Connect('127.0.0.1', $p); $t.Close(); return $true }
  catch { return $false }
}

function Ensure-Proxy {
  if ((Port-Up 4000) -and (Port-Up 4001)) { Write-Host "[ok] proxy LiteLLM + pont 4001 deja allumes" -ForegroundColor Green; return }
  Write-Host "[..] demarrage du proxy LiteLLM + pont 4001..." -ForegroundColor Yellow
  $proxyDir = Split-Path $PROXY
  Start-Process pwsh -ArgumentList '-NoExit', '-File', "`"$PROXY`"" -WorkingDirectory $proxyDir -WindowStyle Minimized
  for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 1
    if ((Port-Up 4000) -and (Port-Up 4001)) { Start-Sleep -Seconds 2; Write-Host "[ok] proxy pret (4000 + 4001)" -ForegroundColor Green; return }
  }
  Write-Host "[!] proxy pas pret apres 40s — verifie la fenetre minimisee" -ForegroundColor Red
}

# Ecrit le modele+provider choisi comme DEFAUT (l'app Codex lit le defaut au demarrage)
function Set-Default([string]$model, [string]$provider) {
  $lines = Get-Content $CONFIG
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\[') { break }
    if ($lines[$i] -match '^\s*model\s*=') { $lines[$i] = "model = `"$model`"" }
    if ($lines[$i] -match '^\s*model_provider\s*=') { $lines[$i] = "model_provider = `"$provider`"" }
  }
  Set-Content -Path $CONFIG -Value $lines -Encoding utf8
}

# Force model_reasoning_effort="xhigh" a chaque lancement.
# L'app Codex reecrit parfois "max" (son reglage UI), valeur REFUSEE par codex-cli 0.118+
# ("unknown variant max, expected ... xhigh") -> 'codex exec' ne demarrait plus.
function Set-Reasoning {
  $lines = Get-Content $CONFIG
  $done = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*\[') { break }
    if ($lines[$i] -match '^\s*model_reasoning_effort\s*=') { $lines[$i] = 'model_reasoning_effort = "xhigh"'; $done = $true }
  }
  if (-not $done) { $lines = @('model_reasoning_effort = "xhigh"') + $lines }
  Set-Content -Path $CONFIG -Value $lines -Encoding utf8
}

# Ecrit/actualise model_catalog_json DANS la section [model_providers.litellm] (catalogue scoped).
# IMPORTANT : chaine litterale TOML a quotes simples — un chemin Windows dans une basic string
# a quotes doubles non echappee ("C:\Serveurs\...") = TOML invalide (\S, \l...) = config illisible.
function Set-LiteLLMScopedCatalog {
  $catalog = $LITELLM_CATALOG
  $lines = Get-Content $CONFIG
  $out = New-Object System.Collections.Generic.List[string]
  $inLite = $false
  $done = $false
  foreach ($ln in $lines) {
    if ($ln -match '^\s*\[model_providers\.litellm\]') { $inLite = $true; $done = $false; $out.Add($ln); continue }
    if ($inLite -and $ln -match '^\s*\[') {
      if (-not $done) { $out.Add("model_catalog_json = '$catalog'") }
      $inLite = $false
    }
    if ($inLite -and $ln -match '^\s*model_catalog_json\s*=') {
      $out.Add("model_catalog_json = '$catalog'")
      $done = $true
      continue
    }
    $out.Add($ln)
  }
  if ($inLite -and -not $done) { $out.Add("model_catalog_json = '$catalog'") }
  Set-Content -Path $CONFIG -Value $out -Encoding utf8
}

# Gere le catalogue de modeles GLOBAL (top-level model_catalog_json).
#  - openai  : AUCUN catalogue global -> l'app Codex affiche ses VRAIS modeles OpenAI (gpt-5.5, gpt-5-codex...).
#  - ollama  : catalogue global = ollama-launch-models.json (modeles ollama cloud).
#  - litellm : aucun global -> le catalogue scoped [model_providers.litellm] fait foi.
# Sans ca, le global ollama-launch-models.json masquait les modeles OpenAI au profit des deepseek/nvidia/hf.
function Set-Catalog([string]$provider) {
  if ($provider -eq 'litellm') { Set-LiteLLMScopedCatalog }
  $ollamaCat = "$FREE_HOME\ollama-launch-models.json"
  $lines = Get-Content $CONFIG
  $out = New-Object System.Collections.Generic.List[string]
  $inHeader = $true
  foreach ($ln in $lines) {
    if ($ln -match '^\s*\[') { $inHeader = $false }
    if ($inHeader -and $ln -match '^\s*model_catalog_json\s*=') { continue }  # retire tout catalogue global existant
    $out.Add($ln)
  }
  if ($provider -eq 'ollama-launch-codex-app') {
    $final = New-Object System.Collections.Generic.List[string]
    $added = $false
    foreach ($ln in $out) {
      $final.Add($ln)
      if (-not $added -and $ln -match '^\s*model_provider\s*=') {
        $final.Add("model_catalog_json = '$ollamaCat'")   # chaine litterale TOML : pas d'echappement
        $added = $true
      }
    }
    $out = $final
  }
  Set-Content -Path $CONFIG -Value $out -Encoding utf8
}

# Coupe les serveurs MCP externes (incompatibles avec les API chat type DeepSeek)
# IMPORTANT : node_repl est le serveur INTERNE de Codex — on ne le touche JAMAIS.
function Strip-MCP {
  $lines = Get-Content $CONFIG
  $out = New-Object System.Collections.Generic.List[string]
  $mcp = New-Object System.Collections.Generic.List[string]
  $inMcp = $false
  $mcpName = ""
  foreach ($ln in $lines) {
    if ($ln -match '^\s*\[mcp_servers\.([^\]]+)\]') { $inMcp = $true; $mcpName = $matches[1] }
    elseif ($ln -match '^\s*\[' -and $ln -notmatch '^\s*\[mcp_servers\.') { $inMcp = $false; $mcpName = "" }
    # node_repl (+ node_repl.env) = serveur interne Codex → on le garde dans config
    if ($inMcp -and $mcpName -notmatch '^node_repl') { $mcp.Add($ln) }
    else { $out.Add($ln) }
  }
  if ($mcp.Count -gt 0) {
    Set-Content -Path $MCPBAK -Value $mcp -Encoding utf8
    Set-Content -Path $CONFIG -Value $out -Encoding utf8
    Write-Host "[ok] $($mcp.Count) lignes MCP externes sauvegardees" -ForegroundColor Yellow
  }
}

# Remet les serveurs MCP externes (pour OpenAI/Ollama qui les supportent)
# IMPORTANT : on ignore node_repl dans la verification — il est toujours present (injecte par Codex).
function Restore-MCP {
  # Verifie si des serveurs EXTERNES (hors node_repl) sont deja presents
  $hasExternal = Get-Content $CONFIG | Select-String '^\s*\[mcp_servers\.(?!node_repl)' -Quiet
  if ($hasExternal) { Write-Host "[i] MCP externes deja presents" -ForegroundColor DarkYellow; return }
  if (-not (Test-Path $MCPBAK)) { Write-Host "[!] mcp-backup.toml introuvable" -ForegroundColor Red; return }
  Add-Content -Path $CONFIG -Value "" -Encoding utf8
  Add-Content -Path $CONFIG -Value (Get-Content $MCPBAK) -Encoding utf8
  Write-Host "[ok] MCP externes restaures depuis mcp-backup.toml" -ForegroundColor Green
}

# Regenere config.yaml : le wildcard '*' route TOUT nom de modele envoye par l'app
# Codex (gpt-5.5, gpt-5-codex, gpt-5.x a venir...) vers le provider choisi dans le menu.
# => le menu fait foi, peu importe ce que le selecteur de modele de l'app affiche.
function Update-LiteLLMConfig([string]$menuModel) {
  $yamlPath = Join-Path (Split-Path $PROXY) 'config.yaml'

  $wcThink = $false
  $wcThinkDS = $false
  switch ($menuModel) {
    'deepseek-flash' { $wcModel = 'deepseek/deepseek-v4-flash'; $wcBase = 'https://api.deepseek.com'; $wcKey = 'DEEPSEEK_API_KEY' }
    'deepseek-v4-pro' { $wcModel = 'deepseek/deepseek-v4-pro'; $wcBase = 'https://api.deepseek.com'; $wcKey = 'DEEPSEEK_API_KEY'; $wcThinkDS = $true }
    'nvidia-deepseek' { $wcModel = 'nvidia_nim/deepseek-ai/deepseek-v4-pro'; $wcBase = 'https://integrate.api.nvidia.com/v1'; $wcKey = 'NVIDIA_API_KEY_DEEPSEEK'; $wcThink = $true }
    'nvidia-glm' { $wcModel = 'nvidia_nim/z-ai/glm-5.1'; $wcBase = 'https://integrate.api.nvidia.com/v1'; $wcKey = 'NVIDIA_API_KEY_GLM' }
    'hf' { $wcModel = 'huggingface/Qwen/Qwen3-Coder-Next'; $wcBase = ''; $wcKey = 'HF_TOKEN' }
    default { $wcModel = 'deepseek/deepseek-v4-flash'; $wcBase = 'https://api.deepseek.com'; $wcKey = 'DEEPSEEK_API_KEY' }
  }

  # params du wildcard (api_base optionnel : HF n'en a pas ; extra_body thinking:false pour deepseek-v4-pro NVIDIA)
  $wc = New-Object System.Collections.Generic.List[string]
  $wc.Add("      model: $wcModel")
  if ($wcBase) { $wc.Add("      api_base: $wcBase") }
  $wc.Add("      api_key: os.environ/$wcKey")
  $wc.Add("      use_chat_completions_api: true")
  if ($wcThink) { $wc.Add('      extra_body: {"chat_template_kwargs": {"thinking": false}}') }
  if ($wcThinkDS) { $wc.Add('      reasoning_effort: high'); $wc.Add('      extra_body: {"thinking": {"type": "enabled"}}') }
  $wcParams = $wc -join "`n"

  # contextes reels : DeepSeek direct 1M, NVIDIA DeepSeek 1M, NVIDIA GLM-5.1 200k, HF/Qwen 256k.
  # model_info doit etre FRERE de litellm_params (indent 4) — imbrique dedans, LiteLLM l'ignore.
  # Codex lit surtout le catalogue scoped litellm-models.json ; ceci aligne /model/info dessus.
  $dsInfo = "    model_info:`n      context_window: 1048576`n      max_context_window: 1048576"
  $nvDsInfo = "    model_info:`n      context_window: 1048576`n      max_context_window: 1048576"
  $glmInfo = "    model_info:`n      context_window: 200000`n      max_context_window: 200000"
  $hfInfo = "    model_info:`n      context_window: 262144`n      max_context_window: 262144"

  $yaml = @"
# LiteLLM proxy — pont API Responses (Codex) -> chat/completions (DeepSeek/NVIDIA/HF)
# GENERE AUTOMATIQUEMENT par codex-launch.ps1 a chaque lancement — ne pas editer a la main.
model_list:
  - model_name: deepseek-flash
    litellm_params:
      model: deepseek/deepseek-v4-flash
      api_base: https://api.deepseek.com
      api_key: os.environ/DEEPSEEK_API_KEY
      use_chat_completions_api: true
$dsInfo

  - model_name: deepseek-v4-pro
    litellm_params:
      model: deepseek/deepseek-v4-pro
      api_base: https://api.deepseek.com
      api_key: os.environ/DEEPSEEK_API_KEY
      use_chat_completions_api: true
      reasoning_effort: high
      extra_body: {"thinking": {"type": "enabled"}}
$dsInfo

  - model_name: nvidia-deepseek
    litellm_params:
      model: nvidia_nim/deepseek-ai/deepseek-v4-pro
      api_base: https://integrate.api.nvidia.com/v1
      api_key: os.environ/NVIDIA_API_KEY_DEEPSEEK
      use_chat_completions_api: true
      extra_body: {"chat_template_kwargs": {"thinking": false}}
$nvDsInfo

  - model_name: nvidia-glm
    litellm_params:
      model: nvidia_nim/z-ai/glm-5.1
      api_base: https://integrate.api.nvidia.com/v1
      api_key: os.environ/NVIDIA_API_KEY_GLM
      use_chat_completions_api: true
$glmInfo

  - model_name: hf
    litellm_params:
      model: huggingface/Qwen/Qwen3-Coder-Next
      api_key: os.environ/HF_TOKEN
      use_chat_completions_api: true
$hfInfo

  # catch-all : route vers le provider du menu ($menuModel)
  - model_name: "*"
    litellm_params:
$wcParams

litellm_settings:
  drop_params: true
  callbacks: codex_deepseek_fix.handler

general_settings:
  master_key: sk-codex-local
"@

  Set-Content -Path $yamlPath -Value $yaml -Encoding utf8
  Write-Host "[ok] config.yaml regenere : wildcard '*' -> $menuModel" -ForegroundColor Green
}

# Arrete la stack proxy : LiteLLM (4000, + sa fenetre pwsh parente) et le pont Node (4001)
function Stop-Proxy {
  if (-not ((Port-Up 4000) -or (Port-Up 4001))) { return }
  Write-Host "[..] arret du proxy existant (rechargement de config)..." -ForegroundColor Yellow
  foreach ($port in 4000, 4001) {
    try {
      $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
      foreach ($c in $conns) {
        $procId = $c.OwningProcess
        if (-not $procId -or $procId -eq $PID) { continue }
        # la fenetre pwsh parente n'est tuee que pour LiteLLM (4000) ; le pont node (4001) n'en a pas
        $parent = $null
        if ($port -eq 4000) {
          $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$procId" -ErrorAction SilentlyContinue).ParentProcessId
        }
        Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        if ($parent -and $parent -ne $PID) {
          $pp = Get-Process -Id $parent -ErrorAction SilentlyContinue
          if ($pp -and $pp.ProcessName -match 'pwsh|powershell') { Stop-Process -Id $parent -Force -ErrorAction SilentlyContinue }
        }
      }
    }
    catch { Write-Host "[!] erreur arret proxy (port $port): $_" -ForegroundColor Red }
  }
  for ($i = 0; $i -lt 20; $i++) { if (-not ((Port-Up 4000) -or (Port-Up 4001))) { break }; Start-Sleep -Milliseconds 500 }
}

function Launch-App([string]$model, [string]$provider, [bool]$needProxy, [bool]$withMcp) {
  # --- Compte OpenAI : on bascule sur le home par defaut ~/.codex et on N'Y TOUCHE PAS ---
  if ($provider -eq 'openai') {
    Set-CodexHome $OPENAI_HOME
    Write-Host "[go] Codex sur ton COMPTE OpenAI (home ~/.codex, config intacte)..." -ForegroundColor Cyan
    Write-Host "    (ferme l'app si elle etait ouverte, puis relance pour appliquer le home)" -ForegroundColor DarkGray
    Start-Process "shell:AppsFolder\$AUMID"
    return
  }
  # --- Providers gratuits : home dedie ~/.codex-openai (gere uniquement ici) ---
  Set-CodexHome $FREE_HOME
  Set-Default $model $provider
  Set-Reasoning   # garantit xhigh a chaque demarrage (l'app reecrit parfois "max", invalide)
  Set-Catalog $provider   # catalogue: ollama=ollama-launch-models.json, litellm=scoped
  if ($withMcp) { Restore-MCP; Write-Host "[ok] MCP/memoire ACTIFS" -ForegroundColor Green }
  else { Strip-MCP; Write-Host "[i] MCP coupes pour cette session (l'API chat ne les supporte pas)" -ForegroundColor DarkYellow }
  if ($needProxy) {
    Update-LiteLLMConfig $model   # menu = source de verite : wildcard pointe sur ce provider
    Stop-Proxy                    # force LiteLLM a recharger la nouvelle config
    Ensure-Proxy
  }
  Write-Host "[go] demarrage de l'application Codex (GRATUIT) sur '$model'..." -ForegroundColor Cyan
  Write-Host "    (si l'app etait deja ouverte, ferme-la et relance pour appliquer)" -ForegroundColor DarkGray
  Start-Process "shell:AppsFolder\$AUMID"
}

Write-Host ""
Write-Host "  ===== LANCEUR CODEX =====" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1) DeepSeek-V4-flash      rapide, pas cher          [MCP OK]  <- recommande"
Write-Host "   2) DeepSeek-V4-pro        plus fort (ton compte)   [MCP OK]"
Write-Host "   3) NVIDIA DeepSeek-V4-pro instable cote NVIDIA      [MCP OK]"
Write-Host "   4) NVIDIA GLM-5.1         gratuit, rapide          [MCP OK]"
Write-Host "   5) HuggingFace Qwen3.6    gratuit                  [MCP OK]"
Write-Host "   6) Mon compte OpenAI      gpt-5.5 (home ~/.codex)   [compte, MCP OK]"
Write-Host "   7) Ollama cloud           minimax (ollama signin)  [cloud]"
Write-Host ""
$c = Read-Host "  Ton choix (1-7)"

switch ($c) {
  '1' { Launch-App "deepseek-flash"   "litellm"                  $true  $false }
  '2' { Launch-App "deepseek-v4-pro"  "litellm"                  $true  $false }
  '3' { Launch-App "nvidia-deepseek"  "litellm"                  $true  $false }
  '4' { Launch-App "nvidia-glm"       "litellm"                  $true  $false }
  '5' { Launch-App "hf"               "litellm"                  $true  $false }
  '6' { Launch-App "gpt-5.5"          "openai"                   $false $true  }
  '7' { Launch-App "minimax-m3:cloud" "ollama-launch-codex-app"  $false $false }
  default { Write-Host "Choix invalide. Relance le lanceur." -ForegroundColor Red }
}
