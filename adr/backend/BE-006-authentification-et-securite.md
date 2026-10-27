# BE-006 : Authentification, autorisation et sécurité applicative

- **Statut** : Proposé
- **Date** : 2026-10-27
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

L'API sert des navigateurs (où les cookies sont le mécanisme le plus sûr) et des apps mobiles natives (où les cookies sont peu pratiques). L'authentification est un domaine où les erreurs maison sont fréquentes et graves. Les projets sont menés par un développeur seul : chaque service à exploiter et chaque ligne de code d'auth écrite à la main coûtent cher.

## Décision

**Ne pas réinventer l'authentification**

- On DOIT utiliser **Better Auth**, intégré au backend, avec l'adaptateur Drizzle : les comptes et les sessions vivent dans notre PostgreSQL (BE-003), sans sous-traitant de plus.
- On NE DOIT PAS écrire soi-même le protocole (émission, rotation ou vérification de tokens, réinitialisation de mot de passe). Un besoin que Better Auth ne couvre pas passe par un ADR.
- On passe à un fournisseur d'identité OIDC (Zitadel ou Keycloak auto-hébergé, ou un service managé hébergé en Europe) quand il y a du SSO, plusieurs apps qui partagent les comptes, ou des exigences fortes. Cela passe par un ADR qui remplace celui-ci.
- Hachage des mots de passe : **Argon2id** uniquement. Better Auth utilise scrypt par défaut : on DOIT fournir `emailAndPassword.password.hash/verify` avec `@node-rs/argon2`.

**Intégration NestJS**

- Module `@thallesp/nestjs-better-auth` (maintenu par la communauté ; son support de Fastify est en bêta). Avant d'adopter une nouvelle version majeure de NestJS ou du module, un essai DOIT valider l'inscription, la connexion, la déconnexion et CORS sur Fastify.
- `trustedOrigins` DOIT être une liste (le repli CORS du module ne gère pas les fonctions).

**Sessions**

- Better Auth gère des **sessions opaques**, stockées en base, vérifiées côté serveur à chaque requête et révocables immédiatement.
- **Web** : session en cookie `HttpOnly`, `Secure`, `SameSite=Lax` (ou `Strict`), pas de token dans `localStorage`.
- **Mobile** : le token de session est envoyé en `Authorization: Bearer` (plugin `bearer`) et stocké dans le Keystore Android / Keychain iOS (AND-004, IOS-004). Pas de couple access/refresh token.
- Durées : `expiresIn` ≤ 30 jours, renouvelé à l'usage (`updateAge`). Better Auth ne borne pas une session renouvelée en continu : on DOIT imposer une **durée de vie absolue** (90 jours au plus depuis la connexion, ensuite reconnexion obligatoire), vérifiée dans un hook de session.
- `session.cookieCache` NE DOIT PAS être activé, ou alors avec `maxAge` ≤ 60 s : pendant ce délai, une session révoquée reste acceptée.
- Les sessions sont révoquées côté serveur à la déconnexion, au changement de mot de passe (`revokeOtherSessions`) et à la suppression du compte.
- Better Auth stocke le token de session **en clair** en base : une fuite de la table `sessions` donne accès aux comptes. L'accès à la base est donc restreint au backend, les sauvegardes DOIVENT être chiffrées, et en cas de fuite toutes les sessions sont révoquées.

**Autorisation**

- Toute route est **protégée par défaut** (guard global du module) ; les routes publiques sont marquées explicitement (`@Public()` / `@AllowAnonymous()`).
- Vérification des droits dans le service **sur la ressource** (ex : la facture appartient-elle à l'organisation de l'utilisateur ?), pas seulement sur le rôle. C'est la première cause de fuite de données (IDOR), et aucune librairie d'auth ne la fait à notre place.
- Modèle par défaut : rôles (RBAC, plugin `admin` ou `organization`) + vérification d'appartenance.

**Sécurité HTTP**

- CORS : liste blanche explicite des origines, jamais `*` avec credentials.
- CSRF : Better Auth vérifie l'origine sur ses propres routes. Les routes métier authentifiées par cookie qui modifient l'état DOIVENT aussi rejeter une origine hors liste blanche (vérification de `Origin` ou de `Sec-Fetch-Site`), en plus de `SameSite`.
- En-têtes de sécurité (`@fastify/helmet`).
- Rate limiting : celui de Better Auth est en mémoire par défaut et ne couvre que ses routes. On DOIT lui donner un stockage partagé (`storage: "database"` ou stockage secondaire) dès qu'il y a plus d'une instance, configurer l'IP réelle derrière le load balancer (`ipAddressHeaders` ou `trustedProxies`), garder des limites strictes sur connexion, inscription et mot de passe oublié, et limiter le reste de l'API avec `@fastify/rate-limit`.
- Les erreurs de login sont génériques (« identifiants invalides »). L'inscription ne DOIT pas révéler qu'un e-mail existe : `requireEmailVerification: true` (ou `autoSignIn: false`), sans quoi Better Auth renvoie une `422`. Le mot de passe oublié répond de la même façon que le compte existe ou non.
- Données personnelles : minimiser, ne jamais les écrire dans les logs (BE-007), respecter le RGPD (durées de conservation, export, suppression). Le fournisseur d'envoi d'e-mails (vérification, mot de passe oublié) figure dans la liste des sous-traitants.

## Alternatives envisagées

- **JWT longs en `localStorage` pour le web** : vulnérable au XSS, révocation difficile.
- **Auth 100 % maison** : risques élevés pour un gain faible.
- **Fournisseur OIDC dès le départ (Zitadel, Keycloak)** : couvre tout, dont la rotation des refresh tokens, mais c'est un service de plus à exploiter, sauvegarder et mettre à jour. Gardé pour le SSO et le multi-apps.
- **Access token court + refresh token rotatif sur mobile** : détecte la réutilisation d'un token volé, mais Better Auth ne le fait pas nativement. L'ajouter reviendrait à écrire du code d'auth sensible. Une session opaque vérifiée côté serveur se révoque immédiatement, ce qui couvre l'essentiel du besoin.

## Conséquences

- ✅ Un seul mécanisme de session (opaque, côté serveur) pour le web et le mobile ; seul le transport change (cookie ou en-tête `Bearer`).
- ✅ Les comptes sont dans notre base : une migration vers un fournisseur OIDC reste possible (import des hachages Argon2id).
- ⚠️ Pas de détection de vol de token par rotation : un token volé reste valable jusqu'à sa révocation ou son expiration. Atténué par le Keychain/Keystore, les durées bornées et la révocation.
- ⚠️ Tokens de session en clair en base : la base devient une cible plus sensible.
- ⚠️ Dépendance à un module NestJS communautaire, avec un support de Fastify en bêta.

## Mise en application

- Guard d'authentification global + décorateur `@Public()`.
- Tests d'intégration obligatoires sur les règles d'accès (un utilisateur ne voit pas les données d'une autre organisation), sur la révocation (une session révoquée est refusée) et sur la durée de vie absolue.
- La configuration Better Auth (hachage, durées, `cookieCache`, rate limiting, `requireEmailVerification`) vit dans un seul fichier, relu à chaque changement.
- Checklist OWASP ASVS (niveau 1) revue à chaque mise en production majeure.
- 2 approbations sur tout changement d'auth (GLB-003).
