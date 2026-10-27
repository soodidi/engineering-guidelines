# Commandes et agents IA

Aide-mémoire de tout ce que Claude Code sait faire dans nos projets (GLB-011). Le détail de chaque commande est dans son `SKILL.md`.

## En un coup d'œil

| Commande | Quand l'utiliser | Exemple | Disponible |
|----------|------------------|---------|------------|
| `/new-project` | Démarrer une nouvelle app | `/new-project` | Partout |
| `/feature` | Développer une fonctionnalité | `/feature 12` | Dans un projet |
| `/fix` | Corriger un bug | `/fix 34` | Dans un projet |
| `/review` | Faire relire une branche ou une PR, sans rien modifier | `/review` ou `/review 42` | Dans un projet |
| `/adr` | Une décision d'architecture n'est couverte par aucun ADR | `/adr file de messages` | Partout |

- **Partout** : commandes globales, installées dans `~/.claude/skills/` par `ai/install.sh`.
- **Dans un projet** : commandes livrées dans le `.claude/` de chaque boilerplate, donc présentes dans toute app créée avec `/new-project`. Lancer Claude Code depuis le dossier du projet.

## Commandes globales

### `/new-project [nom]`

Crée une nouvelle app à partir des boilerplates (GLB-010).

1. Te demande le nom, la description, les briques (web, api, infra, android, ios), l'identifiant d'app mobile, le thème (`clean`, `warm` ou `vivid`, GLB-012) et la visibilité du repo. Récapitule et attend ton « ok ».
2. Copie chaque boilerplate, renomme tout (packages, identifiants, README) et applique le thème choisi.
3. Lance les vérifications du projet.
4. Crée le repo GitHub, avec squash merge et fusion automatique, puis protège `main` (PR obligatoire, CI requise, règles appliquées aussi aux admins).
5. Termine par la liste de ce qui reste à faire à la main : secrets GitHub (il donne les commandes, sans jamais te demander les valeurs), comptes Sentry et Scaleway, ajout du repo dans Renovate.

Source : [`ai/skills/new-project/SKILL.md`](skills/new-project/SKILL.md)

### `/adr <sujet>`

Rédige un brouillon d'ADR quand une décision manque (GLB-001).

1. Vérifie qu'aucun ADR ne couvre déjà le sujet. Sinon, il te le cite, ou propose un ADR qui remplace l'existant.
2. Te demande le contexte et les options, puis te fait **choisir**. L'IA recommande, mais ne tranche pas.
3. Écrit l'ADR à partir de `adr/template.md` : bon préfixe, numéro suivant, statut **Proposé**. Met à jour le README du domaine.
4. Ouvre la PR dans engineering-guidelines et active la fusion automatique.

C'est toi qui passes l'ADR de **Proposé** à **Accepté**.

Source : [`ai/skills/adr/SKILL.md`](skills/adr/SKILL.md)

## Commandes de projet

### `/feature <issue>`

Le cycle complet d'une fonctionnalité, de l'issue à la fusion.

1. **Comprendre** : lit l'issue (`gh issue view`). S'il manque des critères d'acceptation, il les propose. Si le besoin est flou, il te pose une question à la fois et propose 2 ou 3 approches.
2. **Planifier** : l'agent `planner` produit le plan (fichiers, tests, risques). **Tu valides le plan** avant toute ligne de code.
3. **Implémenter** : branche `type/sujet`, petits commits, tests compris, jusqu'à ce que la vérification du projet passe.
4. **Contrôler** : `reviewer` et `qa` en parallèle, plus `security` et `devops` si besoin. Chaque `bloquant:` est corrigé, en deux tours au plus.
5. **Livrer** : ouvre la PR avec la synthèse des contrôles, active la fusion automatique et suit la CI jusqu'à la fusion.

Ton rôle : écrire l'issue, valider le plan, trancher si les agents ne sont pas d'accord.

### `/fix <issue>`

Correction de bug, plus léger que `/feature`.

