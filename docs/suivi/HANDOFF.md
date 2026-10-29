# Passation : suite du chantier boilerplates (2026-10-29)

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
  5. ce qui ne se vérifie qu'à la main (appareil, staging, mise en ligne) s'ajoute à [`A-VERIFIER.md`](A-VERIFIER.md).
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
| B3, décision : ADR GLB-013 (registre `UserDataContributor`, effacement immédiat, mot de passe exigé, pas de traceur sans consentement, pages légales modèles) ; exception ajoutée à BE-002 | `adr/global/GLB-013-donnees-personnelles-et-rgpd.md` | engineering-guidelines #28 |
| Auth iOS, PR 2 sur 2 : `AuthFeature` (repository Better Auth sur `postRaw`, trois écrans natifs, textes d'Android), bascule de l'app sur `SessionStore.states()`, déconnexion qui révoque avant d'effacer, XCUITest avec doublures Debug (`-ui-testing`), essai de bout en bout contre `npm run stack` | `ios-swiftui/Packages/Sources/AuthFeature`, `App/`, `AppUITests/` | boilerplates #23 |
| Auth iOS, PR 1 sur 2 : `CoreAuth` (`SessionStore`, Keychain `AfterFirstUnlockThisDeviceOnly`), client sans cookies ni redirections, `Bearer` vers l'API seulement, `401` → session effacée, `postRaw` ; tests Keychain dans `iOSAppTests` (hébergée par l'app), CI sur simulateur via `scripts/test-simulator.sh` | `ios-swiftui/Packages/Sources/{CoreAuth,CoreNetworking}`, `AppTests/` | boilerplates #22 |
| Tâche I, PR 3 sur 4, Android : `ErrorKind` (401 sans écran, 403, 404, réseau = `IOException` seulement, serveur), `ErrorState` commun (règle testée en JVM par `errorContent`), écran de détail d'une note (`NoteDetailDestination(id)`, `GET v1/notes/{id}`), liste qui ouvre le détail ; `ApiError.Unexpected` pour une réponse illisible ; build release R8 vérifié | `android-compose/app/src/main/java/com/example/app/{core,feature/notes,navigation}` | boilerplates #37 ; engineering-guidelines (PR de cette passation) |
| Tâche I, PR 2 sur 4, web : `useCan` / `requirePermission` qui **demandent à l'API** (`has-permission`, choix de l'utilisateur, BE-010 mis à jour), page `/admin` (chiffres, comptes, suspendre, rôle, avec confirmation), `/notes/$id` (404 → « Note introuvable »), écrans 403, réseau (« Connexion impossible »), hors ligne, chargement ; erreurs du client Better Auth traitées comme `request()` ; politique de confidentialité (rôle, suspension) | `web-react-vite/src/features/{admin,auth,notes}`, `src/app/`, `src/lib/errors.ts` | boilerplates #36 ; engineering-guidelines (PR de cette passation) |
| Tâche I, PR 1 sur 4, API : plugin `admin` + `access-control.ts` (admin réduit à lister, changer de rôle, bannir, révoquer ; routes de prise de compte, de sessions et de suppression fermées), `GET /v1/admin/stats` (`@UserHasPermission`), `GET /v1/notes/:id` (404 IDOR), `npm run user:promote` (adresse vérifiée seulement), rôle dans l'export | `api-nestjs/src/modules/{auth,admin}`, `drizzle/0001_admin_roles.sql` | boilerplates #35 ; engineering-guidelines (PR de cette passation) |
| B3 iOS : portage d'Android (mêmes textes) ; `Toggle` de confirmation ; le ViewModel prévient l'app dès la réponse de l'API (`onAccountDeleted`), sans dépendre du rendu ; écran verrouillé jusqu'au retour à la connexion ; focus VoiceOver sur le message de suppression ; durée des sauvegardes dans `App/LegalInfo.swift` | `ios-swiftui/Packages/Sources/AuthFeature/Account*`, `App/` | boilerplates #34 ; engineering-guidelines (PR de cette passation) |
| B3 Android : écran « Mon compte » (seule action de la barre des notes, déconnexion déplacée dedans), politique de confidentialité et export ouverts sur le web, suppression avec mot de passe + case (écran verrouillé pendant l'envoi), message à la connexion posé par `SessionViewModel` avant l'effacement de la session ; durée des sauvegardes dans `res/values/legal.xml` ; CI qui compile `androidTest` | `android-compose/app/src/main/java/com/example/app/feature/auth/ui/Account*`, `navigation/` | boilerplates #33 ; engineering-guidelines (PR de cette passation) |
| B3 web, PR 2 sur 2 : page privée `/account` (« Mon compte » dans l'en-tête), export JSON téléchargé, suppression avec mot de passe + case de confirmation (`useDeleteAccount`, variante de bouton `destructive`), message de retour par l'état d'historique (pas l'URL), mocks MSW au contrat de l'API | `web-react-vite/src/features/account/` | boilerplates #32 |
| Décision rôles et permissions : plugin `admin` de Better Auth + access control, écrans 403 / 404 ressource / hors ligne (tâche I, pas encore codée) | `adr/backend/BE-010-roles-et-permissions.md` | PR de cette passation |
| Front responsive (tâche G) : FE-008 complété (mobile first, 320 px, pas de défilement horizontal, cibles ≥ 24 px) ; test E2E de débordement à 320/768/1280 px sur chaque route (liste vérifiée contre le router), contenus longs, champs à 16 px sur mobile ; `overflow-wrap: anywhere` sur `body` | `web-react-vite/e2e/responsive.spec.ts`, `e2e/pages.ts`, `src/styles.css` | boilerplates #30, #31 ; engineering-guidelines #33 |
| CI des boilerplates filtrée par chemins (OPS-002) : job `changes` + `scripts/ci-changes.sh` ; jobs non touchés sautés, tout tourne si `_shared/`, `.github/`, `scripts/` ou la racine changent, et sur `main` | `.github/workflows/boilerplates.yml` | boilerplates #29 |
| B3 web, PR 1 sur 2 : pages légales modèles (`/legal/notice`, `/legal/privacy`, `/legal/terms`), pied de page, CGU présentées à l'inscription, champs à remplir dans `legal-info.ts`, textes fr/en dans la feature (lazy), politique alignée sur le code | `web-react-vite/src/features/legal/` | boilerplates #27 (remplace #26) |
| Minimisation des données (API) : purge au démarrage puis toutes les 24 h des sessions et jetons expirés et des compteurs de rate limiting ; logs réduits à id, méthode, URL masquée, statut ; erreurs SQL sans valeurs ; Sentry sans en-têtes, navigateur ni jeton | `api-nestjs/src/common/{redact-url,scrub-error,sentry-redaction}.ts`, `src/modules/auth/expired-auth-data.purge.ts` | boilerplates #25 |
| Pas d'attribution Claude dans les commits et les PR (réglage `attribution`) | `.claude/settings.json` de chaque boilerplate et de `<racine>` | boilerplates #28 |
| Schémas d'architecture (10 diagrammes Mermaid) | `docs/architecture.md` | engineering-guidelines #31 |
| B3 API : registre `UserDataContributor` (`@ContributesUserData()`, `key`, `tables`, `schema`, `export`, `erase`), `notes` et `account` (compte, sessions, moyens de connexion) contributeurs ; `GET /v1/account/export` ; `POST /v1/auth/delete-user` avec mot de passe exigé, effacement transactionnel (`beforeDelete`) puis seconde passe (`afterDelete`) ; test d'architecture sur les tables `user_id` | `api-nestjs/src/common/user-data/`, `src/modules/account/`, `src/modules/auth/auth.user-data.ts` | boilerplates #24 |
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

**État au moment de la passation** (2026-10-29) : **B3 terminé** sur les quatre briques. Tâche I : API (boilerplates #35), web (#36) et Android (#37) faits. Prochaine étape : **tâche I, iOS** (point 4 ci-dessous). La stack locale de l'API est arrêtée.

## Ce qui reste, dans l'ordre convenu

1. ~~**B1 iOS**~~ ✅ (boilerplates #22, #23). B1 est terminé sur les quatre briques. Reste à faire par un humain : essai sur appareil avec VoiceOver et en grande police (iOS et Android).
2. **B3, RGPD et pages légales** : décision prise et écrite (**GLB-013**, à lire avant de coder). Choix de l'utilisateur (2026-10-28) : **registre explicite** `UserDataContributor` (pas d'événement `user.deleted`, pas de cascade SQL), **effacement immédiat** (pas de délai de grâce), **ressaisie du mot de passe** (pas de lien par e-mail). Reste à coder, **une PR par brique**, dans cet ordre :
   1. ~~**API**~~ ✅ (boilerplates #24). Contrat pour les clients :
      - export : `GET /v1/account/export` (session requise, 5 par minute) → `{ exportedAt, data: { account: { user, sessions, signInMethods }, notes: [...] } }`, avec `Content-Disposition: attachment; filename="account-export.json"` ;
      - suppression : `POST /v1/auth/delete-user` avec `{ "password": "…" }` (SDK web : `authClient.deleteUser({ password })`). Réponses : 200 `{ success: true }` ; 400 si mot de passe absent, vide ou faux (code `INVALID_PASSWORD` pour un mauvais mot de passe) ; 429 après 5 essais par minute. Après 200, la session est révoquée.
   2. **Web** (`web-react-vite`) : ~~pages légales~~ ✅ (boilerplates #27), ~~« Mon compte »~~ ✅ (boilerplates #32). Fait : écran « Mon compte » avec « Exporter mes données » (téléchargement JSON) et « Supprimer mon compte » (mot de passe et confirmation, puis retour à l'accueil, cache vidé avec `resetUserCache()`). Tests et E2E.
   3. ~~**Android**~~ ✅ (boilerplates #33), ~~**iOS**~~ ✅ (boilerplates #34). Découpage commun aux deux apps :
      - « Mon compte » est la **seule** action de la barre des notes ; « Se déconnecter » est dans « Mon compte » (deux boutons texte débordaient en grande police) ;
      - lien « Politique de confidentialité » (`WEB_BASE_URL/legal/privacy`), bouton « Exporter depuis le site web » (`WEB_BASE_URL/account`) ;
      - « Supprimer mon compte » : mot de passe actuel + case de confirmation, `POST /v1/auth/delete-user`, erreurs `INVALID_PASSWORD` → « Mot de passe incorrect. », 429, réseau ; écran verrouillé pendant l'envoi (retour bloqué) ;
      - après succès : le message « Votre compte et vos données ont été supprimés. » est posé **avant** l'effacement de la session (sinon la navigation détruit l'écran avant), puis affiché sur l'écran de connexion jusqu'à la session suivante ;
      - durée des sauvegardes (14 jours) dans une ressource, alignée sur `legal-info.ts` et l'infra ; pas d'e-mail affiché (choix de l'utilisateur).
      - petite reprise possible sur Android : l'écran se déverrouille pendant une image entre le succès et le retour à la connexion (`isDeleting` repasse à `false`) ; iOS garde `isDeleting` à vrai après le succès et prévient l'app depuis le ViewModel.
   4. ~~Checklist « nouveau projet », section Légal~~ ✅ (PR de cette passation).
3. ~~**Tâche G, front full responsive**~~ ✅ (FE-008 : engineering-guidelines #33 ; web : boilerplates #31 ; agent `reviewer` : boilerplates #30). Fait.
4. **Tâche I, rôles, permissions et écrans d'erreur** (décision du 2026-10-29, **BE-010**). Choix de l'utilisateur : route d'exemple `GET /v1/admin/stats`, et `GET /v1/notes/:id` ajouté au contrat des notes. ~~**API**~~ ✅ (boilerplates #35). Reste, une PR par brique :
   1. ~~**Web**~~ ✅ (boilerplates #36). Le web demande les permissions à l'API (`has-permission`) au lieu de copier `access-control.ts`.
   2. ~~**Android**~~ ✅ (boilerplates #37), puis **iOS, la prochaine étape**. Reprendre le découpage d'Android :
      - classement des erreurs : 401 → rien (le client efface la session, l'app revient à la connexion), 403, 404, réseau (`URLError` seulement), serveur (le reste, y compris une réponse illisible) ;
      - écran d'erreur commun avec les textes d'Android (`error_*`, sans « L'équipe a été prévenue »), règle testable sans simulateur (titre, explication, action : réessayer pour réseau et serveur, retour pour 403 et 404) ;
      - écran de détail d'une note (`GET /v1/notes/:id`, « Note introuvable », « Toutes les notes »), ouvert depuis la liste ; la liste utilise l'écran d'erreur commun ;
      - **pas de lecture du rôle** dans la session ni de bandeau hors ligne global (choix validé pour Android : aucun élément réservé sur mobile ; à ajouter avec le premier qui en dépend).
   3. Agent `security` : vérifier qu'une route réservée a son décorateur et son test de refus.
   - **Décisions en attente de l'utilisateur** (signalées par les agents, PR #35) :
     - **lancer `user:promote` en staging et en production** : la base est privée, le conteneur n'a pas de shell, et OPS-004 écarte le job GitHub. Options proposées par devops : Serverless Job lancé par `workflow_dispatch` (si Jobs joint le réseau privé), bastion temporaire (Public Gateway en `count`, puis tunnel SSH), endpoint public temporaire limité à une IP (contraire à OPS-005). Un ADR `/adr` à écrire après le choix ;
     - protection des admins entre eux (aujourd'hui un admin peut en rétrograder ou en bannir un autre ; `user:promote` permet de reprendre la main) ;
     - journalisation des actions d'administration (ids seulement, BE-007) ;
     - procédure d'export ou d'effacement pour un compte banni (GLB-013 : il ne peut plus se connecter).
5. **Tâche C** : catalogue de modules optionnels.
6. **Tâche D** : app jetable de bout en bout, déployée en staging. L'utilisateur y déroule [`A-VERIFIER.md`](A-VERIFIER.md) d'un coup. C'est là que se vérifie tout ce qui ne se teste pas sans compte Scaleway :
   - la chaîne `X-Forwarded-For` (`TRUST_PROXY_HOPS`, **prioritaire**) ;
   - la commande et les champs de la CLI `scw` ;
   - les CNAME, Edge Services, le cookie entre sous-domaines ;
   - les quotas TEM et les droits PostgreSQL ;
   - la rétention réelle des logs Cockpit (7 jours par défaut ?) et de Sentry, puis la fixer dans l'infra par un ADR (OPS-007) ;
   - le statut 404 et le cache Edge Services d'un accès direct à une route de la SPA (`/legal/*`, `/account` : index.html servi en `error_document`) ;
   - un onglet resté ouvert pendant un déploiement : `aws s3 sync --delete` retire les anciens chunks, garder une version de plus ;
   - une ligne de log sans IP ni navigateur, un événement Sentry sans user-agent, le log « Expired auth data purged » au démarrage.

Pistes non bloquantes :

- cache de build GHA pour le job `stack` ;
- Android : `assembleRelease` dans la CI (R8 n'est vérifié qu'à la main) ; recharger la liste des notes au retour d'une note introuvable ; en debug, logcat affiche le contenu des notes (corps hors `/v1/auth/`) : à trancher dans AND-004 ;
- **budget du bundle web** : `size-limit` ne mesure que `index-*.js` (115 Ko), mais `index.html` précharge d'autres chunks (zod, client Better Auth…) : environ 194 Ko sur 200 en tout (devops, #36). Mesurer tout le JS initial (manifeste Vite) ;
- **Playwright en CI** : le workflow du monorepo (`boilerplates.yml`) ne lance que `npm run verify` pour le web ; le job `e2e` de `web-react-vite/.github/workflows/ci.yml` ne tourne qu'une fois le boilerplate copié dans son repo. Les E2E sont lancés à la main avant chaque PR ;
- test e2e de `has-permission` côté API (user → false, admin → true, sans session → 401), dont dépend le web ;
- apps mobiles : exiger `https` pour `WEB_BASE_URL` et `API_BASE_URL` en Release (garde-fou au build ou au démarrage), et faire échouer le build Release tant que `example.com` reste dans les URL (suggestions security et devops, boilerplates #33, #34) ;
- `verify-ca` pour PostgreSQL, avec le certificat de l'instance ;
- documenter dans un ADR que l'app tourne aussi dans compose (profil `app`).
- les routes `/v1/auth/*` (Better Auth) ne passent pas par pino-http : elles ne sont pas journalisées (BE-007).
- la config `dataCollection` de Sentry (API) n'a pas de test automatisé ; `document.title` ne change pas par page (FE-008).
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
- **Keychain en test iOS** : un bundle de tests de package (sans app hôte) reçoit `-34018`. Les tests Keychain vivent dans `iOSAppTests`, hébergée par l'app, signée en ad hoc (`CODE_SIGN_IDENTITY=-`), jamais avec `CODE_SIGNING_ALLOWED=NO`.
- **`xcodebuild -quiet`** n'affiche pas les tests passés : lire le résultat avec `xcrun xcresulttool get test-results summary --path <dernier .xcresult>`.
- **Better Auth `/delete-user`** (1.7) : le `password` est **facultatif**. Sans lui, une session de moins d'un jour (`freshAge`, 1 jour par défaut) suffit à supprimer le compte, et `freshAge: 0` désactive même ce contrôle. Vu dans `node_modules/better-auth/dist/api/routes/update-user.mjs`. Ordre réel : vérification du mot de passe, puis `beforeDelete`, puis suppression du user, puis des sessions, puis `afterDelete`.
- **Better Auth `listSessions`** exige une session de moins d'un jour (`freshSessionMiddleware`) : inutilisable pour l'export. Le module auth lit ses propres tables (`auth.repository.ts`), colonne par colonne.
- **Better Auth `/delete-user`** : `if (ctx.body.password)` traite une chaîne vide comme absente. Le hook `before` refuse donc aussi `""`. Le chemin `token` du corps appelle `deleteUserCallback` en direct (sans passer par `disabledPaths`), mais exige une ligne `delete-account-<token>` que seul `sendDeleteAccountVerification` crée.
- **Throttler NestJS en test e2e** : les compteurs vivent en mémoire pour toute l'app de test ; un test qui appelle beaucoup une route limitée (export, 5 par minute) passe un `x-forwarded-for` dédié, ou vérifie l'état par une autre route.
- **CI filtrée et ruleset** : un job matriciel sauté en entier ne rapporte pas ses checks `node (…)` requis (PR bloquée) : la matrice `node` tourne toujours et saute ses étapes. Un job sauté parce que `changes` a échoué compterait comme réussi : d'où `!cancelled()` et « tout tourne si `changes` échoue ».
- **`overflow-wrap`** : `break-word` ne réduit pas la largeur minimale d'une colonne de grille ; seul `anywhere` évite qu'un mot long élargisse la page.
- **Commit de fusion GitHub** : en squash, GitHub ajoute les `Co-authored-by` trouvés dans les commits de la branche, même avec un message de fusion explicite (`gh pr merge --body`). Une branche qui en contient doit être recréée propre (`git merge --squash` sur une nouvelle branche, nouvelle PR), sans force-push.
- **Sentry v11, spans** : l'instrumentation HTTP ajoute `user_agent.original`, `network.peer.address`, `client.address` à chaque span serveur, quel que soit `dataCollection.httpHeaders` : `beforeSendSpan` (`redactSpan`) les retire. La liste `allow` des en-têtes compare par sous-chaîne (`accept` laisse passer `accept-language`).
- **pino-http** : `serializers.req` / `res` / `err` reçoivent l'objet déjà passé par le sérialiseur standard ; le `res` standard journalise `location` (jeton de réinitialisation). `DrizzleQueryError` met les paramètres SQL dans son message.
- **SwiftUI réécrit la même valeur dans un binding en fin d'édition** (par exemple quand le focus passe à nil) : un `didSet` qui efface des erreurs doit comparer à `oldValue`, sinon le message d'erreur disparaît aussitôt (trouvé par XCUITest).
- **Runners macOS GitHub** : un job peut être annulé faute de runner (« not acquired by Runner… capacity constraints », 0 étape). Ce n'est pas un échec du code : `gh run rerun <id> --failed`.
- **PostgreSQL pro sur le port 5432** (conteneur `sqool-postgresql-1`) : `npm run stack` ne peut pas publier ce port. Ne pas toucher aux conteneurs pro ; lancer la stack avec une surcharge hors du repo qui retire le port de `postgres` (`ports: !reset []`), l'API le joint par le réseau Docker.
- **Plugin `admin` de Better Auth** : le rôle `admin` par défaut (`adminAc`) donne `set-password`, `set-email`, `update`, `create` : un admin peut prendre n'importe quel compte. Ne jamais l'hériter tel quel : `access-control.ts` liste les actions, et `ADMIN_DISABLED_PATHS` ferme les routes. `/admin/remove-user` supprime le compte sans passer par `user.deleteUser.beforeDelete`, donc sans effacer les données des modules (GLB-013) : fermé.
- **Plugin `admin` et anti-énumération** : la réponse d'inscription pour une adresse déjà utilisée est un compte factice ; sans `customSyntheticUser`, il a `role: null` au lieu de `user` et trahit l'adresse. Le test de forme de `auth.e2e-spec.ts` le détecte.
- **Client Better Auth et erreurs (web)** : ses appels ne passent pas par `request()`. Une panne réseau donnait un `TypeError` brut ; `customFetchImpl: fetchOrNetworkError` la change en `NetworkError`. Les routes réservées passent par `unwrapProtected` (401 → `notifyUnauthorized`, 403 → `ForbiddenError`). Le `retry` de TanStack Query ne réessaie aucune 4xx (`isClientError`).
- **Nom accessible avec un `<span className="sr-only">`** : Testing Library calcule « SuspendreOther » (sans espace) ; utiliser un `aria-label` qui commence par le libellé visible.
- **Routes `/v1/auth/admin/*` avec un id mal formé** : 500 (erreur PostgreSQL sur une colonne uuid) ; le hook `before` répond 400.
- **Gradle sur ce Mac** : `~/.gradle/gradle.properties` est la config **pro** (options JVM refusées par Java 21, `android.enableBuildCache` refusé par AGP 8, identifiants pro). Ne pas l'afficher ni le modifier. Lancer Gradle avec `GRADLE_USER_HOME=~/.gradle-perso JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home ANDROID_HOME=~/Library/Android/sdk`. Le SDK est installé en ligne de commande (pas d'Android Studio, pas d'émulateur) : les tests `androidTest` compilent mais ne tournent pas ici.
- **Tests Compose** : pendant l'envoi, `AuthSubmitButton` n'affiche qu'un indicateur ; le libellé n'est plus que dans `contentDescription`, donc `hasText()` ne trouve plus le bouton (`hasContentDescription()`).
- **Plugins Claude** : un plugin n'est actif dans un projet que s'il y est installé (`claude plugin install <p> --scope project`), même s'il est dans `enabledPlugins`. Ne jamais l'installer en `--scope user` sur ce Mac (portée par défaut).

## État des boilerplates en une phrase

En local, l'API, l'auth et l'envoi d'e-mails fonctionnent avec `npm run setup && npm run stack`, l'API tournant dans l'image de production avec PostgreSQL et Mailpit dans Docker Compose. Le front s'y branche avec `npm run dev:api`. Il n'y a pas de Traefik : les services sont exposés sur `localhost:3000`, `localhost:8025` et `localhost:5173`. La production cible Scaleway Serverless Containers, et non un serveur Docker avec Traefik.
