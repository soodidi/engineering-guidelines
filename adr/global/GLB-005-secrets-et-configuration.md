# GLB-005 : Secrets et configuration

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Un secret commité dans Git est compromis, même supprimé ensuite : il reste dans l'historique. Une configuration éparpillée ou non validée provoque des pannes au démarrage, souvent en production.

## Décision

- Aucun secret (clé d'API, mot de passe, token, clé privée) NE DOIT être commité, y compris dans les tests, les exemples ou les fichiers de CI.
- La configuration DOIT passer par des **variables d'environnement** ([12-factor](https://12factor.net/config)).
- Chaque projet DOIT fournir un `.env.example` documentant toutes les variables, sans valeurs réelles.
- `.env`, `.env.local`, `*.pem`, `*.p12`, `google-services.json` de prod, etc. DOIVENT être dans `.gitignore`.
- La configuration DOIT être **validée au démarrage** : l'application refuse de démarrer si une variable obligatoire manque ou est invalide.
- Secrets de production : stockés dans le gestionnaire de secrets du cloud (OPS-006), jamais sur un poste.
- **Frontend et mobile** : tout ce qui est embarqué dans le bundle ou le binaire est public. On n'y met JAMAIS de secret, seulement des identifiants publics (clé publique d'analytics, URL d'API).
- En cas de fuite : **révoquer d'abord**, nettoyer l'historique ensuite.

## Alternatives envisagées

- **Fichiers de config chiffrés dans le repo (SOPS, git-crypt)** : viable, mais ajoute de la complexité de gestion de clés. Possible plus tard pour l'infra.

## Conséquences

- ✅ Pas de secret dans l'historique, configuration explicite et vérifiée.
- ⚠️ Un peu de mise en place par projet (schéma de validation, `.env.example`).

## Mise en application

- `gitleaks` en hook pre-commit et en job CI.
- GitHub Secret Scanning + Push Protection activés.
- Validation de config : Zod (front/back, voir BE-005), équivalent typé côté mobile.
