```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║     C X - F R E E   ·   Codex GRATUIT depuis Claude Code               ║
║     Review & agent de code par DeepSeek / HuggingFace / NVIDIA         ║
║     ───────────────────────────────────────────────────────────       ║
║     Zéro compte OpenAI · Zéro coût · 100 % local (proxy LiteLLM)       ║
║                                                                        ║
╚══════════════════════════════════════════════════════════════════════╝
```

## En une phrase

Tu tapes une commande **dans Claude Code** (ex. `/cx-free-review deepseek`), et c'est **Codex piloté par un LLM gratuit** (DeepSeek, HF ou NVIDIA) qui fait l'analyse — exactement le genre de travail que ferait `/codex:review`, mais **sans ton compte OpenAI** et **sans payer**.

---

## Le problème que ça résout

```
  /codex:review  ──►  reviewer NATIF Codex  ──►  ☁️ OpenAI  ──►  💳 compte payant requis
                                                                  ❌ marche pas en DeepSeek

  /cx-free-review ─►  codex exec -m deepseek ─►  🖥️ proxy LiteLLM :4000  ─►  DeepSeek/HF/NVIDIA
                                                                  ✅ gratuit · ✅ providers libres
```

---

## Les 4 commandes

```
┌──────────────────────────────┬───────────────────────────────────────────────┐
│ COMMANDE                      │ CE QUE ÇA FAIT                                 │
├──────────────────────────────┼───────────────────────────────────────────────┤
│ /cx-free-review   [prov][ref] │ Revue de code complète (= /codex:review)       │
│ /cx-free-critique [prov][ref] │ Revue ADVERSARIALE red-team, cherche le pire   │
│                               │ bug + scénario de repro (= adversarial-review) │
│ /cx-free-task  [prov][--write]│ Toute demande à l'agent (lecture, ou écriture  │
│                <demande>      │ de fichiers avec --write)                      │
│ /cx-free-status               │ Proxy 4000 up/down + modèles servis            │
└──────────────────────────────┴───────────────────────────────────────────────┘
```

**Providers** (`[prov]`) : `deepseek` (défaut) · `deepseek-pro` · `hf` · `nvidia` · `glm`
**Cible review** (`[ref]`) : vide = travail non commité · `main` = ta branche comparée à `main`

---

## Détail des fonctionnalités

### 🔍 `/cx-free-review` — la revue standard
- Analyse le diff git (non commité, ou vs une base) **en lecture seule** (ne touche à rien).
- Lit les fichiers autour du diff pour le contexte.
- Rend : résumé → findings triés par gravité `[CRITIQUE/ÉLEVÉE/MOYENNE/FAIBLE]` avec `fichier:ligne`, problème et correctif → recommandation finale (OK / à corriger / bloquant).
- Couvre : bugs & logique, sécurité (injection, secrets, authz, validation), cas limites, régressions, concurrence, perf, qualité.

### 🥷 `/cx-free-critique` — la revue adversariale
- Posture red-team : **cherche activement le pire bug caché**, comme si un incident de prod en dépendait.
- Donne un **scénario de reproduction concret** par finding.
- Idéal avant un merge sensible (paiement, auth, données).

### 🤖 `/cx-free-task` — l'agent à tout faire
- Envoie n'importe quelle demande : « explique ce module », « écris des tests », « trouve pourquoi X plante »…
- **Lecture seule par défaut** ; ajoute `--write` pour autoriser l'agent à **modifier les fichiers**.

### 📊 `/cx-free-status` — le check rapide
- Dit si le proxy LiteLLM (port 4000) est **UP/DOWN** et quels **modèles** il sert.
- Pratique quand un appel « timeout » : confirme en 1 s si c'est juste le proxy éteint.

---

## Exemples concrets

```bash
/cx-free-review deepseek            # review du travail non commité par DeepSeek
/cx-free-review hf main             # review de ta branche vs main par HuggingFace
/cx-free-task nvidia explique-moi ce que fait ce module
/cx-free-critique deepseek-pro      # revue adversariale par DeepSeek V4 Pro
/cx-free-task deepseek --write ajoute la gestion d'erreur manquante dans api.js
/cx-free-status                     # proxy + modèles dispo
```

---

## Comment ça marche (sous le capot)

```
  Toi (Claude Code)
      │  /cx-free-review hf main
      ▼
  cx-free.ps1  ──(1) allume le proxy si éteint──►  litellm :4000
      │                                                 │
      │  (2) codex exec -c model_provider=litellm        │ route vers
      │       -m hf  --sandbox read-only -o rapport.txt  ▼
      ▼                                            HuggingFace / DeepSeek / NVIDIA
  Codex CLI (agent: git diff, lit les fichiers, raisonne)
      │
      │  (3) rapport final propre
      ▼
  Affiché dans Claude Code
```

> Ce n'est pas branché sur la fenêtre de l'app Codex ouverte : c'est un tour `codex exec` headless sur le **même provider gratuit**. Le résultat est identique.

---

## Démarrage en 30 secondes

```powershell
# 1. Installer (copie commandes + helper + prompts)
pwsh -NoProfile -File "C:\Serveurs\Codex Gratuit\Claude_Commandes\install.ps1"

# 2. Redémarrer Claude Code

# 3. Dans n'importe quel repo :
/cx-free-status
/cx-free-review deepseek
```

**Prérequis** : `codex` CLI + `litellm` installés, et `model_reasoning_effort = "xhigh"` dans `~/.codex/config.toml` (pas `"max"`). Le proxy démarre tout seul au 1ᵉʳ appel.

---

## Bonus : aussi DANS l'app Codex

Le dossier installe aussi 2 slash-commandes **directement dans l'application Codex** (via `~/.codex/prompts/`) :
- `/relire` — revue de code sur le provider actif (DeepSeek/HF/NVIDIA).
- `/relire-critique` — revue adversariale.

Tu les tapes dans l'app Codex elle-même quand tu y es déjà, en complément des `/cx-free-*` côté Claude Code.

---

*Détails techniques & dépannage → `README.md`*
```
Sourire Concept · pont gratuit Codex
```
