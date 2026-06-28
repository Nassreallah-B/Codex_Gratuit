---
description: État du pont gratuit Codex — proxy LiteLLM (port 4000) + providers disponibles
allowed-tools: Bash(pwsh:*)
---
Affiche l'état du pont gratuit (proxy LiteLLM + providers cx-free), sans rien lancer d'autre.

Marche à suivre :
1. Lance :
   ```
   pwsh -NoProfile -File "$env:USERPROFILE\.claude\scripts\cx-free.ps1" -Mode status
   ```
2. Restitue la sortie : proxy UP/DOWN sur 4000, modèles servis par le proxy, et la liste des providers utilisables (`deepseek`, `deepseek-pro`, `hf`, `nvidia`, `glm`).
3. Si le proxy est DOWN, rappelle qu'il démarre automatiquement au prochain `/cx-free-review`, `/cx-free-critique` ou `/cx-free-task`.
