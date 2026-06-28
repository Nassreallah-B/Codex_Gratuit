# CloudZIR Agent Runtime

Duplication renforcée de **Codex Gratuit** pour transformer le projet en runtime portable, testable et exploitable dans l'écosystème CloudZIR.AI.

## Objectif

CloudZIR Agent Runtime fournit une couche CLI cross-platform entre Codex/Codex CLI et LiteLLM afin de router les tâches d'agents vers DeepSeek, NVIDIA NIM ou Hugging Face, avec fallback possible vers OpenAI côté configuration Codex native.

Cette version conserve le projet original dans `legacy/` et ajoute une base industrialisable :

- CLI Python portable `cloudzir-agent` ;
- génération de configuration LiteLLM sans chemins Windows hardcodés ;
- master key locale générée dans `.env` ;
- commande `doctor` pour audit d'environnement ;
- prompts Codex review/critique/task réutilisables ;
- callback Python testé pour réordonner les tool calls Codex ;
- tests unitaires pour éviter les régressions.

## Architecture

```txt
Codex / Codex CLI
      │ model_provider=litellm
      ▼
CloudZIR Agent Runtime CLI
      │ génère config.yaml + secrets locaux
      ▼
LiteLLM Proxy :4000
      │ wildcard "*" + callback tool-order
      ├── DeepSeek Flash / Pro
      ├── NVIDIA DeepSeek / GLM
      └── Hugging Face Qwen
```

## Installation locale

```bash
cd cloudzir-agent-runtime
python -m venv .venv
. .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -e . pytest
cloudzir-agent init --provider deepseek-flash
cloudzir-agent doctor
```

Le runtime utilise `CLOUDZIR_AGENT_HOME` si défini, sinon `~/.cloudzir-agent-runtime`.

## Commandes

```bash
cloudzir-agent models
cloudzir-agent init --provider deepseek-flash
cloudzir-agent generate-config --provider nvidia-glm --output ./config.yaml
cloudzir-agent start-proxy --provider deepseek-flash --port 4000
cloudzir-agent codex review --provider deepseek --repo /path/to/repo
cloudzir-agent codex critique --provider deepseek-pro --base main --repo /path/to/repo
cloudzir-agent codex task --provider hf --prompt "Explique ce module" --repo /path/to/repo
```

## Fenêtres de contexte

| Modèle | Route | Contexte à exposer |
| --- | --- | ---: |
| DeepSeek V4 Flash / Pro | DeepSeek direct via LiteLLM | 1 048 576 tokens |
| DeepSeek V4 Pro | NVIDIA NIM via LiteLLM | 1 048 576 tokens |
| GLM-5.1 | NVIDIA NIM / Z.AI via LiteLLM | 200 000 tokens |
| Qwen3-Coder-Next | Hugging Face via LiteLLM | 262 144 tokens |
| MiniMax M3 `minimax-m3:cloud` | Ollama Cloud natif Codex | jusqu'à 1 048 576 tokens ; minimum garanti 512 000 côté modèle |

Note opérationnelle : sur Ollama local, la fenêtre effective peut être inférieure à la capacité du modèle car Ollama ajuste le contexte par défaut selon la VRAM disponible. Pour des agents de code CloudZIR, vise au minimum 64k tokens et réserve les fenêtres 200k–1M aux tâches repo-wide, RAG long contexte et audits adversariaux.

## Sécurité

- La master key LiteLLM n'est plus codée en dur : elle est générée au premier `init` dans `.env`.
- Les clés providers sont lues depuis `.env` ou variables d'environnement.
- Les secrets ne doivent jamais être commités.
- Pour une équipe CloudZIR, brancher ensuite Windows Credential Manager, macOS Keychain, Secret Service Linux ou Vault.

## Impact CloudZIR / SourireConcept

Cette duplication permet de bâtir un **runtime d'audit et d'automatisation IA low-cost** : reviews sécurité, critiques adversariales, analyse performance, support agents spécialisés, et réduction du coût opérationnel des tâches IA répétitives.

KPIs recommandés : coût par review, bugs détectés avant merge, temps moyen de correction, latence provider, taux d'échec provider, ratio tâches gratuites vs premium.
