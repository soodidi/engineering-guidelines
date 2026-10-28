# Configuration IA globale

Ce dossier contient la configuration Claude Code commune à **tous** les projets (GLB-011). Elle s'installe dans le **dossier de travail** (celui qui contient `engineering-guidelines`, `boilerplates` et `shared-libs`), et non dans `~/.claude` : elle ne s'applique qu'aux sessions lancées dans ce dossier, ce qui la garde à l'écart des autres projets du poste. La configuration propre à un projet (agents, `/feature`, `/fix`, `/review`, hooks, permissions) vit dans le `.claude/` de chaque boilerplate.

**Aide-mémoire de toutes les commandes et agents : [COMMANDES.md](COMMANDES.md).**

| Fichier | Installé dans | Rôle |
|---------|---------------|------|
| `CLAUDE.global.md` | `<racine>/CLAUDE.md` | Où trouver les guidelines, façon de travailler |
| `skills/new-project/` | `<racine>/.claude/skills/new-project` | Commande `/new-project` : crée un projet depuis un boilerplate |
| `skills/upstream/` | `<racine>/.claude/skills/upstream` | Commande `/upstream` : remonte dans les boilerplates les améliorations génériques d'une app (GLB-010) |
| `skills/adr/` | `<racine>/.claude/skills/adr` | Commande `/adr <sujet>` : brouillon d'ADR et PR dans ce repo quand une décision manque (GLB-001) |

## Installation

Depuis le dossier de travail :

```bash
engineering-guidelines/ai/install.sh
```

Le script crée des liens symboliques relatifs : un `git pull` du repo met la configuration à jour, et le dossier de travail peut être déplacé. Un `<racine>/CLAUDE.md` existant qui n'est pas un lien est sauvegardé à côté avant d'être remplacé ; reporte ce qu'il contenait d'utile dans `CLAUDE.global.md`. Les réglages propres au dossier (plugins activés) vont dans `<racine>/.claude/settings.json`, hors des repos.
