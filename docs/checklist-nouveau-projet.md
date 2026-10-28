# Checklist « nouveau projet »

Comptes, secrets et réglages à faire **à la main** pour chaque nouveau projet. `/new-project` affiche cette liste à la fin, coche ce qu'il a déjà fait et ouvre dans chaque repo une issue « Mise en route » avec le reste.

À relire au démarrage d'un projet et **avant le premier déploiement**.

## Conventions

- `<repo>` : nom du repo GitHub (`<nom>-web`, `<nom>-api`, `<nom>-infra`…, ou `<nom>` s'il n'y a qu'une brique).
- Les commandes `gh` lisent la valeur sur l'entrée standard : ne jamais la taper dans la conversation avec l'IA ni la laisser dans l'historique du shell.
- Un secret d'environnement (`--env staging`) n'est visible que des jobs qui déclarent cet environnement. Les noms ci-dessous sont ceux attendus par les workflows des boilerplates : les retrouver avec `grep -rhoE '(secrets|vars)\.[A-Za-z0-9_]+' .github/workflows | sort -u`.
- Chaque valeur secrète est aussi rangée dans le **gestionnaire de mots de passe**, dans une entrée au nom du projet (GLB-005).

## Tous les projets

- [ ] Repo GitHub créé sous `soodidi`, squash merge seul, suppression des branches fusionnées, fusion automatique activée.
- [ ] `main` protégée : PR obligatoire, jobs CI requis, branche à jour, force-push interdit, règles appliquées aux admins (GLB-011).
- [ ] Labels `feature` et `security` créés (`bug` existe par défaut).
- [ ] Renovate actif sur le repo (<https://developer.mend.io>, si l'installation est limitée à certains repos) (GLB-008).
- [ ] Entrée du projet créée dans le gestionnaire de mots de passe.

## Sentry (FE-009, BE-007)

Organisation `soodidi`, région UE, déjà créée. Un projet Sentry par brique.

- [ ] Projets créés : `<nom>-web` (React), `<nom>-api` (Node.js / NestJS). Android et iOS : quand le SDK Sentry sera intégré aux boilerplates mobiles.
- [ ] Alerte « nouvelle erreur » de chaque projet envoyée par e-mail.
- [ ] Web, variables et secret du repo (envoi des source maps au build) :

  ```bash
  gh variable set SENTRY_ORG -R soodidi/<repo> --body soodidi
  gh variable set SENTRY_PROJECT -R soodidi/<repo> --body <nom>-web
  gh secret set SENTRY_AUTH_TOKEN -R soodidi/<repo>        # token d'organisation existant
  ```

- [ ] Web, DSN par environnement (injecté dans `config.json` au déploiement) :

  ```bash
  gh variable set SENTRY_DSN -R soodidi/<repo> --env staging --body <dsn-web>
  gh variable set SENTRY_DSN -R soodidi/<repo> --env production --body <dsn-web>
  ```

- [ ] API : DSN dans `api_sentry_dsn` de `envs/<env>/<env>.auto.tfvars` du repo infra (variable d'environnement `SENTRY_DSN` du conteneur).

## Scaleway (OPS-003 à OPS-006)

Le compte Scaleway existe ; chaque projet a son **projet Scaleway** pour isoler droits et factures.

- [ ] Projet Scaleway `<nom>` créé ; noter son ID et celui de l'organisation.
- [ ] **Alerte budget** sur le projet (Console → Billing → Budget alerts), avec un seuil bas au départ.
- [ ] Bucket d'état OpenTofu créé à la main (privé, versioning activé), nom reporté à la place de `CHANGE-ME-tfstate` dans les `main.tf` de l'infra.
- [ ] **Passphrase de chiffrement du state** (16 caractères au moins) rangée dans le gestionnaire de mots de passe et dans le secret `TF_STATE_PASSPHRASE` des quatre environnements du repo infra (OPS-006).
- [ ] `envs/iam` appliqué **à la main** avec ta clé personnelle (droits IAM) : il crée la clé de la CI, **limitée au projet** et sans droit IAM, et les clés SMTP. Récupérer la clé de la CI avec `tofu -chdir=envs/iam output -raw ci_access_key` et `ci_secret_key` (OPS-006).
- [ ] Environnements GitHub `staging` et `production` dans chaque repo qui déploie, **reviewers obligatoires sur `production`** :

  ```bash
  gh api -X PUT repos/soodidi/<repo>/environments/staging
  gh api -X PUT repos/soodidi/<repo>/environments/production \
    -F 'reviewers[][type]=User' -F "reviewers[][id]=$(gh api user -q .id)"
  ```

- [ ] Repo infra : environnements `staging-plan` et `production-plan` (sans reviewers) en plus, puis pour chacun des quatre :

  ```bash
  gh secret set SCW_ACCESS_KEY -R soodidi/<nom>-infra --env <env>
  gh secret set SCW_SECRET_KEY -R soodidi/<nom>-infra --env <env>
  gh variable set SCW_DEFAULT_PROJECT_ID -R soodidi/<nom>-infra --env <env> --body <id-projet>
  gh variable set SCW_DEFAULT_ORGANIZATION_ID -R soodidi/<nom>-infra --env <env> --body <id-organisation>
  gh secret set TF_STATE_PASSPHRASE -R soodidi/<nom>-infra --env <env>
  ```

- [ ] **Une clé par repo** (OPS-006). Les clés sortent de `envs/iam` ; ne jamais mettre la clé de la CI infra dans un repo applicatif :

  | Repo | Clé | Commande |
  |---|---|---|
  | infra, environnements `staging` et `production` (apply) | CI infra (tous les produits du projet) | `tofu -chdir=envs/iam output -raw ci_access_key` / `ci_secret_key` |
  | infra, environnements `staging-plan` et `production-plan` (plans des PR) | `ci-plan` (lecture seule) | `tofu -chdir=envs/iam output -raw ci_plan_access_key` / `ci_plan_secret_key` |
  | API | `deploy-api` (registre et conteneurs) | `tofu -chdir=envs/iam output -json deploy_access_keys` / `deploy_secret_keys`, entrée `api` |
  | web | `deploy-web` (Object Storage) | mêmes sorties, entrée `web` |

- [ ] Repo API, niveau repo (push de l'image dans le registre, clé `deploy-api`) :

  ```bash
  gh variable set REGISTRY_IMAGE -R soodidi/<nom>-api --body rg.fr-par.scw.cloud/<namespace>/api
  gh secret set SCW_SECRET_KEY -R soodidi/<nom>-api
  ```

- [ ] Repo API, par environnement (`staging`, `production`), après le premier `tofu apply` (clé `deploy-api`) :

  ```bash
  gh secret set SCW_ACCESS_KEY -R soodidi/<nom>-api --env <env>
  gh secret set SCW_SECRET_KEY -R soodidi/<nom>-api --env <env>
  gh variable set SCW_DEFAULT_PROJECT_ID -R soodidi/<nom>-api --env <env> --body <id-projet>
  gh variable set CONTAINER_ID -R soodidi/<nom>-api --env <env> --body "$(tofu -chdir=envs/<env> output -raw api_container_id)"
  ```

  Pas de `DATABASE_URL` dans GitHub : l'API applique ses migrations au démarrage, dans le réseau privé (BE-003).

- [ ] Repo web, par environnement, après le premier `tofu apply` (clé `deploy-web`) :

  ```bash
  gh secret set SCW_ACCESS_KEY -R soodidi/<nom>-web --env <env>
  gh secret set SCW_SECRET_KEY -R soodidi/<nom>-web --env <env>
  gh variable set BUCKET -R soodidi/<nom>-web --env <env> --body <bucket>
  gh variable set API_URL -R soodidi/<nom>-web --env <env> --body https://<domaine-api>
  ```

## Domaine

- [ ] Nom de domaine acheté (registrar en UE de préférence), au nom de l'éditeur.
- [ ] Le domaine est **obligatoire dès le staging** dès qu'il y a de l'auth web (BE-006) : l'API DOIT être sur le même domaine que le front (`api.app.<domaine>` et `app.<domaine>`, `api.staging.app.<domaine>` et `staging.app.<domaine>`). Sur l'URL par défaut du conteneur Scaleway (`*.scw.cloud`), le navigateur n'envoie pas le cookie de session et la connexion web ne marche pas.
- [ ] **Edge Services** activé sur le projet Scaleway (CDN et HTTPS du front), avant le premier apply de staging.
- [ ] DNS : l'app (`app.<domaine>`, `staging.app.<domaine>`) vers Edge Services ; l'API (`api.…`) en CNAME vers `tofu -chdir=envs/<env> output api_dns_target`, obtenu par un premier apply ciblé (`-target=module.api.scaleway_container.this`, voir le README de l'infra) ; `web_domain`, `web_origin` et `api_url` reportés dans les tfvars.
- [ ] E-mails d'envoi (BE-009) : sous-domaine d'envoi (`mail.<domaine>`) déclaré dans Scaleway TEM ; enregistrements **SPF**, **DKIM** et **DMARC** (`p=none` au départ) publiés et vérifiés.
- [ ] Tfvars de staging et production : `mail_from` (adresse du sous-domaine d'envoi) ; en staging, `mail_allowed_recipients` avec tes propres adresses. `SMTP_URL` est généré par OpenTofu (`envs/iam`) : rien à saisir.

## Authentification (BE-006)

- [ ] `api_url` sur le même domaine que le front (voir « Domaine »). C'est la contrainte la plus structurante de l'auth web.
- [ ] `app_name` renseigné dans les tfvars : c'est le nom affiché dans les e-mails.
- [ ] `BETTER_AUTH_SECRET` : rien à faire, OpenTofu le génère pour chaque environnement.
- [ ] **En priorité au premier déploiement en staging** : se connecter, puis vérifier dans la table `sessions` que `ip_address` est ta vraie IP publique, et pas une adresse interne (`10.…`, `100.64.…`, `172.16.…`). Si c'est une adresse interne, il y a plus de proxys que prévu devant l'API : augmenter `TRUST_PROXY_HOPS`. Sinon, tous les utilisateurs partagent le même compteur de rate limiting, et un seul attaquant bloque la connexion de tout le monde (5 essais par minute).
- [ ] Parcours complet testé en staging : inscription, e-mail de vérification reçu, connexion, mot de passe oublié, déconnexion.

## Mobile (Android, iOS)

À lancer **tôt** : les comptes demandent une validation de plusieurs jours.

- [ ] Compte **Apple Developer** (99 €/an).
- [ ] Compte **Google Play Console** (25 $, une fois).
- [ ] Identifiant d'app réservé dans les deux consoles (le même que celui choisi dans `/new-project`).
- [ ] URL de production dans les apps : `API_BASE_URL` et `WEB_BASE_URL` (Android : `app/build.gradle.kts`, buildType `release` ; iOS : `project.yml`). `WEB_BASE_URL` DOIT être exactement le `web_origin` de production, sinon l'inscription et le mot de passe oublié échouent (`INVALID_CALLBACK_URL`).
- [ ] Fiches store : nom, description, captures, icône, catégorie, contact, lien vers la politique de confidentialité, questionnaire de données (Data safety, App Privacy).

## Légal (RGPD)

- [ ] Mentions légales, politique de confidentialité et CGU remplies (plus aucun champ entre crochets comme `[NOM DE L'ÉDITEUR]`) et publiées.
- [ ] Liste des sous-traitants à jour dans la politique de confidentialité (Scaleway, Sentry, fournisseur d'e-mail…).

## Avant le premier déploiement

- [ ] Toutes les cases ci-dessus des briques concernées sont cochées.
- [ ] Le workflow `deploy` passe en staging ; l'app s'ouvre, une erreur volontaire remonte dans Sentry avec une stack trace lisible.
