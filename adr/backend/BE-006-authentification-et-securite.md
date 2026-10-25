# BE-006 : Authentification, autorisation et sécurité applicative

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

L'API sert des navigateurs (où les cookies sont le mécanisme le plus sûr) et des apps mobiles natives (où les cookies sont peu pratiques). L'authentification est un domaine où les erreurs maison sont fréquentes et graves.

## Décision

**Ne pas réinventer l'authentification**
- Hachage des mots de passe : **Argon2id** uniquement.
- On s'appuie sur une solution éprouvée plutôt que d'écrire le protocole soi-même : librairie d'auth reconnue intégrée au backend, ou fournisseur d'identité OIDC (Keycloak auto-hébergé, ou un service managé hébergé en Europe) quand il y a SSO, multi-apps ou exigences fortes.

**Sessions**
- **Web** : session en cookie `HttpOnly`, `Secure`, `SameSite=Lax` (ou `Strict`), pas de token dans `localStorage`. Protection CSRF sur les requêtes qui modifient l'état.
- **Mobile** : *access token* court (≤ 15 min) + *refresh token* **rotatif** à usage unique, stocké dans le Keystore Android / Keychain iOS (AND-004, IOS-004). La réutilisation d'un refresh token révoque toute la famille de tokens.
- Les sessions et refresh tokens sont révocables côté serveur (déconnexion, changement de mot de passe).

**Autorisation**
- Toute route est **protégée par défaut** (guard global) ; les routes publiques sont marquées explicitement (`@Public()`).
- Vérification des droits dans le service **sur la ressource** (ex : la facture appartient-elle à l'organisation de l'utilisateur ?), pas seulement sur le rôle. C'est la première cause de fuite de données (IDOR).
- Modèle par défaut : rôles (RBAC) + vérification d'appartenance.

**Sécurité HTTP**
- CORS : liste blanche explicite des origines, jamais `*` avec credentials.
- En-têtes de sécurité (`@fastify/helmet`).
- Rate limiting sur l'API, renforcé sur login, inscription, mot de passe oublié.
- Les erreurs de login sont génériques (« identifiants invalides ») pour ne pas révéler l'existence d'un compte.
- Données personnelles : minimiser, ne jamais les écrire dans les logs (BE-007), respecter le RGPD (durées de conservation, export, suppression).

## Alternatives envisagées

- **JWT longs en `localStorage` pour le web** : vulnérable au XSS, révocation difficile.
- **Auth 100 % maison** : risques élevés pour un gain faible.

## Conséquences

- ✅ Une stratégie adaptée à chaque type de client, sur un même backend.
- ⚠️ Deux mécanismes de session à maintenir (cookie web, tokens mobile).

## Mise en application

- Guard d'authentification global + décorateur `@Public()`.
- Tests d'intégration obligatoires sur les règles d'accès (un utilisateur ne voit pas les données d'une autre organisation).
- Checklist OWASP ASVS (niveau 1) revue à chaque mise en production majeure.
- 2 approbations sur tout changement d'auth (GLB-003).
