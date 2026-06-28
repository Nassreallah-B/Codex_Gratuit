# Lance le proxy LiteLLM (pont Responses->chat pour Codex)
# Usage : pwsh -File "C:\Serveurs\Codex Gratuit\litellm-codex\start-litellm.ps1"
$dir = $PSScriptRoot   # auto-localise : le script trouve son .env/config.yaml ou qu'il soit

# Force UTF-8 (sinon la banniere LiteLLM crashe la console Windows cp1252)
$env:PYTHONUTF8 = "1"
$env:PYTHONIOENCODING = "utf-8"

# Charge les cles depuis .env dans l'environnement du process
Get-Content "$dir\.env" | ForEach-Object {
  if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$') {
    $name = $matches[1]; $val = $matches[2]
    $val = $val.Trim().Trim('"').Trim("'")   # supprime les quotes optionnelles
    if ($val) { Set-Item -Path "Env:$name" -Value $val }
  }
}
Write-Host "[ok] cles chargees : NVIDIA=$([bool]$env:NVIDIA_API_KEY) DEEPSEEK=$([bool]$env:DEEPSEEK_API_KEY) HF=$([bool]$env:HF_TOKEN)"

# Lance le proxy sur le port 4000
# IMPORTANT : Set-Location pour que Python trouve codex_deepseek_fix.py via le CWD
Set-Location -Path $dir
litellm --config "$dir\config.yaml" --port 4000
