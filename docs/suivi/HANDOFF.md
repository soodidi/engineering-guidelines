# Passation : suite du chantier boilerplates (2026-10-28)

Ce document résume l'état d'une session précédente. Lis-le en entier avant d'agir. La feuille de route détaillée est dans `PLAN-SUITE.md`, dans ce même dossier : ce document la complète, il ne la remplace pas.

Ces deux fichiers vivent dans `engineering-guidelines/docs/suivi/`. Ce sont des **documents temporaires, à effacer** une fois le chantier terminé. Ils servent à fluidifier le travail entre les postes et entre les instances d'IA : n'importe quelle machine ou session de Claude reprend le chantier avec un `git pull`, sans dépendre d'une mémoire locale ni d'un historique de conversation. Mets-les à jour (PR) à la fin de chaque tâche, et supprime-les quand le chantier est terminé. Sur une nouvelle machine, installe d'abord le poste avec [`docs/poste-de-travail.md`](../poste-de-travail.md).

## Cadre de travail

- **Trois repos** côte à côte dans le dossier racine `<racine>` (sur le Mac actuel : `~/Documents/perso/projects`, isolé du travail pro, voir [`docs/poste-de-travail.md`](../poste-de-travail.md)) :
  - `engineering-guidelines` : ADR, checklist, skills IA ;
  - `boilerplates` : `api-nestjs`, `web-react-vite`, `infra-scaleway`, `android-compose`, `ios-swiftui`, plus `_shared` ;
  - `shared-libs` : packages partagés et preset Renovate.
- **Règles** : `<racine>/CLAUDE.md` (lien vers `ai/CLAUDE.global.md`), l'`AGENTS.md` de chaque repo et de chaque boilerplate, et les ADR (GLB-011 pour le cycle de travail).
- **Langue** : parler en français, de façon concise. Code et commits en anglais (Conventional Commits). Docs et ADR en français.
- **Cycle d'une PR** :
  1. une branche par sujet ;
  2. `npm run verify` (ou `tofu fmt` et `validate`), dont tu cites le résultat ;
  3. les agents de contrôle `reviewer`, `qa`, `security` et `devops` (`.claude/agents/*.md` de chaque boilerplate), à lancer en agents `general-purpose` qui lisent ce fichier. L'utilisateur veut qu'ils soient **tous** lancés, ou que tu dises explicitement lequel tu sautes et pourquoi ;
  4. la PR, puis `gh pr merge --squash --auto --delete-branch`. Jamais `--admin`, jamais de force-push, jamais de `tofu apply` ni d'action irréversible.
- **Décisions d'architecture** : présenter 2 ou 3 options avec une recommandation, puis **attendre le choix de l'utilisateur** avant d'écrire l'ADR.
- **Environnement local** :
  - Outils et installation : [`docs/poste-de-travail.md`](../poste-de-travail.md). Machine actuelle : MacBook Pro M1 (Apple Silicon).
  - Le shell de Claude ne garde pas les variables d'un appel à l'autre, et peut ne pas charger nvm. Si `node -v` n'est pas en v26 ou si `docker` est introuvable, préfixer les commandes : `export PATH="$(dirname "$(ls -d ~/.nvm/versions/node/v26.*/bin/node | tail -1)")":/Applications/Docker.app/Contents/Resources/bin:$PATH`. Sans le chemin de Docker Desktop, Testcontainers échoue (`docker-credential-desktop` introuvable).
  - Android : `export ANDROID_HOME=~/Library/Android/sdk`. Sur Apple Silicon, l'émulateur utilise une image `arm64-v8a` (voir le doc du poste de travail).

## Préférences de l'utilisateur (aussi en mémoire)

- Il fait d'abord des apps pour lui, peut-être publiques plus tard : simple en dev et en staging, propre en production.
- Il veut la même image Docker en dev, en staging et en production, un `.env` prêt dès l'initialisation, et le minimum à remplir.
- À chaque nouveau projet, lui expliquer **clairement** la passphrase du state OpenTofu (`TF_STATE_PASSPHRASE`). L'étape existe dans le skill `/new-project`.

## Ce qui est fait

