# GLB-011 : Développement avec l'IA et agents spécialisés

- **Statut** : Proposé
- **Date** : 2026-10-27
- **Périmètre** : global
- **Auteurs** : Mo, Claude
- **Liens** : GLB-003, GLB-004, GLB-009, GLB-010

## Contexte

L'essentiel du code sera écrit par une IA (Claude Code). Une IA produit vite et beaucoup, mais elle oublie les règles qu'elle n'a pas sous les yeux, valide son propre travail avec indulgence et peut prendre des initiatives difficiles à rattraper (force-push, migration, `apply` d'infra). Les ADR ne servent que si l'IA les lit au bon moment et si des contrôles indépendants vérifient le résultat.

## Décision

### Cycle de travail

Toute fonctionnalité suit le même cycle, lancé par la commande `/feature` :

1. **Issue** : le besoin est décrit dans une issue GitHub (template « Feature ») avec des **critères d'acceptation vérifiables** et ce qui est hors périmètre. Si l'issue est floue, l'IA **cadre** d'abord avec l'humain : une question à la fois, puis deux ou trois approches avec leurs compromis et sa recommandation, avant tout plan.
2. **Plan** : l'agent `planner` produit un plan (fichiers touchés, ADR concernés, tests prévus, risques). Un humain **DOIT** valider le plan avant le code, sauf changement trivial (typo, renommage local).
3. **Code** : la session principale implémente sur une branche `type/sujet` (GLB-002), par petites étapes, tests compris. La vérification du projet (`npm run verify` ou équivalent indiqué dans `AGENTS.md`) **DOIT** passer.
4. **Contrôles** : les agents spécialisés relisent en parallèle (voir ci-dessous). Les remarques `bloquant:` **DOIVENT** être corrigées.
5. **PR et fusion** : l'IA ouvre la PR (template GLB-003) avec le lien de l'issue et la synthèse des contrôles, puis active la **fusion automatique** (`gh pr merge --squash --auto --delete-branch`) s'il ne reste aucun `bloquant:`. GitHub fusionne seul quand les checks requis sont verts. Si la CI échoue, l'IA lit le log, corrige et pousse, dans la limite de deux tentatives ; au-delà, elle s'arrête et explique.

### Agents spécialisés

| Agent | Rôle | Écrit du code ? |
|-------|------|-----------------|
| Session principale (dev) | Orchestre le cycle et implémente | Oui |
| `planner` | Transforme une issue en plan, repère les ADR et les décisions manquantes | Non |
| `reviewer` | Revue de code au regard des ADR (GLB-003), préfixes `bloquant:` / `suggestion:` / `question:` / `nit:` | Non |
| `qa` | Vérifie la couverture des critères d'acceptation, la Definition of Done (GLB-009), écrit les tests manquants | Tests uniquement |
| `security` | Secrets, entrées externes, authentification, dépendances (GLB-005, BE-006) | Non |
| `devops` | CI, Docker, infrastructure, déploiement (OPS-001 à OPS-007) | Oui, sur ces fichiers |

- Les agents **DOIVENT** s'appuyer sur les ADR : chaque remarque cite l'ADR concerné. Une remarque sans règle derrière est au mieux une `suggestion:`.
- `security` n'intervient que si le changement touche une entrée externe, l'authentification, des données personnelles, des dépendances ou l'infrastructure. `devops` n'intervient que si la CI, Docker ou l'infra changent.
- Les agents de contrôle n'ont pas accès en écriture au code de production : ils ne valident pas un travail qu'ils auraient eux-mêmes modifié.

### Communication entre agents

- La session principale est le **seul chef d'orchestre** : elle lance les agents, leur transmet le contexte et arbitre. Les agents ne s'appellent pas entre eux.
- Les échanges passent par des **fichiers de passation** dans `.claude/work/<sujet>/` (non versionné) : `plan.md`, `review.md`, `qa.md`, `security.md`, `devops.md`. Chaque agent lit les rapports déjà produits avant d'écrire le sien.
- Quand un agent soulève un point qui relève d'un autre (ex. le `reviewer` repère une donnée sensible), il le signale dans son rapport ; la session principale sollicite l'agent concerné.
- Au plus **deux allers-retours** correction / contrôle. Au-delà, ou en cas de désaccord entre agents, la décision remonte à l'humain.
- La synthèse finale (points corrigés, points ouverts) est recopiée dans la description de la PR : c'est la trace durable.

### Cadrage de l'IA

