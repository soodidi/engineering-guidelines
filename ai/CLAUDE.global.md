# Instructions globales (tous les projets)

Fichier installé dans `~/.claude/CLAUDE.md` par `ai/install.sh` du repo engineering-guidelines. Le modifier dans ce repo, pas dans `~/.claude`.

## Guidelines

- Les règles de code sont les ADR du repo **engineering-guidelines**, cloné dans `~/Documents/projects/engineering-guidelines` (<https://github.com/soodidi/engineering-guidelines>).
- Dans un projet, lire d'abord son `AGENTS.md`, puis `adr/global/README.md` et le README du domaine dans engineering-guidelines. Ouvrir l'ADR détaillé seulement si besoin.
- ADR **Accepté** : appliquer sans demander. **Proposé** : suivre, mais signaler ce qui pose problème. Une décision non couverte : proposer un brouillon d'ADR plutôt que trancher seul.
- Gestionnaire de paquets : **npm** (jamais pnpm ni yarn). Commits en Conventional Commits, en anglais.

## Façon de travailler

- Une fonctionnalité suit GLB-011 : `/feature <issue>` (plan validé par moi, code, vérification, agents de contrôle, PR). Je relis et je fusionne : ne jamais fusionner une PR, forcer un push ou lancer une action irréversible à ma place.
- Un nouveau projet part d'un boilerplate via `/new-project`, jamais de `create-vite`, `nest new` ou équivalent sans me le signaler.
- Me parler en français, de façon concise. Code, noms et commentaires en anglais ; docs et ADR en français (GLB-007).
