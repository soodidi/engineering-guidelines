# Configuration IA globale

Ce dossier contient la configuration Claude Code commune à **tous** les projets (GLB-011). La configuration propre à un projet (agents, `/feature`, `/fix`, `/review`, hooks, permissions) vit dans le `.claude/` de chaque boilerplate.

| Fichier | Installé dans | Rôle |
|---------|---------------|------|
| `CLAUDE.global.md` | `~/.claude/CLAUDE.md` | Où trouver les guidelines, façon de travailler |
| `skills/new-project/` | `~/.claude/skills/new-project` | Commande `/new-project` : crée un projet depuis un boilerplate |
| `skills/adr/` | `~/.claude/skills/adr` | Commande `/adr <sujet>` : brouillon d'ADR et PR dans ce repo quand une décision manque (GLB-001) |

## Installation

```bash
~/Documents/projects/engineering-guidelines/ai/install.sh
```

Le script crée des liens symboliques : un `git pull` du repo met la configuration à jour. Un `~/.claude/CLAUDE.md` existant est sauvegardé à côté avant d'être remplacé ; reporte ce qu'il contenait d'utile dans `CLAUDE.global.md`.
