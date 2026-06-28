# ollama-launch-models.json — Référence

**Emplacement** : `C:\Users\<user>\.codex\ollama-launch-models.json`

**Rôle** : Catalogue des modèles connus de l'application Codex. Codex lit ce fichier pour connaître le `context_window` de chaque modèle. Sans entrée correcte, le contexte tombe à **65 536 tokens** par défaut.

---

## Structure générale

```json
{
  "models": [
    {
      "slug": "identifiant-unique",
      "display_name": "Nom affiché dans Codex",
      "context_window": 1048576,
      "max_context_window": 1048576,
      "effective_context_window_percent": 95,
      "input_modalities": ["text"],
      "supports_parallel_tool_calls": true,
      ...
    },
    ...
  ]
}
```

Les champs clés pour le contexte sont `context_window` et `max_context_window`.

---

## Entrées LiteLLM (DeepSeek / NVIDIA / HuggingFace)

Ces 5 entrées sont **indispensables** au bon fonctionnement du lanceur. Si une màj de Codex les efface, il faut les remettre.

### 1. deepseek-flash

```json
{
  "slug": "deepseek-flash",
  "display_name": "DeepSeek V4 Flash",
  "description": "DeepSeek V4 Flash via LiteLLM",
  "context_window": 1048576,
  "max_context_window": 1048576,
  "effective_context_window_percent": 95,
  "input_modalities": ["text"],
  "supports_parallel_tool_calls": true,
  "supports_reasoning_summaries": false,
  "supports_search_tool": false,
  "supported_in_api": true,
  "visibility": "list",
  "priority": 100,
  "shell_type": "default",
  "support_verbosity": false,
  "supports_image_detail_original": false,
  "supported_reasoning_levels": [],
  "experimental_supported_tools": [],
  "additional_speed_tiers": [],
  "truncation_policy": { "limit": 10000, "mode": "bytes" },
  "default_reasoning_summary": "auto",
  "auto_compact_token_limit": null,
  "apply_patch_tool_type": null,
  "availability_nux": null,
  "base_instructions": null,
  "default_reasoning_level": null,
  "default_verbosity": null,
  "model_messages": null,
  "upgrade": null,
  "web_search_tool_type": "text"
}
```

### 2. deepseek-pro

Mêmes valeurs que `deepseek-flash`, seul le slug et le display_name changent :
- `"slug": "deepseek-pro"`
- `"display_name": "DeepSeek V4 Pro"`
- `"description": "DeepSeek V4 Pro via LiteLLM"`
- `"context_window": 1048576`
- `"max_context_window": 1048576`

### 3. nvidia-deepseek

- `"slug": "nvidia-deepseek"`
- `"display_name": "NVIDIA DeepSeek V4 Pro"`
- `"description": "NVIDIA DeepSeek V4 Pro via LiteLLM"`
- `"context_window": 1048576`
- `"max_context_window": 1048576`

### 4. nvidia-glm

- `"slug": "nvidia-glm"`
- `"display_name": "NVIDIA GLM-5.1"`
- `"description": "NVIDIA GLM-5.1 via LiteLLM"`
- `"context_window": 200000`
- `"max_context_window": 200000`

### 5. hf

- `"slug": "hf"`
- `"display_name": "HuggingFace Qwen3 Coder Next"`
- `"description": "HuggingFace Qwen3 via LiteLLM"`
- `"context_window": 262144`
- `"max_context_window": 262144`

---

## Vérification après màj Codex

1. Ouvre `C:\Users\<user>\.codex\ollama-launch-models.json`
2. Cherche les slugs : `deepseek-flash`, `deepseek-pro`, `nvidia-deepseek`, `nvidia-glm`, `hf`
3. Vérifie que leur `context_window` n'est pas `65536`
4. Si absents ou incorrects : restaure depuis ce document

## Sauvegardes automatiques

Codex crée parfois des `.bak` avant modification :
```
ollama-launch-models.json.bak
ollama-launch-models.json.20260616*.bak
```