| Sujet | Où | PR |
|---|---|---|
| Auth : BE-006, Better Auth 1.7.14, sessions opaques (cookie pour le web, Bearer signé pour le mobile), Argon2id, plafond de 90 jours, CSRF, IP client via `TRUST_PROXY_HOPS` | `api-nestjs/src/modules/auth/` | boilerplates #12, #14 ; engineering-guidelines #12, #13 |
| E-mails : BE-009, module `mail` (SMTP, nodemailer), Mailpit en local, Scaleway TEM | `api-nestjs/src/mail/` | boilerplates #10 ; engineering-guidelines #14 |
| Auth web : pages, routes privées, nettoyage du cache entre comptes, exception FE-002 pour le SDK | `web-react-vite/src/features/auth/` | boilerplates #15 ; engineering-guidelines #17 |
| Infra : IAM depuis `envs/iam` (appliqué à la main), une clé par repo, state chiffré (OPS-006) | `infra-scaleway/` | boilerplates #11, #13, #14 ; engineering-guidelines #15, #16 |
| Renovate : pas de fusion automatique pour les librairies d'auth | `shared-libs/default.json` | shared-libs #7 |
| Tâche E : `npm run setup`, `npm run stack` (image de production), test de fumée en CI, `npm run dev:api` côté web, `/new-project` minimal | `api-nestjs/scripts/`, `compose.yaml` | boilerplates #16 ; engineering-guidelines #18 |
| Auth Android : écrans natifs (connexion, inscription, mot de passe oublié), token signé chiffré (Tink + Keystore), 401 → connexion, liens des e-mails vers le web (`WEB_BASE_URL`), sans deep links (choix de l'utilisateur) | `android-compose/app/src/main/java/com/example/app/{core/auth,feature/auth,navigation}` | boilerplates #18, #19 ; engineering-guidelines #21 |
| Tâche F : migrations au démarrage sous `pg_advisory_lock` (décision de l'utilisateur), chaîne de déploiement prête | BE-003, OPS-004, `infra-scaleway/` | boilerplates #17 ; engineering-guidelines #19, #20 |

## Tâche F : terminée

Fusionnée dans boilerplates #17 et engineering-guidelines #19 et #20. Elle couvre :

- les migrations au démarrage de l'API sous verrou PostgreSQL ;
- le TLS de la base, et l'URL de la base qui attend le privilège de l'utilisateur `app` ;
- `CONTAINER_ID` en UUID seul, le domaine de l'API et sa cible CNAME, la cible CNAME du front ;
- une bucket policy qui cite la CI, la clé de plan et `deploy-web` ;
- `envs/shared` dans la CI, une clé `ci_plan` en lecture seule, et la CLI `scw` et tflint épinglés.

Rapport devops : `boilerplates/infra-scaleway/.claude/work/deploy-chain/devops.md`. Tous les points sont traités. Restent à vérifier en conditions réelles, pendant la tâche D :

- la chaîne `X-Forwarded-For` ;
- les droits réels de l'utilisateur `app` ;
- si le `dns_stage` Edge Services exige déjà le CNAME au moment de l'apply.

**Isolation perso / pro** (2026-10-28) : la configuration Claude vit dans `<racine>` (`CLAUDE.md`, `.claude/skills`, `.claude/settings.json`), rien dans `~/.claude` ; l'identité Git perso passe par `includeIf` vers `~/.gitconfig-perso`. Les chemins `~/Documents/projects` codés en dur sont remplacés par `<racine>` (engineering-guidelines et boilerplates, PR « workspace-relative paths »). Ne pas cloner dans `~/Documents/projects` : c'est le dossier pro de ce Mac.

## Ce qui reste, dans l'ordre convenu

1. **B1 iOS** (Android fait, boilerplates #18 : reprendre le même découpage, les mêmes textes et les mêmes tests). Décisions de l'utilisateur (2026-10-28) : **deux PR** (1 : `CoreAuth` avec Keychain + client sans cookies, `Bearer` et `401` ; 2 : `AuthFeature`, écrans, bascule de l'app, XCUITest) et un **job CI `xcodebuild test` sur simulateur** à chaque PR (Keychain et XCUITest) :
   - écran de connexion ;
   - token signé reçu dans l'en-tête `set-auth-token`, envoyé en `Authorization: Bearer` ;
   - stockage : Keystore avec Tink sur Android, Keychain sur iOS ;
   - sur un 401, effacer le token et revenir à la connexion. Il n'y a pas de refresh token (BE-006, AND-004, IOS-004) ;
   - iOS : URLSession **sans cookies** (`httpShouldSetCookies = false`, `httpCookieStorage = nil`).
2. **B3, RGPD et pages légales** : voir `PLAN-SUITE.md`. Il faut un mécanisme explicite pour effacer les données de chaque module à la suppression d'un compte, par exemple un événement `user.deleted` émis par le module auth. Il n'y a pas de clé étrangère entre modules (BE-002), par exemple pour `notes.user_id`.
3. **Tâche C** : catalogue de modules optionnels.
4. **Tâche D** : app jetable de bout en bout, déployée en staging. C'est là que se vérifie tout ce qui ne se teste pas sans compte Scaleway :
   - la chaîne `X-Forwarded-For` (`TRUST_PROXY_HOPS`, **prioritaire**) ;
   - la commande et les champs de la CLI `scw` ;
   - les CNAME, Edge Services, le cookie entre sous-domaines ;
   - les quotas TEM et les droits PostgreSQL.

Pistes non bloquantes :

- cache de build GHA pour le job `stack` ;
- `verify-ca` pour PostgreSQL, avec le certificat de l'instance ;
- documenter dans un ADR que l'app tourne aussi dans compose (profil `app`).
- l'utilisateur a demandé si tout tourne « en une commande, avec Traefik ». Réponse donnée : `npm run setup && npm run stack` côté API, plus `npm run dev:api` côté web, sans Traefik. Améliorations proposées, **à lui faire valider** : une commande unique `npm run up` (setup + stack), ajouter le front à la même stack compose. Traefik seulement en cas de choix d'auto-hébergement sur un VPS, ce qui demande un ADR, car c'est un autre modèle qu'OPS-005.

## Pièges déjà rencontrés (à ne pas redécouvrir)

- **Token mobile** : seul l'en-tête `set-auth-token` est signé ; le `token` du corps de sign-in ne passe pas `requireSignature`.
- **Tink** : si le Keystore est inutilisable, `AndroidKeysetManager` écrit le keyset en clair sans erreur → vérifier `isUsingKeystore`.
- **Gradle** : ne pas lancer plusieurs Gradle en parallèle sur le même projet (KSP casse). Les agents de contrôle lancés en même temps le font : leur dire de ne pas relancer Gradle, ou les lancer après la vérification.
- **Tests DataStore** : temps réel (`runBlocking`), pas `runTest` ; relire le fichier plutôt qu'attendre une émission du flux (instable en CI).
- **ktlintFormat** reformate avant un remplacement par script : relire le fichier après coup.

- **Better Auth en test** : il désactive sa vérification d'origine (`isTest()`). Garder `advanced.disableOriginCheck: false` dans `auth.config.ts`.
- **Plugin `bearer`** : il exige `requireSignature: true`, sinon un token lu en base suffit.
- **Hook `session.update.before`** : il ne reçoit que `{ expiresAt, updatedAt }`. `createdAt` se lit dans `context.context.session`.
- **Client Better Auth côté web** : il mémorise `fetch` à sa création. `customFetchImpl` lit le `fetch` global à chaque appel, pour que MSW fonctionne.
- **`queryClient.clear()`** : il détache les observateurs, et l'en-tête ne suit plus la session. Utiliser `resetUserCache()`.
- **Image de production** : elle a besoin de `@fastify/static` dès que Swagger est actif.
- **`SMTP_INSECURE`** : il n'est accepté que vers un Mailpit local.

## État des boilerplates en une phrase

En local, l'API, l'auth et l'envoi d'e-mails fonctionnent avec `npm run setup && npm run stack`, l'API tournant dans l'image de production avec PostgreSQL et Mailpit dans Docker Compose. Le front s'y branche avec `npm run dev:api`. Il n'y a pas de Traefik : les services sont exposés sur `localhost:3000`, `localhost:8025` et `localhost:5173`. La production cible Scaleway Serverless Containers, et non un serveur Docker avec Traefik.