- Chaque projet contient un `AGENTS.md` (règles du domaine à appliquer sans demander) et un `CLAUDE.md` qui l'importe. Le `CLAUDE.md` commun, relié dans le dossier racine par `ai/install.sh`, indique où trouver les guidelines en local.
- Chaque projet contient une configuration Claude Code versionnée (`.claude/`) issue du boilerplate (GLB-010) :
  - **hooks** : formatage et lint de chaque fichier modifié par l'IA, les erreurs lui sont renvoyées immédiatement ;
  - **permissions** : commandes de vérification, de branche, de commit, d'ouverture et de fusion automatique de PR autorisées sans confirmation ; actions irréversibles **interdites** (force-push, push direct sur `main`, fusion avec `--admin`, `drizzle-kit push`, `tofu apply` / `destroy`, lecture des fichiers `.env`) ;
  - **agents** et **commandes** (`/feature`, `/fix`, `/review`) communs à tous les projets.
- L'IA **NE DOIT PAS** contourner un hook ou une règle de lint (`--no-verify`, `eslint-disable` sans justification). Une dérogation suit `AGENTS.md` : commentaire `// Dérogation <ADR> : <raison>`.
- Un bug suit un cycle allégé, `/fix` : test de non-régression qui échoue d'abord (GLB-004), correction, contrôle par `reviewer` (et `security` / `devops` si concernés), PR. Le plan repasse par l'humain si la correction s'étend (plus de trois fichiers de production, migration, authentification, contrat d'API).
- Quand une décision d'architecture manque, l'IA propose un brouillon d'ADR au lieu de trancher seule (GLB-001), avec la commande commune `/adr`.

### Discipline

- **Vérifier avant d'annoncer** : l'IA NE DOIT PAS écrire qu'un travail est fini, corrigé ou que les tests passent sans avoir lancé la vérification dans la même étape et cité son résultat (commande, nombre de tests, sortie en échec). « Ça devrait marcher » n'est pas une vérification.
- **Cause avant correctif** (`/fix`) : reproduire, rassembler les faits (message exact, trace, dernier changement), puis tester **une hypothèse à la fois**. Pas de correctif sans cause identifiée. Après trois correctifs qui échouent, l'IA s'arrête et remet l'approche en question avec l'humain au lieu d'en tenter un quatrième.

### Fusion par l'IA (règle temporaire)

- Tant que le volume de PR est élevé, l'IA **PEUT** fusionner toute PR dont les checks requis sont verts, uniquement via la fusion automatique de GitHub (`--auto`) : c'est la protection de `main`, pas l'IA, qui garantit que la CI est passée.
- L'IA **NE DOIT PAS** utiliser `--admin` ni aucun autre contournement des checks. Exception : la PR « Version Packages » de shared-libs, sur laquelle aucune CI ne tourne.
- Cette règle sera resserrée quand le volume baissera : fusion par un humain pour les migrations de base, l'authentification et les données personnelles, l'infrastructure de production et les montées de version majeures.

## Alternatives envisagées

- **Une seule IA généraliste, sans agents** : plus simple, mais elle relit son propre travail avec les mêmes angles morts.
- **Agents qui se parlent directement** : séduisant, mais les échanges deviennent difficiles à suivre et à arrêter. Passer par un orchestrateur et des fichiers garde une trace lisible et un seul point de décision.
- **Plugin Superpowers** (obra/superpowers) : bonnes pratiques solides, mais un cycle concurrent qui se déclenche tout seul, des plans commités dans le repo et une proposition de fusion locale. On en reprend les idées (cadrage, cause avant correctif, vérifier avant d'annoncer) dans nos propres commandes.
- **Revue automatique par une IA dans la CI** (GitHub Action) : utile en complément plus tard, mais elle demande une clé API dans la CI et arrive après coup ; les contrôles locaux interviennent avant la PR.

## Conséquences

- ✅ Les ADR sont appliqués au moment où le code est écrit, pas seulement en revue.
- ✅ Les erreurs de format et de lint sont corrigées au fil de l'eau, la CI échoue rarement.
- ✅ Les actions irréversibles hors fusion (`tofu apply`, migrations de production, secrets, publication manuelle) restent entre les mains d'un humain.
- ⚠️ Tant que la fusion par l'IA est permise, plus aucun humain ne relit le code avant `main` : la qualité repose sur la CI, les hooks et les agents de contrôle. Une fusion sur `main` peut déclencher un déploiement.
- ⚠️ Un cycle complet consomme plus de temps et de tokens qu'une modification directe : réserver `/feature` aux vraies fonctionnalités.
- ⚠️ La configuration `.claude/` est copiée dans chaque projet : une amélioration doit être reportée depuis le boilerplate.

## Mise en application

- Boilerplates : `.claude/settings.json`, `.claude/hooks/after-edit.sh`, `.claude/agents/`, `.claude/skills/`, template d'issue `feature.yml`. La CI du repo `boilerplates` vérifie que le kit commun est identique dans chaque boilerplate.
- Protection de `main` : PR obligatoire, checks requis, fusion automatique activée ; l'IA fusionne uniquement par `--auto`.
- Revue : une PR ouverte par l'IA sans lien vers une issue ni synthèse des contrôles est renvoyée.
