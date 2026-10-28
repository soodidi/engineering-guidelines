# Configuration IA commune

Ce dossier contient la configuration Claude Code commune à **tous** les projets (GLB-011). Elle s'installe dans le **dossier racine** (celui qui contient `engineering-guidelines`, `boilerplates` et `shared-libs`), et non dans `~/.claude` : elle reste ainsi à l'écart des autres projets du poste. Claude Code charge `<racine>/CLAUDE.md` dans toute session lancée dans `<racine>` ou en dessous, mais `<racine>/.claude/` (skills, `settings.json`) **seulement** dans une session lancée dans `<racine>` même : un projet en dessous est son propre repo git et n'en hérite pas. D'où :

- les commandes communes (`/new-project`, `/upstream <app>`, `/adr`) se lancent depuis `<racine>` ;
- les plugins utiles à un projet sont activés dans le `.claude/settings.json` versionné de chaque boilerplate, et suivent l'app à sa création. La configuration propre à un projet (agents, `/feature`, `/fix`, `/review`, hooks, permissions) vit dans le `.claude/` de chaque boilerplate.

**Aide-mémoire de toutes les commandes et agents : [COMMANDES.md](COMMANDES.md).**

| Fichier | Installé dans | Rôle |
|---------|---------------|------|
| `CLAUDE.global.md` | `<racine>/CLAUDE.md` | Où trouver les guidelines, façon de travailler |
| `skills/new-project/` | `<racine>/.claude/skills/new-project` | Commande `/new-project` : crée un projet depuis un boilerplate |
| `skills/upstream/` | `<racine>/.claude/skills/upstream` | Commande `/upstream` : remonte dans les boilerplates les améliorations génériques d'une app (GLB-010) |
| `skills/adr/` | `<racine>/.claude/skills/adr` | Commande `/adr <sujet>` : brouillon d'ADR et PR dans ce repo quand une décision manque (GLB-001) |

## Installation

Depuis le dossier racine :

```bash
engineering-guidelines/ai/install.sh
```

Le script crée des liens symboliques relatifs : un `git pull` du repo met la configuration à jour, et le dossier racine peut être déplacé. Un `<racine>/CLAUDE.md` existant qui n'est pas un lien est sauvegardé à côté avant d'être remplacé ; reporte ce qu'il contenait d'utile dans `CLAUDE.global.md`. Une ancienne copie réelle d'un skill est déplacée dans `<racine>/.claude/backup-<date>/`, hors de `skills/`. Les liens des skills retirés du repo sont supprimés. Les réglages des sessions lancées depuis `<racine>` (plugins, par exemple) vont dans `<racine>/.claude/settings.json`, hors des repos.
