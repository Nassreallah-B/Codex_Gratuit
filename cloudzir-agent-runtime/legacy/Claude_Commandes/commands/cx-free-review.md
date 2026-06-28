---
description: Review de code par l'agent Codex sur un provider GRATUIT (DeepSeek/HF/NVIDIA), sans OpenAI
argument-hint: "[deepseek|deepseek-pro|hf|nvidia|glm] [base-ref]"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Équivalent GRATUIT de `/codex:review` : fait relire le code par l'agent Codex tournant sur un provider gratuit (via le proxy LiteLLM local), au lieu du reviewer natif OpenAI.

Arguments bruts : `$ARGUMENTS`

Marche à suivre :
1. Parse `$ARGUMENTS` :
   - 1er token = **provider** parmi `deepseek` (défaut si absent), `deepseek-pro`, `hf`, `nvidia`, `glm`.
   - 2e token optionnel = **référence git de base** (ex: `main`) → compare la branche à cette base. Sinon, review du travail non commité.
2. Lance le helper (remplace `<provider>`, `<base>`, `<cwd>` = chemin absolu du repo courant) :
   ```
   pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode review -Provider <provider> -Repo "<cwd>" [-Base <base>]
   ```
   - Le helper allume le proxy 4000 tout seul si besoin.
   - C'est long (≈30 s à 2 min). Si le diff est gros, propose de lancer en tâche de fond (`run_in_background`).
3. Restitue **verbatim** la section affichée après `===== RAPPORT CODEX` — c'est la review faite par DeepSeek/HF/NVIDIA. N'ajoute PAS ta propre relecture ; ton rôle est juste de transmettre le rapport de Codex.
4. Si le helper sort en erreur (proxy KO, provider inconnu, pas un repo git), explique l'erreur et la correction.
