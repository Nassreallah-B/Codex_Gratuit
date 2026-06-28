---
description: Review ADVERSARIALE (red team) par l'agent Codex sur un provider GRATUIT (DeepSeek/HF/NVIDIA)
argument-hint: "[deepseek|deepseek-pro|hf|nvidia|glm] [base-ref]"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Review ADVERSARIALE (cherche activement le pire bug caché, avec scénario de repro) par l'agent Codex sur un provider GRATUIT — équivalent libre de `/codex:adversarial-review`.

Arguments bruts : `$ARGUMENTS`

Marche à suivre :
1. Parse `$ARGUMENTS` :
   - 1er token = **provider** (`deepseek` défaut, `deepseek-pro`, `hf`, `nvidia`, `glm`).
   - 2e token optionnel = **référence git de base** (ex: `main`).
2. Lance :
   ```
   pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode critique -Provider <provider> -Repo "<cwd>" [-Base <base>]
   ```
   Le helper allume le proxy 4000 si besoin. C'est long (≈30 s–2 min) ; propose `run_in_background` si gros diff.
3. Restitue **verbatim** la section après `===== RAPPORT CODEX` (analyse faite par DeepSeek/HF/NVIDIA). N'ajoute pas ta propre analyse.
