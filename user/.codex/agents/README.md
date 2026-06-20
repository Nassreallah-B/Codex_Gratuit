# Agents d'élite Codex (Français)

Une équipe de **15 sous-agents spécialisés** pour **Codex CLI** (multi-agents), taillée pour une stack
Node.js/Express + React/Vike + Supabase/Postgres + Vercel + LLM. La même équipe existe aussi pour
Claude Code (`.claude/agents/*.md`) et Qwen Code (`.qwen/agents/*.md`).

## Installation

1. Copie chaque `*.toml` de ce dossier dans ton dossier d'agents Codex :
   - Windows : `C:\Users\<toi>\.codex\agents\`
   - macOS/Linux : `~/.codex/agents/`
2. Vérifie que le multi-agents est activé dans `~/.codex/config.toml` :
   ```toml
   [features]
   multi_agent = true
   ```
3. Un backend de modèle doit être joignable (ex. ton pont LiteLLM sur `:4000`, ou OpenAI). Si le backend
   est éteint, le dispatch tombera en timeout — c'est un problème de backend, pas d'agent.

## Permissions (sandbox)

Chaque agent déclare un `sandbox_mode` :
- `read-only` — relecteurs/auditeurs (ne peuvent rien modifier).
- `workspace-write` — les 4 « doers » qui éditent (debugger, test-engineer, refactorer, docs-changelog-maintainer).

C'est plus sûr qu'un `danger-full-access` global : un relecteur ne peut physiquement pas écrire.

## Équipe

| Agent | Sandbox | Rôle |
| --- | --- | --- |
| codebase-explorer | read-only | Recherche code/architecture rapide |
| code-reviewer | read-only | Bugs, sécu, conventions sur les changements récents |
| security-auditor | read-only | OWASP, secrets, injection, authz, CVE, RLS |
| debugger | workspace-write | Cause racine d'abord, un seul fix minimal vérifié |
| test-engineer | workspace-write | TDD : écrit et lance les tests, trous de couverture |
| db-migration-reviewer | read-only | Migrations rejouables, schéma, index, RLS |
| performance-optimizer | read-only | Chemins chauds, requêtes, bundle, CWV, fuites |
| refactorer | workspace-write | Code mort, duplication, simplif (comportement inchangé) |
| ai-llm-engineer | read-only | Chaînes de fallback, RAG, anti-hallucination, coût tokens |
| frontend-ux-reviewer | read-only | React/Vike, a11y (WCAG AA), SEO, CWV, i18n |
| deployment-release-engineer | read-only | Env vars, build, CI (consultatif — ne déploie jamais) |
| backend-api-reviewer | read-only | Validation, erreurs, authz, idempotence, rate-limit |
| compliance-rgpd-auditor | read-only | RGPD art.15/17, isolation tenant, cosmétique UE |
| integration-resilience-reviewer | read-only | Webhooks, timeouts, retries, idempotence |
| docs-changelog-maintainer | workspace-write | Met la doc/le changelog en accord avec la réalité |

## Utilisation

Dans une session `codex`, demande-lui d'utiliser un agent par son nom — ex. *« utilise l'agent
security-auditor sur lib/ »* — ou laisse Codex déléguer automatiquement selon la description de chaque agent.

Chaque agent suit des règles anti-hallucination : chaque finding cite `fichier:ligne` + preuve réelle, la
sévérité colle à la preuve, les comptes se mesurent (pas de devinette), et les correctifs proposés pour les
findings à forte sévérité sont marqués « non testé ».
