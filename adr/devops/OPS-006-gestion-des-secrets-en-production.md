# OPS-006 : Gestion des secrets en production

- **Statut** : Proposé
- **Date** : 2026-10-27
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison opérationnelle de GLB-005. Les secrets doivent être stockés dans un endroit unique, chiffré, avec contrôle d'accès et historique, et injectés dans les applications sans passer par un poste de développeur.

## Décision

- Les secrets applicatifs **saisis par un humain** (clé d'une API tierce, par exemple) sont stockés dans **Scaleway Secret Manager** (ou l'équivalent OVH). OpenTofu crée leur emplacement et les droits d'accès, jamais leur valeur.
- Les secrets **générés par OpenTofu** (mot de passe de la base, clé API Scaleway, secret de signature) PEUVENT passer directement dans les **variables secrètes du conteneur** (`secret_environment_variables`), sans Secret Manager. Leur valeur ne figure jamais dans le code ni dans les tfvars.
- Le state contient alors ces secrets : il DOIT être **chiffré par OpenTofu** (bloc `encryption`, `enforced = true`), en plus du chiffrement du bucket. La passphrase est stockée dans le gestionnaire de mots de passe et dans le secret GitHub `TF_STATE_PASSPHRASE` du repo infra. La perdre rend le state illisible.
- Les applications reçoivent leurs secrets en **variables d'environnement** injectées par la plateforme au démarrage.
- Les secrets nécessaires à la CI sont stockés dans les **secrets d'Environment GitHub** (`staging`, `production`), pas dans les secrets du repo.
- **Principe du moindre privilège** : chaque application et chaque pipeline a ses propres clés d'API, limitées à ce dont il a besoin. Pas de clé « admin » partagée.
- Chez Scaleway, applications, politiques et clés IAM appartiennent à l'**organisation**. Elles sont décrites dans `envs/iam`, **appliqué à la main** avec une clé personnelle qui a les droits IAM, une fois par projet et à chaque rotation. La clé de la CI n'a jamais de droit IAM : elle ne doit pas pouvoir fabriquer d'autres clés.
- **Rotation** : mots de passe de base et clés d'API tierces renouvelés au moins une fois par an, et immédiatement au départ d'une personne ayant eu accès.
- Les secrets de développement local sont différents de ceux de production et sans valeur en dehors du poste.

## Alternatives envisagées

- **HashiCorp Vault / OpenBao auto-hébergé** : très complet (secrets dynamiques), mais lourd à opérer pour notre taille.
- **Fichiers `.env` sur les serveurs** : pas de contrôle d'accès ni d'historique.
- **SOPS dans le repo** : envisageable pour la config d'infra ; gestion des clés à prévoir.
- **Tous les secrets dans Secret Manager**, y compris ceux générés par OpenTofu : la valeur passerait quand même par le state au moment de sa création, et les conteneurs ne lisent pas une référence Secret Manager. On ajoute une étape sans gain réel.
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