1. Lit l'issue. Il lui faut le comportement observé, le comportement attendu et un moyen de reproduire.
2. **Cherche la cause** (faits, une hypothèse à la fois) et écrit d'abord un **test qui échoue** à cause du bug.
3. Corrige au plus près de la cause. Si la correction s'étend (plus de 3 fichiers, migration, auth, contrat d'API), il s'arrête et te demande de valider un plan.
4. `reviewer` relit, plus `security` et `devops` si besoin.
5. PR et fusion automatique, comme `/feature`.

Après trois correctifs ratés, il s'arrête et revient vers toi au lieu de s'acharner.

### `/review [PR]`

Relecture sans aucune modification, de la branche courante ou d'une PR.

- `reviewer`, `qa` (sans écrire de tests) et `security` en parallèle, plus `devops` si la CI, Docker ou l'infra changent.
- Une synthèse unique : verdict, puis les points `bloquant:`, puis les suggestions.
- Ne publie rien sur GitHub, sauf si tu le lui demandes ensuite (commentaire sur la PR, corrections).

## Agents

Lancés par `/feature`, `/fix` et `/review`, jamais directement par toi. Ils citent l'ADR derrière chaque remarque et écrivent leur rapport dans `.claude/work/<sujet>/`, qui n'est pas versionné.

| Agent | Rôle | Modifie du code ? |
|-------|------|-------------------|
| `planner` | Transforme l'issue en plan : fichiers, ADR concernés, tests prévus, risques, décisions manquantes | Non |
| `reviewer` | Revue au regard des ADR et de GLB-003, préfixes `bloquant:` / `suggestion:` / `question:` / `nit:`. Une couleur brute est un `bloquant:` (GLB-012) | Non |
| `qa` | Chaque critère d'acceptation a un test, Definition of Done (GLB-009) ; écrit les tests manquants | Tests uniquement |
| `security` | Entrées externes, authentification, données personnelles, secrets, dépendances, infra | Non |
| `devops` | CI GitHub Actions, Docker, OpenTofu, déploiement | Oui, sur ces fichiers |

## Ce qui tourne tout seul

| Mécanisme | Effet |
|-----------|-------|
| Hook `after-edit.sh` | Formate et lint chaque fichier modifié par l'IA (Prettier/ESLint, ktlint via Gradle, SwiftFormat/SwiftLint, `tofu fmt`) et lui renvoie les erreurs à corriger |
| Permissions `.claude/settings.json` | Autorisés sans confirmation : vérifications, branches, commits, PR, fusion automatique. Interdits : push sur `main`, force-push, `--no-verify`, `gh pr merge --admin`, `tofu apply`, lecture des `.env` |
| Fusion automatique | `gh pr merge --squash --auto` : GitHub fusionne quand la CI requise est verte (règle temporaire de GLB-011) |
| Renovate | Mises à jour de dépendances proposées chaque lundi matin (failles de sécurité : à tout moment), fusionnées automatiquement si la CI est verte. Les majeures portent le label `major` |
| `~/.claude/CLAUDE.md` | Règles valables dans tous les projets : où sont les ADR, npm, Conventional Commits, réponses en français, vérifier avant d'annoncer |

## Quelle commande choisir ?

- Une nouvelle app → `/new-project`.
- Un besoin produit, même petit mais qui touche plusieurs fichiers → crée une issue (template « Fonctionnalité »), puis `/feature <n>`.
- Quelque chose ne marche pas → `/fix <n>`, ou `/fix <description>` sans issue.
- Une PR ouverte à la main, ou un doute sur une branche → `/review`.
- « Comment fait-on X ici ? » et aucun ADR ne répond → `/adr <X>`.
- Une typo, un renommage local → demande-le directement, sans commande.

## Où modifier quoi

| Élément | Où le modifier | Puis |
|---------|----------------|------|
| `/new-project`, `/adr`, `CLAUDE.global.md` | `engineering-guidelines/ai/` | `git pull` suffit (liens symboliques). Pour une nouvelle commande : `ai/install.sh` |
| `/feature`, `/fix`, `/review`, agents, hook | `boilerplates/_shared/claude/` | `scripts/sync-shared.sh`, puis reporter à la main dans les apps existantes |
| Permissions | `boilerplates/<stack>/.claude/settings.json` | Reporter dans les apps existantes |
| Règles d'un domaine | `boilerplates/<stack>/AGENTS.md` et l'ADR du domaine | — |
