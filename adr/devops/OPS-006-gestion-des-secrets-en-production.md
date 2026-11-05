# OPS-006 : Gestion des secrets en production

- **Statut** : Proposé
- **Date** : 2026-10-27 (secrets saisis à la main : 2026-11-05)
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison opérationnelle de GLB-005. Les secrets doivent être stockés dans un endroit unique, chiffré, avec contrôle d'accès et historique, et injectés dans les applications sans passer par un poste de développeur.

## Décision

- Les secrets applicatifs **saisis par un humain** (clé d'une API tierce, par exemple) sont stockés dans les **secrets de l'environnement GitHub** du repo infra (`staging`, `production`, limités à `main`) (2026-11-05, choix de l'utilisateur). Le workflow `infra` les passe un par un à OpenTofu (`TF_VAR_…`), qui les donne au conteneur en `secret_environment_variables`. Jamais toute la liste des secrets d'un coup (`toJSON(secrets)`) : les clés de la CI finiraient dans le conteneur. Rotation : `gh secret set`, puis relancer le workflow `infra`.
- Les secrets **générés par OpenTofu** (mot de passe de la base, clé API Scaleway, secret de signature) PEUVENT passer directement dans les **variables secrètes du conteneur** (`secret_environment_variables`), sans Secret Manager. Leur valeur ne figure jamais dans le code ni dans les tfvars.
- Le state contient alors ces secrets : il DOIT être **chiffré par OpenTofu** (bloc `encryption`, `enforced = true`), en plus du chiffrement du bucket. La passphrase est stockée dans le gestionnaire de mots de passe et dans le secret GitHub `TF_STATE_PASSPHRASE` du repo infra. La perdre rend le state illisible.
- Les applications reçoivent leurs secrets en **variables d'environnement** injectées par la plateforme au démarrage.
- Les secrets nécessaires à la CI sont stockés dans les **secrets d'Environment GitHub** (`staging`, `production`), pas dans les secrets du repo.
- **Aucune PR n'atteint un secret** (2026-11-04) : une PR exécute la version du workflow de sa propre branche, donc un workflow ne peut pas protéger ses secrets contre elle. Les environnements qui portent des secrets (`staging`, `production`) DOIVENT être limités à la branche `main` (« Deployment branches ») ; `/new-project` les crée ainsi. Aucun secret au niveau du repo : n'importe quelle branche poussée, sans PR, pourrait le lire (clé du registre et token Sentry passent par l'environnement `staging`). Les PR ne lancent que des vérifications sans secret. Pour l'infra, aucun `plan` sur les PR : tout plan lit le state `iam` (toutes les clés) avec une passphrase commune ; le plan s'affiche après fusion, dans le job qui l'applique.
- Pour un repo privé, ces règles d'environnement demandent **GitHub Pro** (ou Team) ; la validation obligatoire avant un déploiement (reviewers) n'existe pas pour un repo privé hors Enterprise. La production ne part donc que d'un lancement manuel depuis `main` par le propriétaire du repo (OPS-004).
- Limite connue : staging et production partagent le projet Scaleway et la clé de la CI ; du code fusionné sur `main` peut donc agir sur la production. Le lancement manuel n'est pas une barrière de sécurité. Séparer les projets Scaleway : décision en attente.
- Filet contre les erreurs dans la CI de l'infra (pas contre du code malveillant : une PR peut modifier le workflow) : refus de `nonsensitive`, `data "external"`, `data "http"`, `provisioner`, `local-exec`, d'un `api_url` de fournisseur, des fichiers `*.tf.json` et `*.tofu.json`, de tout fournisseur hors liste blanche et des modules non locaux. Un lancement manuel par un autre que le propriétaire du repo échoue.
- **Principe du moindre privilège** : chaque application et chaque pipeline a ses propres clés d'API, limitées à ce dont il a besoin. Pas de clé « admin » partagée.
- Chez Scaleway, applications, politiques et clés IAM appartiennent à l'**organisation**. Elles sont décrites dans `envs/iam`, **appliqué à la main** avec une clé personnelle qui a les droits IAM, une fois par projet et à chaque rotation. La clé de la CI n'a jamais de droit IAM : elle ne doit pas pouvoir fabriquer d'autres clés.
- **Rotation** : mots de passe de base et clés d'API tierces renouvelés au moins une fois par an, et immédiatement au départ d'une personne ayant eu accès.
- Les secrets de développement local sont différents de ceux de production et sans valeur en dehors du poste.

## Alternatives envisagées

- **HashiCorp Vault / OpenBao auto-hébergé** : très complet (secrets dynamiques), mais lourd à opérer pour notre taille.
- **Fichiers `.env` sur les serveurs** : pas de contrôle d'accès ni d'historique.
- **SOPS dans le repo** : envisageable pour la config d'infra ; gestion des clés à prévoir.
- **Tous les secrets dans Secret Manager**, y compris ceux générés par OpenTofu : la valeur passerait quand même par le state au moment de sa création, et les conteneurs ne lisent pas une référence Secret Manager. On ajoute une étape sans gain réel.
- **Secrets saisis à la main dans Scaleway Secret Manager**, lus par OpenTofu (décision initiale) : les Serverless Containers ne lisent pas Secret Manager (seuls les Serverless Jobs le font) ; il fallait créer le secret par OpenTofu, saisir sa valeur ailleurs, puis réappliquer, et la valeur finissait quand même dans le state. Écarté le 2026-11-05 pour un seul endroit, GitHub, et une commande. À reconsidérer si un Serverless Job doit lire les mêmes secrets.
- **Droits IAM pour la clé de la CI** : elle pourrait créer des clés admin. Écarté.

## Conséquences

- ✅ Un seul endroit pour les secrets, accès traçable, rotation possible.
- ⚠️ Processus de rotation à documenter et à tenir.
- ⚠️ Le state contient des secrets : sa passphrase de chiffrement devient un secret critique.
- ⚠️ `envs/iam` demande une action humaine avec une clé admin, une fois par projet et à chaque rotation.

## Mise en application

- Revue des accès aux secrets à chaque changement d'équipe.
- `gitleaks` en CI (GLB-005).
- Bloc `encryption` avec `enforced = true` dans chaque environnement OpenTofu (revue de code) ; la CI échoue sans `TF_STATE_PASSPHRASE`.
