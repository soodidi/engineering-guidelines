# BE-010 : Rôles et permissions

- **Statut** : Proposé
- **Date** : 2026-10-29
- **Périmètre** : backend (avec ses conséquences sur le web et le mobile)
- **Auteurs** : Mo, Claude
- **Liens** : BE-006, BE-004, FE-004, GLB-013, AND-004, IOS-004

## Contexte

BE-006 fixe le modèle d'autorisation : routes protégées par défaut, vérification d'appartenance sur la ressource, et rôles « via le plugin `admin` ou `organization` » de Better Auth. Les boilerplates ne font aujourd'hui que la vérification d'appartenance (une note n'est lisible que par son propriétaire) : pas de rôle, pas de permission, pas d'écran « accès refusé ». Dès qu'une app a un espace d'administration ou des actions réservées, chacun réinventerait son système.

Il faut une base unique pour l'API, le web et le mobile, sans dupliquer les règles dans trois langages : l'API décide, les clients n'utilisent les rôles que pour adapter l'affichage.

## Décision

**Outil**

- Les rôles et les permissions passent par le plugin **`admin` de Better Auth** et son **access control** (`createAccessControl`). Pas de librairie d'autorisation supplémentaire.
- Le rôle est porté par l'utilisateur (colonne `role` de `users`, ajoutée par le plugin) ; rôle par défaut : `user`. Rôles du boilerplate : `user` et `admin`.

**Déclaration**

- Les permissions sont déclarées **une seule fois**, dans `src/modules/auth/access-control.ts` : des « statements » par ressource (`note: ['read', 'update', 'delete']`…) et, pour chaque rôle, les actions accordées. Ce fichier est la référence ; une nouvelle action s'y ajoute avant d'être utilisée.
- Une permission dit ce qu'un rôle peut faire **sur un type de ressource**. Elle ne remplace jamais la vérification d'appartenance sur **la** ressource (BE-006) : un `user` peut modifier « ses » notes, pas celles des autres, et cela se vérifie dans le service ou le repository.

**API**

- Une route réservée DOIT porter un décorateur du module NestJS de Better Auth : `@UserHasPermission({ permissions })` de préférence, `@Roles([...])` pour une route d'administration. Le guard global les applique.
- Refus : **403** au format Problem Details (BE-004) quand l'utilisateur est connecté mais n'a pas la permission. Une ressource qui existe mais appartient à un autre utilisateur répond **404**, jamais 403, pour ne pas révéler son existence (IDOR).
- Les routes `/v1/auth/admin/*` du plugin (lister, bannir, changer de rôle, révoquer les sessions) ne sont ouvertes qu'au rôle `admin`. L'usurpation d'identité (`impersonate`) est **désactivée** par défaut : l'activer demande un ADR de projet (durée courte, journalisation).
- Le premier administrateur est promu par une commande lancée à la main (`npm run user:promote -- <email>`), jamais par une variable d'environnement ni à l'inscription.
- Un utilisateur banni n'a plus de session valide ; un changement de rôle s'applique à la requête suivante (pas de cache de session, BE-006).

**Web et mobile**

- Le rôle arrive avec la session. Les clients s'en servent **uniquement pour l'affichage** : cacher un bouton, une entrée de menu, une page. L'API reste la seule autorité.
- Web : `requirePermission(…)` dans `beforeLoad` d'une route réservée affiche l'écran « Accès refusé » ; un hook (`useCan`) cache un lien ou un bouton. Les deux **demandent à l'API** si l'utilisateur connecté a ces permissions (route `has-permission` du plugin `admin`), avec un cache vidé au changement de compte. Le web ne copie pas `access-control.ts` : avec un repo par brique, les deux copies divergeraient (choix de l'utilisateur, 2026-10-29).
- Les appels du client Better Auth vers des routes réservées sont traités comme les autres appels de l'API : 401 → retour à la connexion, 403 → « Accès refusé », API injoignable → écran « hors ligne ».
- Mobile : pas de copie des règles en Kotlin ou Swift ; l'affichage s'appuie sur le rôle de la session, et tout 403 de l'API affiche l'écran « Accès refusé ».

**Écrans d'erreur (web et mobile)**

- Chaque client DOIT avoir un écran ou un état pour : 401 (retour à la connexion, déjà en place), **403** (« Accès refusé », avec un retour à l'accueil), **404** sur une URL **et** sur une ressource absente, erreur serveur (avec « Réessayer ») et **hors ligne / API injoignable**.

**Équipes et multi-tenant**

- Le plugin `organization` (organisations, membres, invitations, rôles par organisation) n'est pas dans les boilerplates : c'est un module optionnel du catalogue (tâche C), à ajouter quand une app a des équipes.

## Alternatives envisagées

- **Copie d'`access-control.ts` dans le web** (`checkRolePermission` du client Better Auth, sans appel réseau) : prévu au départ. Écarté : un projet a un repo par brique, et rien ne garantirait que les deux copies restent identiques ; une permission vérifiée par l'API coûte un petit appel, mis en cache.
- **CASL** : règles isomorphes très expressives (conditions par attribut). Écarté : une dépendance et un paquet partagé de plus, inutilisables par les apps Kotlin et Swift, et en partie redondants avec l'access control de Better Auth. À reconsidérer pour une app aux règles conditionnelles complexes (ADR de projet).
- **Plugin `organization` dès le départ** : couvre les équipes. Écarté par défaut : trop lourd pour des apps d'abord personnelles ; disponible comme module optionnel.
- **Table de rôles maison** : écarté, Better Auth le fait déjà, avec l'administration des comptes (bannissement, révocation des sessions).

## Conséquences

- ✅ Une seule source pour les permissions, appliquée par l'API, lisible par le web.
- ✅ Administration des comptes (bannir, changer de rôle, révoquer) sans code maison.
- ⚠️ Une migration ajoute `role`, `banned`, `ban_reason`, `ban_expires` à `users` (et `impersonated_by` à `sessions`) : à relire comme toute migration (BE-003), et à exporter avec le compte (GLB-013).
- ⚠️ Les clients mobiles n'ont pas les règles fines : ils affichent selon le rôle et s'appuient sur les 403.
- 🔁 BE-006 renvoie à cet ADR pour les rôles.

## Mise en application

- `access-control.ts` dans `api-nestjs`, rôles `user` et `admin` ; tests : un `user` reçoit 403 sur une route d'administration, un `admin` y accède, un `user` reçoit 404 sur la ressource d'un autre.
- Web : `requirePermission`, `useCan`, écrans 403, 404 ressource et hors ligne, avec tests et E2E.
- Android et iOS : écrans 403, 404 et hors ligne ; rôle lu dans la session.
- Agent `security` : toute nouvelle route réservée a son décorateur et son test de refus.
