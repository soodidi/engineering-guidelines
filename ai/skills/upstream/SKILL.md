---
name: upstream
description: Compare une app à son boilerplate d'origine, repère les améliorations génériques apparues dans l'app (outillage, config, CI, kit IA, socle technique) et les remonte dans le repo boilerplates par PR (GLB-010). À lancer depuis le dossier racine avec le nom de l'app, ex. /upstream monapp-web.
argument-hint: '<dossier de l''app sous la racine>'
disable-model-invocation: true
---

App à comparer : `<racine>/$ARGUMENTS` (demande le nom si vide)

Les boilerplates sont dans `<racine>/boilerplates` (`<racine>` : le dossier racine, défini dans le `CLAUDE.md` commun). Le skill se lance depuis `<racine>` (les skills communs ne sont chargés que là) : exécute les commandes sur l'app dans son dossier (`git -C <racine>/<app>`, chemins préfixés). Travaille dans `.claude/work/upstream/` de l'app (non versionné). Tu ne modifies **jamais** l'app elle-même dans ce skill.

## 1. Retrouver l'origine

- Lis `.boilerplate.json` à la racine de l'app : `boilerplate` (nom du dossier), `commit` (commit du repo boilerplates au moment de la copie), `renames` (remplacements faits à la création, ex. `"web-react-vite": "monapp-web"`).
- S'il n'existe pas (app créée avant ce fichier) : déduis le boilerplate de la stack, prends comme base le dernier commit de boilerplates antérieur au premier commit de l'app (`git log --reverse --format=%cI | head -1`, puis `git -C <racine>/boilerplates rev-list -1 --before=<date> main`) et signale à l'humain que la base est estimée.
- `git -C <racine>/boilerplates pull --ff-only`.
- Extrais le boilerplate à la base et à `main` :
  - `git -C <racine>/boilerplates archive <commit> <boilerplate> | tar -x -C .claude/work/upstream/base`
  - `git -C <racine>/boilerplates archive main <boilerplate> | tar -x -C .claude/work/upstream/head`

## 2. Lister ce qui a divergé

Compare l'app à `base` (ce que l'app a changé depuis la copie) **en appliquant d'abord les `renames` à l'envers** sur la copie de travail de la comparaison, pour ne pas voir les renommages comme des différences.

Regarde uniquement le **socle générique** :

- configuration des outils (lint, format, TypeScript, Gradle, SwiftLint/SwiftFormat, Vite, Vitest, Playwright, Docker, lefthook) ;
- CI et workflows (`.github/`), templates d'issue et de PR ;
- kit IA (`.claude/agents`, `.claude/skills`, `.claude/hooks`, `.claude/settings.json`) et `AGENTS.md` ;
- socle technique partagé : client HTTP, gestion d'erreurs, config d'environnement, logs, i18n (mécanisme, pas les textes), design system, setup de tests, scripts.

Ignore : le code des features métier, les textes, les identifiants de l'app, le README produit, les fichiers générés (thème GLB-012 : ils viennent de `@soodidi/design-tokens`), les lockfiles et les montées de version de dépendances (Renovate s'en charge des deux côtés).

Pour chaque fichier modifié, compare aussi avec `head` : si le boilerplate a déjà fait le même changement, ou mieux, écarte-le.

## 3. Trier

Classe chaque divergence :

| Catégorie | Exemple | Suite |
|-----------|---------|-------|
| **À remonter** | Règle de lint utile, correctif du client HTTP, job CI plus rapide, meilleure consigne d'agent | Proposée pour boilerplates |
| **Propre à l'app** | Config liée à un service que seule cette app utilise | Ignorée |
| **Dérive à signaler** | Règle de lint désactivée, test supprimé, contournement d'un ADR sans commentaire `Dérogation` | Signalée à l'humain, jamais remontée |

Une divergence **à remonter** doit être une amélioration démontrable (bug corrigé, règle d'ADR mieux appliquée, temps de CI réduit, erreur évitée) et rester générique une fois les noms de l'app retirés. En cas de doute, classe-la à part avec une question.

Écris `.claude/work/upstream/rapport.md`, puis présente à l'humain un tableau court : fichier, changement en une ligne, catégorie, justification, autres boilerplates concernés (ex. une config Vitest partagée par `web-react-vite` et `api-nestjs`). Mets les **dérives** en premier. **Attends qu'il choisisse** ce qui remonte.

## 4. Remonter

Pour chaque sujet retenu (un sujet = une PR, GLB-003) :

- Dans boilerplates : `git switch main && git pull`, puis `git switch -c <type>/upstream-<sujet>`.
- Applique le changement en le **généralisant** : noms du boilerplate, pas de l'app ; aucune donnée propre à l'app. Si c'est le kit IA, modifie `_shared/` puis `scripts/sync-shared.sh`. Si d'autres boilerplates sont concernés, applique-le aussi chez eux ou explique pourquoi non.
- Lance la vérification de chaque boilerplate touché (commande dans son `AGENTS.md`) et cite le résultat.
- Commit Conventional Commits en anglais, `git push -u origin <branche>`, `gh pr create` en indiquant l'app d'origine et le gain attendu, puis `gh pr merge <n> --squash --auto --delete-branch` (jamais `--admin`). Suis la CI ; si elle échoue, corrige.
- Si le changement relève d'un ADR qui n'existe pas encore, arrête-toi et propose `/adr` au lieu de remonter.

## 5. Terminer

Récapitule : PR ouvertes ou fusionnées (liens), divergences ignorées, et les **dérives** signalées avec la correction suggérée dans l'app (à faire avec `/fix` ou `/feature` dans l'app, pas dans ce skill).
