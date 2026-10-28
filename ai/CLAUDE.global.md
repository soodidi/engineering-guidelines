# Instructions communes (tous les projets)

Fichier relié en `<racine>/CLAUDE.md` par `ai/install.sh` du repo engineering-guidelines. Le modifier dans ce repo, pas à travers le lien.

## Guidelines

- **Dossier racine** : le dossier qui contient ce `CLAUDE.md`. Les repos `engineering-guidelines`, `boilerplates` et `shared-libs` y sont clonés côte à côte, et `/new-project` y crée les nouveaux projets. Dans les skills et les agents, `<racine>` désigne ce dossier. Aucun chemin absolu n'est codé en dur : chaque poste choisit le sien. Ce fichier vaut pour toute session lancée dans `<racine>` ou en dessous ; les skills communs (`/new-project`, `/upstream`, `/adr`) ne sont chargés que dans une session lancée dans `<racine>` même.
- Les règles de code sont les ADR du repo **engineering-guidelines**, dans `<racine>/engineering-guidelines` (<https://github.com/soodidi/engineering-guidelines>).
- Dans un projet, lire d'abord son `AGENTS.md`, puis `adr/global/README.md` et le README du domaine dans engineering-guidelines. Ouvrir l'ADR détaillé seulement si besoin.
- ADR **Accepté** : appliquer sans demander. **Proposé** : suivre, mais signaler ce qui pose problème. Une décision non couverte : proposer un brouillon d'ADR avec `/adr` plutôt que trancher seul.
- Gestionnaire de paquets : **npm** (jamais pnpm ni yarn). Commits en Conventional Commits, en anglais.

## Façon de travailler

- Une fonctionnalité suit GLB-011 : `/feature <issue>` (plan validé par moi, code, vérification, agents de contrôle, PR). Un bug suit `/fix <issue>` : test qui reproduit le bug d'abord. Une fois la PR ouverte, active la fusion automatique (`gh pr merge --squash --auto --delete-branch`) sans m'attendre : GitHub fusionne quand la CI est verte. Jamais de `--admin`, de force-push, ni d'action irréversible hors fusion (`tofu apply`, migration de production, secrets) à ma place.
- Ne jamais écrire qu'un travail est fini, corrigé ou testé sans avoir lancé la vérification et cité son résultat.
- Un nouveau projet part d'un boilerplate via `/new-project`, jamais de `create-vite`, `nest new` ou équivalent sans me le signaler.
- Au démarrage d'un projet et avant son premier déploiement, me rappeler la checklist `engineering-guidelines/docs/checklist-nouveau-projet.md` (ou l'issue « Mise en route » du repo) et ce qui n'y est pas encore coché.
- Un chantier en cours se suit dans `engineering-guidelines/docs/suivi/` (`HANDOFF.md`, `PLAN-SUITE.md`) : des documents temporaires, à effacer une fois le chantier terminé, qui fluidifient le travail entre les postes et entre les instances d'IA ; s'ils existent et que je demande de reprendre, les lire d'abord, et les tenir à jour par PR à la fin de chaque tâche. Installation d'une machine : `engineering-guidelines/docs/poste-de-travail.md` ; tout outil ou plugin ajouté y est reporté.
- Me parler en français, de façon concise. Code, noms et commentaires en anglais ; docs et ADR en français (GLB-007).
