# Plan de la suite — à exécuter par Claude Code

Lancé depuis le dossier racine `<racine>` (voir `ai/README.md`). Trois repos : `engineering-guidelines`, `shared-libs`, `boilerplates`. Ce fichier et `HANDOFF.md` vivent dans `engineering-guidelines/docs/suivi/` (documents temporaires, à effacer à la fin du chantier ; voir `README.md` du dossier).

## Règles pour toute la suite

- Lire `AGENTS.md` de chaque repo touché et les ADR concernés (`engineering-guidelines/adr/`). Respecter GLB-002 (branches, Conventional Commits), GLB-003 (PR courtes, un sujet), GLB-010, GLB-011, GLB-012.
- npm uniquement. Une branche et une PR par tâche numérotée ci-dessous. `verify` (ou l'équivalent dans `AGENTS.md`) doit passer, CI verte (`gh pr checks <n> --watch`).
- Fusion : tant qu'un seul développeur travaille sur le projet, activer la **fusion automatique** dès la PR ouverte (`gh pr merge --squash --auto --delete-branch`, GLB-011) : GitHub fusionne quand la CI est verte. Jamais de `--admin`. Ne jamais forcer un push, ne jamais lancer `tofu apply` / `destroy` ni créer de ressource payante : me le demander.
- Toute décision non couverte par un ADR : me présenter 2 ou 3 options (pour / contre en quelques lignes, recommandation), **attendre mon choix**, puis écrire l'ADR.
- Me parler en français, de façon concise. Me signaler toute action que je dois faire moi-même (compte, secret, paiement).
- Avant de modifier un repo : `git switch main && git pull`.

---

## Tâche A — Checklist « nouveau projet » qui revient à chaque fois

> ✅ Fait : PR engineering-guidelines #11 (fusionnée).

But : ne jamais oublier les comptes et secrets propres à chaque projet.

1. Créer `engineering-guidelines/docs/checklist-nouveau-projet.md` avec des cases à cocher, par brique :
   - **Tous** : repo GitHub créé et `main` protégée (PR obligatoire, CI verte) ; labels ; Renovate actif sur le repo (developer.mend.io) ; secrets rangés dans le gestionnaire de mots de passe.
   - **Sentry** (organisation `soodidi` déjà créée, région UE) : créer un projet par brique (web, api, android, ios) ; récupérer le DSN ; variables GitHub `SENTRY_DSN`, `SENTRY_ORG`, `SENTRY_PROJECT` ; secret `SENTRY_AUTH_TOKEN` (token d'organisation existant) ; alerte « nouvelle erreur » vers mon e-mail.
   - **Scaleway** (infra) : projet Scaleway dédié ; clé API limitée à ce projet pour la CI (`SCW_ACCESS_KEY`, `SCW_SECRET_KEY`) ; bucket pour l'état OpenTofu ; **alerte budget** ; environnements GitHub `staging` et `production` (avec validation manuelle pour production).
   - **Domaine** : nom de domaine acheté ; DNS vers l'app et l'API ; e-mails d'envoi configurés (SPF, DKIM, DMARC) quand la brique e-mail est utilisée.
   - **Mobile** : compte Apple Developer (99 €/an, validation en quelques jours) ; Google Play Console (25 $) ; identifiants d'app réservés ; fiches store.
   - **Légal** (voir tâche B3) : mentions légales, politique de confidentialité, CGU remplies.
   - Pour chaque secret ou variable : le nom exact attendu par les workflows (les retrouver en cherchant `secrets.` et `vars.` dans `.github/workflows/` de chaque boilerplate) et la commande `gh secret set` / `gh variable set`.
2. Faire en sorte que **`/new-project` affiche cette checklist** à la fin (adaptée aux briques choisies), en marquant ce qu'il a déjà fait lui-même, et crée dans le nouveau repo une issue « Mise en route » qui contient la checklist restante.
3. Ajouter une ligne dans `ai/CLAUDE.global.md` : au démarrage d'un projet ou avant le premier déploiement, rappeler la checklist.
4. Lien depuis le README d'engineering-guidelines et GLB-010.

---

## Tâche B — Briques manquantes dans les boilerplates

Faire B1, puis B2, puis B3 (chacune : ADR + code + tests, une PR par repo touché).

### B1. Authentification (le plus important)

> État : ADR (BE-006 avec Better Auth) ✅ ; API ✅ (boilerplates #12, #14) ; checklist B1.4 ✅ (engineering-guidelines #16). Web ✅ (boilerplates #15, exception FE-002 : engineering-guidelines #17). Android ✅ (boilerplates #18, #19 ; engineering-guidelines #21). iOS ✅ (boilerplates #22, #23). **B1 terminé.**

BE-006 fixe les règles (Argon2id, cookie `HttpOnly` sur le web, access token court + refresh token rotatif sur mobile stocké dans Keychain / Keystore, routes protégées par défaut avec `@Public()`, vérification d'appartenance contre l'IDOR, rate limiting sur login) mais **ne choisit pas d'outil**.

1. Me présenter les options, par exemple : une librairie d'auth TypeScript intégrée à l'API NestJS + Drizzle (ex. Better Auth), un fournisseur OIDC auto-hébergé (Keycloak, Zitadel), un service managé hébergé en Europe. Critères : respect de BE-006 pour web **et** mobile, hébergement UE / RGPD, coût, maintenance, maturité, compatibilité NestJS 12 + Fastify + Drizzle. **Attendre mon choix.**
2. Écrire l'ADR (ex. BE-009) et mettre à jour BE-006 / README backend.
3. Intégrer dans les boilerplates :
   - **api-nestjs** : inscription, connexion, déconnexion, session web en cookie, tokens mobiles avec rotation, mot de passe oublié, vérification d'e-mail, guard global + `@Public()`, rôles + appartenance ; la feature `notes` devient propre à l'utilisateur connecté ; tests d'intégration (Testcontainers) dont un test IDOR.
   - **web-react-vite** : pages connexion / inscription / mot de passe oublié, route protégée (TanStack Router `beforeLoad`), déconnexion, gestion du 401 dans `request()`, tests et E2E du parcours de connexion.
   - **android-compose** et **ios-swiftui** : écran de connexion, stockage sécurisé des tokens, rafraîchissement automatique, déconnexion, tests.
4. Mettre à jour `.env.example`, les README et la checklist de la tâche A (secrets d'auth).

### B2. Envoi d'e-mails

> ✅ Fait : BE-009 (engineering-guidelines #14), module `mail` + Mailpit (boilerplates #10), TEM dans l'infra (boilerplates #11, puis #13).

1. Me présenter les options (ex. Scaleway Transactional Email, Brevo) : coût, hébergement UE, délivrabilité, SDK. **Attendre mon choix.** Écrire l'ADR.
2. **api-nestjs** : module e-mail derrière une interface (implémentation réelle + implémentation de test), gabarits en français (vérification d'e-mail, mot de passe oublié), envoi via une file ou au minimum avec reprise sur erreur ; **Mailpit** dans `compose.yaml` pour le développement local ; tests.
3. Brancher B1 dessus (vérification d'e-mail, mot de passe oublié). Ajouter SPF / DKIM / DMARC à la checklist.

### B3. RGPD et pages légales

> État : ADR ✅ (**GLB-013**, engineering-guidelines #28). API ✅ (boilerplates #24, minimisation #25). Web : pages légales ✅ (boilerplates #27) ; reste l'écran « Mon compte ». Puis Android, iOS (détail dans `HANDOFF.md`). Checklist Légal ✅.

1. ADR (ex. GLB-013) : données collectées minimales, durées de conservation, pas de traceur sans consentement (donc pas de bandeau cookies tant qu'il n'y a ni analytics ni pub), droit d'accès (export JSON) et d'effacement, sous-traitants listés (Scaleway, Sentry, e-mail), Sentry sans données personnelles.
2. **web-react-vite** : pages modèles « Mentions légales », « Politique de confidentialité », « CGU » avec des champs à remplir clairement marqués (`[NOM DE L'ÉDITEUR]`…), liées dans le pied de page ; écran « Mon compte » avec **exporter mes données** et **supprimer mon compte** (confirmation).
3. **api-nestjs** : endpoints export et suppression du compte (suppression réelle ou anonymisation, en cascade), tests.
   - Pas de clé étrangère entre modules (BE-002, ex. `notes.user_id`) : prévoir un mécanisme explicite, par exemple un événement `user.deleted` émis par le module auth et écouté par chaque module qui garde des données d'utilisateur, avec un test par module.
4. **Mobile** : suppression du compte accessible dans l'app (obligatoire pour l'App Store) et lien vers la politique de confidentialité.

---

## Tâche C — Catalogue de modules optionnels

But : des recettes prêtes à appliquer **quand une app en a besoin**, sans les mettre dans les boilerplates.

1. Créer `engineering-guidelines/modules/README.md` (index : quand utiliser chaque module) et une fiche par module :
   - `upload-fichiers.md` — Object Storage Scaleway, URL présignées, limites de taille et de type, analyse des fichiers, suppression avec le compte (RGPD).
   - `paiement.md` — Stripe : Checkout ou Payment Element, webhooks signés et idempotents, abonnements, mode test, factures, TVA.
   - `analytics.md` — mesure d'audience respectueuse de la vie privée (Plausible, PostHog hébergé UE…), sans cookie si possible, impact RGPD.
   - `notifications-push.md` — FCM (Android) et APNs (iOS), enregistrement des appareils côté API, préférences utilisateur, envoi depuis l'API.
   - `client-api-openapi.md` — générer les clients web, Android et iOS depuis `openapi.json` de l'API (outil par plateforme, intégration CI, quand le préférer aux appels écrits à la main).
2. Format de chaque fiche : quand l'utiliser, option recommandée et alternatives, ADR impactés, étapes d'intégration par brique (api, web, android, ios, infra), secrets et comptes à créer (à ajouter à la checklist du projet), pièges, tests à écrire.
3. Les fiches sont au statut « Proposé » : au premier usage réel, `/adr` en tire un ADR.
4. Mentionner le catalogue dans `ai/CLAUDE.global.md` et dans l'agent `planner` (`boilerplates/_shared/claude/agents/planner.md`, puis `scripts/sync-shared.sh`) : si une fonctionnalité correspond à un module, lire sa fiche avant de planifier.

---

## Ordre convenu (2026-10-27)

1. ~~B1 web (auth dans `web-react-vite`)~~ ✅
2. ~~Tâche E — Parité Docker et `.env` prêts à l'init~~ ✅ (boilerplates #16, engineering-guidelines #18)
3. ~~Tâche F — Chaîne de déploiement prête~~ ✅ (boilerplates #17, engineering-guidelines #19, #20)
4. ~~B1 mobile~~ ✅ : Android (boilerplates #18, #19), iOS (boilerplates #22, #23).
5. ~~Tâche G — front full responsive~~ ✅, puis B3 — RGPD : ~~ADR~~ ✅, ~~API~~ ✅, web (~~pages légales~~ ✅, « Mon compte »), Android, iOS.
6. Tâche I — rôles, permissions et écrans d'erreur (BE-010), après B3 mobile.
7. Tâche C, puis tâche D (app jetable de bout en bout).

## Tâche G — Front full responsive (demande du 2026-10-28)

> ✅ Fait : FE-008 (engineering-guidelines #33), web (boilerplates #31), agent `reviewer` (boilerplates #30).

But : toutes les apps web s'utilisent confortablement du téléphone (320 px) au grand écran.

1. Compléter FE-008 (ou un ADR dédié via `/adr`) : mobile first ; aucun défilement horizontal de 320 px à 1920 px ; cibles tactiles d'au moins 24 × 24 px (WCAG 2.2, 2.5.8) ; navigation repliable sur petit écran ; tableaux en cartes ou défilement interne ; formulaires sur une colonne.
2. `web-react-vite` : test E2E (Playwright) qui ouvre chaque route à 320, 768 et 1280 px et échoue si `document.documentElement.scrollWidth > clientWidth` ; corriger l'en-tête et ce que le test trouve.
3. Agent `reviewer` (`_shared/claude/agents/reviewer.md`) : vérifier le responsive dans les revues front.

## Tâche I — Rôles, permissions et écrans d'erreur (demande du 2026-10-29)

> Décision de l'utilisateur : plugin `admin` de Better Auth + access control (pas CASL, `organization` en module optionnel) ; écrans d'erreur dans le même chantier. ADR : **BE-010**.

1. **API** : plugin `admin` (migration `role`, `banned`…), `src/modules/auth/access-control.ts` (rôles `user`, `admin`), `@UserHasPermission` / `@Roles`, 403 Problem Details, 404 sur la ressource d'un autre ; commande `npm run user:promote -- <email>` ; usurpation désactivée ; `role` ajouté à l'export du compte (GLB-013) ; tests (403, accès admin, 404 IDOR). Exemple : une route d'administration minimale (liste des utilisateurs) ou une permission sur `notes`.
2. **Web** : `requirePermission` (`beforeLoad`), `useCan`, écrans 403, 404 ressource (`notFound()` sur une 404 de l'API), erreur serveur et hors ligne ; tests et E2E.
3. **Android**, puis **iOS** : écrans 403, 404, hors ligne ; rôle lu dans la session.
4. Agent `security` : vérifier qu'une route réservée a son décorateur et son test de refus.

## Tâche H — Schémas d'architecture

> ✅ Fait : `docs/architecture.md` (engineering-guidelines #31), à tenir à jour dans la même PR que tout changement d'architecture.

## Tâche E — Parité Docker et démarrage en une commande

> ✅ Fait : `npm run setup`, `npm run stack` (image de prod) + smoke en CI, `npm run dev:api` côté web, `/new-project` minimal avec explication de la passphrase. Reste en piste : cache de build GHA pour le job `stack`.

But : même image en dev, staging et prod ; rien à construire à la main en dev ; ne remplir que le minimum.

1. `npm run setup` (et `/new-project`) : crée `.env` depuis `.env.example`, génère les secrets de dev (`BETTER_AUTH_SECRET`…), lance `docker compose up` (PostgreSQL, Mailpit, API construite avec le même `Dockerfile` que la prod), applique les migrations.
2. `npm run dev` reste disponible pour le rechargement à chaud.
3. `/new-project` ne demande que nom, domaine, nom affiché ; il liste ce qui reste à saisir et **explique la passphrase du state** (`TF_STATE_PASSPHRASE`).

## Tâche F — Chaîne de déploiement prête (rapport devops du 2026-10-27)

> ✅ Fait : migrations au démarrage sous verrou (ADR #19), TLS base, ordre privilège → URL, `CONTAINER_ID`, domaine API + CNAME, bucket policy, `shared` en CI, clé `ci_plan`, outils épinglés. À vérifier en conditions réelles pendant la tâche D.

Bloquants d'un premier déploiement réel (`boilerplates/infra-scaleway/.claude/work/deploy-keys/devops.md`) :

1. Migrations : le runner GitHub ne joint pas la base privée → ADR (runner dans le réseau privé, migrations au démarrage, ou endpoint filtré).
2. TLS PostgreSQL (`sslmode=require` + CA Scaleway) refusé par `pg`.
3. `CONTAINER_ID` au format `fr-par/<uuid>` au lieu de l'UUID.
4. Domaine personnalisé de l'API (`scaleway_container_domain`) absent : auth web impossible.
5. Bucket policy du front qui bloquerait la clé `deploy-web` (à vérifier).
6. `envs/shared` hors CI ; clé en lecture seule pour les plans des PR ; scripts d'installation non épinglés ; secret de push de l'API au niveau repo ; vérification de fin de déploiement trop optimiste.

## Tâche D — Une app « jetable » de bout en bout

But : prouver que toute la chaîne marche avant le premier vrai projet. À faire une fois A, B et C fusionnées.

1. `/new-project` : nom `sandbox`, briques web + api + infra, thème `warm`, repos privés.
2. Créer une issue « Fonctionnalité » simple (ex. marquer une note comme favorite) et la dérouler avec `/feature`.
3. Me guider pour la checklist (Sentry, Scaleway, domaine si besoin), puis préparer le déploiement en **staging** : je lance moi-même `tofu apply` et je valide les déploiements.
4. Vérifier en staging : l'app s'ouvre, connexion et inscription, e-mail reçu, une erreur volontaire remonte dans Sentry avec une stack trace lisible (source maps), les migrations sont passées.
5. Noter chaque friction, puis corriger les boilerplates, `/new-project` ou la checklist (PR séparées).
6. Me proposer le démontage (`tofu destroy` par moi, suppression des repos et projets Sentry / Scaleway) et attendre mon accord.

## À la fin de chaque tâche

Résumé court : PR ouvertes, ce que je dois faire à la main, prochaine tâche.
