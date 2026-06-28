# config.toml — Référence

**Emplacement** : `C:\Users\<user>\.codex\config.toml`

**Rôle** : Configuration principale de l'application Codex. Contient le modèle actif, les fournisseurs, les profils, les serveurs MCP, les plugins, et les options de sandbox.

⚠️ Ce fichier est modifié **automatiquement** par `codex-launch.ps1` à chaque lancement via le menu.

---

## Sections essentielles

### Entête — modèle et fournisseur actifs

```toml
model = "deepseek-flash"          # ← modifié par le lanceur (Set-Default)
model_reasoning_effort = "xhigh"  # "max" supprimé depuis codex-cli 0.118.0
personality = "pragmatic"
model_provider = "litellm"        # ← modifié par le lanceur (Set-Default)
sandbox_mode = "danger-full-access"
```

### Catalogue des modèles

```toml
model_catalog_json = "C:\\Users\\<user>\\.codex\\ollama-launch-models.json"
```

Ce fichier **DOIT** exister et contenir les entrées LiteLLM (voir `ollama-launch-models.json.md`).

### Notifications

```toml
notify = [
  "<path-codex>\\codex-computer-use.exe",
  "turn-ended"
]
```

### Projets de confiance

```toml
[projects.'C:\\Serveurs\\Codex Gratuit']
trust_level = "trusted"
```

Chaque dossier projet utilisé avec Codex doit être listé ici. Le lanceur n'y touche pas.

---

## Fournisseurs de modèles

### OpenAI (ton compte)

```toml
[profiles.openai]
model = "gpt-5-codex"
model_provider = "openai"
```

Pas de proxy requis — connexion directe à OpenAI.

### Ollama local

```toml
[model_providers.ollama-launch-codex-app]
name = "Ollama"
base_url = "http://127.0.0.1:11434/v1/"
wire_api = "responses"

[profiles.local]
model = "cc-ollama"
model_provider = "ollama-launch-codex-app"
```

### Ollama cloud

```toml
[profiles.cloud]
model = "minimax-m3:cloud"
model_provider = "ollama-launch-codex-app"
```

Nécessite `ollama signin` préalable.

### LiteLLM — pont pour DeepSeek / NVIDIA / HuggingFace

```toml
[model_providers.litellm]
name = "LiteLLM"
base_url = "http://localhost:4000/v1/"
wire_api = "responses"
env_key = "LITELLM_KEY"
model_catalog_json = "C:\\Serveurs\\Codex Gratuit\\litellm-codex\\litellm-models.json"

```

> ⚠️ **Le lanceur ne switche PAS via des profils.** `Set-Default` ([codex-launch.ps1](codex-launch.ps1)) réécrit directement l'entête `model` / `model_provider` (voir plus haut) à chaque lancement. Les noms de modèles valides — qui doivent matcher le `model_list` de `litellm-codex/config.yaml` et les slugs de `litellm-models.json` — sont : `deepseek-flash`, `deepseek-pro`, `nvidia-deepseek`, `nvidia-glm`, `hf`. Exemple écrit pour le choix 1 :
>
> ```toml
> model = "deepseek-flash"
> model_provider = "litellm"
> ```

---

## Serveurs MCP

### Serveur interne node_repl (NE JAMAIS SUPPRIMER)

```toml
[mcp_servers.node_repl]
args = []
command = "<path-codex>\\node_repl.exe"
startup_timeout_sec = 120

[mcp_servers.node_repl.env]
NODE_REPL_NATIVE_PIPE_CONNECT_TIMEOUT_MS = "1000"
NODE_REPL_NODE_MODULE_DIRS = "<path-codex>\\node_modules"
NODE_REPL_NODE_PATH = "<path-codex>\\node.exe"
NODE_REPL_TRUSTED_CODE_PATHS = "C:\\Users\\<user>\\.codex"
CODEX_HOME = "C:\\Users\\<user>\\.codex"
BROWSER_USE_AVAILABLE_BACKENDS = "chrome,iab"
BROWSER_USE_CODEX_APP_BUILD_FLAVOR = "prod"
SKY_CUA_NATIVE_PIPE = "1"
CODEX_CLI_PATH = "<path-codex>\\codex.exe"
# + autres variables d'env générées par Codex
```

Ce bloc est **géré par Codex** — ne pas modifier manuellement.

### Serveurs MCP externes (gérés par le lanceur)

```toml
[mcp_servers.playwright]
args = ["@playwright/mcp@latest"]
command = "npx"

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"

[mcp_servers.supabase_<projet>]
url = "https://mcp.supabase.com/mcp?project_ref=<ref>&read_only=true"

[mcp_servers.render]
url = "https://mcp.render.com/mcp"
[mcp_servers.render.headers]
Authorization = "Bearer <token>"
```

**Important** : les serveurs MCP externes restent **actifs pour tous les choix du menu (1→7)**. `mcp-backup.toml` est une sauvegarde manuelle (filet de secours) ; le lanceur ne les coupe plus automatiquement. La fonction `Strip-MCP` existe encore dans `codex-launch.ps1` mais n'est plus déclenchée.

---

## Plugins

```toml
[plugins."<nom-du-plugin>"]
enabled = true
```

Les plugins sont listés sous `[plugins."..."]`. Le lanceur n'y touche pas.

---

## Marketplaces

```toml
[marketplaces.openai-codex]
last_updated = "<date>"
last_revision = "<commit-hash>"
source_type = "git"
source = "https://github.com/openai/codex-plugin-cc.git"
```

Gérées par Codex, pas besoin d'y toucher.

---

## Desktop

```toml
[desktop]
appearanceLightCodeThemeId = "codex"
localeOverride = "fr-FR"
show-context-window-usage = true
hotkey-window-projectless-default-enabled = true
```

---

## Restauration après màj Codex

Si une mise à jour de Codex écrase `config.toml` :

1. **Restaurer le modèle actif** : `model = "deepseek-flash"` + `model_provider = "litellm"`
2. **Vérifier `model_catalog_json`** pointe bien vers `ollama-launch-models.json`
3. **Vérifier `[model_providers.litellm]`** est présent
4. **Vérifier `model_reasoning_effort = "xhigh"`** (la valeur `"max"` est invalide depuis codex-cli 0.118.0)
5. **Vérifier `sandbox_mode = "danger-full-access"`**
6. **Vérifier les `[mcp_servers.*]`** externes sont présents (ou les restaurer depuis `mcp-backup.toml`)
7. **Vérifier les `[projects.*]`** de confiance
8. **Vérifier les `[plugins.*]`** activés

Le lanceur gère automatiquement le point 1 (`Set-Default`). Les serveurs MCP (point 6) ne sont **plus coupés automatiquement** — restaure-les manuellement depuis `mcp-backup.toml` si une màj Codex les efface.
