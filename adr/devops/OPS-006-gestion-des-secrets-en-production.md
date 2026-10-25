# OPS-006 : Gestion des secrets en production

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

Déclinaison opérationnelle de GLB-005. Les secrets doivent être stockés dans un endroit unique, chiffré, avec contrôle d'accès et historique, et injectés dans les applications sans passer par un poste de développeur.

## Décision

- Les secrets applicatifs de staging et production sont stockés dans **Scaleway Secret Manager** (ou l'équivalent OVH).
- OpenTofu crée les **emplacements** de secrets et les droits d'accès ; les **valeurs** ne sont jamais dans le code ni dans le state quand c'est évitable (saisies via la console/CLI ou générées par la plateforme).
- Les applications reçoivent leurs secrets en **variables d'environnement** injectées par la plateforme au démarrage.
- Les secrets nécessaires à la CI sont stockés dans les **secrets d'Environment GitHub** (`staging`, `production`), pas dans les secrets du repo.
- **Principe du moindre privilège** : chaque application et chaque pipeline a ses propres clés d'API, limitées à ce dont il a besoin. Pas de clé « admin » partagée.
- **Rotation** : mots de passe de base et clés d'API tierces renouvelés au moins une fois par an, et immédiatement au départ d'une personne ayant eu accès.
- Les secrets de développement local sont différents de ceux de production et sans valeur en dehors du poste.

## Alternatives envisagées

- **HashiCorp Vault / OpenBao auto-hébergé** : très complet (secrets dynamiques), mais lourd à opérer pour notre taille.
- **Fichiers `.env` sur les serveurs** : pas de contrôle d'accès ni d'historique.
- **SOPS dans le repo** : envisageable pour la config d'infra ; gestion des clés à prévoir.

## Conséquences

- ✅ Un seul endroit pour les secrets, accès traçable, rotation possible.
- ⚠️ Processus de rotation à documenter et à tenir.

## Mise en application

- Revue des accès aux secrets à chaque changement d'équipe.
- `gitleaks` en CI (GLB-005).
