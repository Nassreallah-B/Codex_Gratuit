# Claude_Commandes — Pont gratuit Claude Code ↔ Codex (DeepSeek / HF / NVIDIA)

Des slash-commandes **dans Claude Code** qui font faire le travail (review de code, tâche d'agent) par **Codex tournant sur un provider GRATUIT** (DeepSeek via proxy LiteLLM, HuggingFace, NVIDIA) — **sans utiliser ton compte OpenAI**.

> Pourquoi : `/codex:review` natif n'utilise QUE le reviewer OpenAI (compte payant). Ces commandes lancent à la place `codex exec` forcé sur un provider gratuit, via le proxy LiteLLM local (port 4000).

## Commandes disponibles

| Commande | Rôle |
| --- | --- |
| `/cx-free-review [provider] [base-ref]` | Revue de code (équivalent gratuit de `/codex:review`). |
| `/cx-free-critique [provider] [base-ref]` | Revue **adversariale** red-team (équivalent de `/codex:adversarial-review`). |
| `/cx-free-task [provider] [--write] <demande>` | N'importe quelle demande à l'agent Codex (`--write` = autorise modif de fichiers). |
| `/cx-free-status` | État du proxy LiteLLM (port 4000) + providers disponibles. |

**Providers** : `deepseek` (défaut), `deepseek-pro`, `hf`, `nvidia`, `glm`.
**Cible review** : sans `base-ref` → travail non commité ; avec `base-ref` (ex. `main`) → branche vs base.

### Exemples

```
/cx-free-review deepseek            → review du travail non commité par DeepSeek
/cx-free-review hf main             → review de ta branche vs main par HuggingFace
/cx-free-task nvidia explique-moi ce que fait ce module
/cx-free-critique deepseek-pro      → revue adversariale par DeepSeek V4 Pro
/cx-free-status                     → proxy up/down + modèles servis
```

## Installation / réintégration

```powershell
pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"
```

L'installeur copie :
- `commands\*.md` → `~/.claude/commands/`  (slash-commandes `/cx-free-*`)
- `scripts\cx-free.ps1` → `~/.claude/scripts/`  (le moteur)
- `prompts\*.md` → `~/.codex/prompts/`  (bonus : `/relire` et `/relire-critique` **dans l'app Codex** elle-même)

Redémarre Claude Code après installation pour voir les commandes.

## Prérequis

- **Codex CLI** (`codex`) installé et connecté (login OpenAI sert juste de garde ; les appels LLM partent sur le provider gratuit).
- **litellm** installé (`uv tool install litellm`).
- Le **proxy LiteLLM** du projet `C:\Serveurs\Codex Gratuit\litellm-codex` (clés dans son `.env`). Le helper le démarre tout seul sur le port 4000 si éteint.
- `~/.codex/config.toml` : `model_reasoning_effort` doit valoir `"xhigh"` (PAS `"max"`, supprimé depuis codex-cli 0.118.0, sinon `codex exec` refuse la config).

## Fonctionnement (sous le capot)

`/cx-free-*` → `cx-free.ps1` qui :
1. s'assure que le proxy LiteLLM (port 4000) tourne (le démarre sinon) ;
2. lance `codex exec -c model_provider=litellm -m <modèle> --sandbox <ro|write> -o <fichier>` → l'agent Codex tourne sur le provider gratuit choisi (via le proxy) ;
3. renvoie le rapport final propre (le bruit MCP/skills est filtré).

> Ça n'attache pas à la fenêtre de l'app Codex ouverte : ça lance un tour `codex exec` headless sur le même provider gratuit. Le résultat (DeepSeek/HF/NVIDIA fait l'analyse) est identique.

## Dépannage

- **`/cx-free-status` dit DOWN** → normal si tu n'as rien lancé ; le 1er `/cx-free-*` démarre le proxy.
- **« proxy 4000 indisponible »** → vérifier `litellm` installé + les clés dans `C:\Serveurs\Codex Gratuit\litellm-codex\.env`. Test manuel : `pwsh -File "C:\Serveurs\Codex Gratuit\litellm-codex\start-litellm.ps1"`.
- **`unknown variant 'max'`** → mettre `model_reasoning_effort = "xhigh"` dans `~/.codex/config.toml`.
- **Erreurs MCP (supabase/render) dans les logs** → sans effet sur le résultat (échec rapide en headless), le rapport final reste propre.

## Contenu du dossier

```
Claude_Commandes/
├── README.md            (ce fichier — technique & dépannage)
├── PRESENTATION.md      (présentation visuelle des fonctionnalités)
├── install.ps1          (installe les commandes + helper + prompts)
├── commands/            (slash-commandes Claude Code)
│   ├── cx-free-review.md
│   ├── cx-free-critique.md
│   ├── cx-free-task.md
│   └── cx-free-status.md
├── scripts/
│   └── cx-free.ps1      (le moteur)
└── prompts/             (bonus : slash-commandes DANS l'app Codex)
    ├── relire.md
    └── relire-critique.md
```
