---
description: Demande/tâche à l'agent Codex sur un provider GRATUIT (DeepSeek/HF/NVIDIA), sans OpenAI
argument-hint: "[deepseek|deepseek-pro|hf|nvidia|glm] [--write] <ta demande>"
allowed-tools: Bash(pwsh:*), Read, Glob, Grep
---
Envoie n'importe quelle demande à l'agent Codex tournant sur un provider GRATUIT (via le proxy LiteLLM local).

Arguments bruts : `$ARGUMENTS`

Marche à suivre :
1. Parse `$ARGUMENTS` :
   - Si le 1er token est l'un de `deepseek`, `deepseek-pro`, `hf`, `nvidia`, `glm` → c'est le **provider** ; sinon provider = `deepseek` et tout est la demande.
   - Flag optionnel `--write` → autorise l'agent à **modifier des fichiers** (sandbox workspace-write). Sans lui, lecture seule.
   - Le reste = la **demande** (prompt).
2. Lance le helper (remplace `<provider>`, `<cwd>`, `<demande>`) :
   ```
   pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode task -Provider <provider> -Repo "<cwd>" [-Write] -Prompt "<demande>"
   ```
   - Le helper allume le proxy 4000 si besoin.
   - C'est long (≈30 s à 2 min) ; propose `run_in_background` si la demande est lourde.
3. Restitue **verbatim** la section après `===== RAPPORT CODEX` (la réponse de DeepSeek/HF/NVIDIA).
4. En cas d'erreur (proxy KO, provider inconnu), explique et corrige.
