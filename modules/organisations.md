# Module : organisations et équipes

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-004, BE-005, BE-006, BE-008, BE-009, BE-010, GLB-013, FE-002, FE-004, AND-002, AND-004, IOS-002, IOS-004

## Quand l'utiliser

Plusieurs utilisateurs partagent des données dans un **espace commun** : une famille, une association, une équipe, un client B2B. Chaque donnée appartient alors à une organisation, et les droits dépendent du rôle **dans cette organisation**.

S'en passer quand le partage reste ponctuel (partager une note avec une personne : une table de partage suffit) ou quand les rôles globaux de BE-010 (`user`, `admin`) couvrent le besoin.

## Recommandation

**Plugin `organization` de Better Auth**, comme le prévoit BE-010 : organisations, membres, invitations par e-mail, rôles par organisation (`owner`, `admin`, `member`) et contrôle d'accès déclaré comme `access-control.ts`. Il cohabite avec le plugin `admin` : le rôle global sert à l'administration de l'app, le rôle dans l'organisation sert aux données partagées.

Pourquoi : même librairie que l'auth (sessions, e-mails, rate limiting), tables et routes déjà écrites, garde-fous déjà en place (une invitation n'est acceptée que par la session dont l'adresse est celle de l'invitation ; le dernier `owner` ne peut ni partir, ni être retiré, ni être rétrogradé).

**L'organisation est dans l'URL des routes de données** (`/v1/orgs/:orgId/notes`), pas déduite de l'organisation active de la session. L'organisation active est partagée par tous les onglets : un onglet resté sur A écrirait dans B si B a été choisie ailleurs. Elle ne sert qu'à choisir l'organisation affichée par défaut.

Options à fixer au premier usage :

- `requireEmailVerificationOnInvitation: true` : sans elle, un compte **non vérifié** créé avec l'adresse invitée accepterait l'invitation ;
- `invitationExpiresIn` (48 h par défaut), `membershipLimit`, `invitationLimit`, `organizationLimit` ;
- `teams` (sous-équipes) seulement si le besoin est réel ;
- rôles et permissions propres à l'app dans un `ac` dédié, en partant des déclarations par défaut du plugin.

## Alternatives

- **Table maison** (`memberships`) : simple pour un seul niveau de partage, mais invitations, rôles et cas limites à réécrire.
- **Fournisseur d'identité avec organisations** (Zitadel, Keycloak) : pour du B2B avec SSO d'entreprise ; hors du modèle de BE-006.

## Intégration par brique

**API**

- Migration générée pour les tables du plugin, au pluriel comme les autres tables d'auth (`organizations`, `members`, `invitations`, colonne de l'organisation active sur `sessions`). Elles appartiennent au module `auth` (BE-002).
- Chaque table de données partagées porte `organization_id`. Le module métier ne lit jamais `members` : il passe par un service que le module `auth` **ajoute** à son `index.ts` (adhésion et permission d'un utilisateur dans une organisation).
- **Guard d'organisation** propre à l'app (`@OrgPermission({ permissions })`, BE-010 : toute route réservée porte un décorateur) qui lit `:orgId` dans l'URL et appelle `auth.api.hasPermission({ headers, body: { permissions, organizationId } })`, **toujours avec les en-têtes de la requête et l'`organizationId` de l'URL** :
  - non-membre → **404**, comme pour l'IDOR (BE-006). `hasPermission` répond 401 à un non-membre : le guard le convertit, sinon les clients prendraient ce 401 pour une session expirée et déconnecteraient l'utilisateur ;
  - membre sans la permission → **403**.
- Les décorateurs du module NestJS (`@MemberHasPermission`, `@OrgRoles`, `@RequireActiveOrg`) vérifient l'organisation **active** : ne pas les utiliser sur une route dont l'organisation est dans l'URL. `@UserHasPermission` et `@Roles` lisent le rôle **global** : jamais pour les données d'une organisation.
- Le repository filtre toujours par `organization_id` (celui de l'URL, déjà vérifié par le guard).
- Invitations : `sendInvitationEmail` branché sur `Mailer` (BE-009), lien vers le web, noms d'organisation et d'invitant échappés dans l'e-mail. Débit limité (`customRules` du rate limiting de Better Auth) sur `/organization/create` et `/organization/invite-member` : sinon n'importe quel compte fait envoyer des e-mails, au nom de l'app, à n'importe quelle adresse.
- Le hook `before` de `auth.config.ts` valide aussi les identifiants des routes `/organization/*` (UUID), comme pour `/admin/*` : un id mal formé donnerait un 500.
- Hooks du plugin (`organizationHooks`) pour les règles de l'app : limiter la création, et effacer les données des modules à la suppression d'une organisation (`beforeDeleteOrganization`), par un contrat par organisation (voir Données personnelles).
- Les invitations expirées s'ajoutent à la purge du module `auth`.
- Routes du plugin à classer comme celles du plugin `admin` (ouvertes, fermées), avec le même test garde-fou que `access-control.spec.ts`.
- Destinataires d'un événement d'organisation (e-mail, push, temps réel) calculés **au moment de l'envoi**, pour ne pas prévenir un membre retiré entre-temps.

**Web**

- Organisation courante dans l'URL des pages (`/orgs/$orgId/...`) ; sélecteur dans l'en-tête ; changer d'organisation change de page et **vide le cache** (`resetUserCache()`), comme au changement de compte.
- Pages : membres, invitations, rôles ; acceptation d'une invitation après connexion avec la bonne adresse.
- Permissions dans l'organisation : un hook dédié (`useOrgCan`) qui interroge `/organization/has-permission` avec l'`organizationId` ; `useCan` reste pour le rôle global. Réponses validées avec Zod (FE-002).

**Android / iOS**

- Organisation courante choisie dans « Mon compte » (par défaut : l'organisation active de la session) et passée dans l'URL des appels ; listes rechargées au changement.
- Invitations acceptées sur le web (lien de l'e-mail), comme les autres liens d'e-mail des apps.

**Infra**

- Rien.

## Comptes et secrets (checklist du projet)

Aucun compte ni secret. À reporter dans l'issue « Mise en route » :

- [ ] Modèles d'e-mail d'invitation relus (BE-009).
- [ ] Section Légal : données partagées, visibilité de l'e-mail des membres, sort du contenu d'un membre qui supprime son compte.

## Données personnelles (GLB-013)

- Les données d'une organisation appartiennent à l'organisation, pas à un membre. À la suppression d'un compte :
  - ses adhésions et ses invitations sont effacées ;
  - s'il est le **seul membre** d'une organisation : l'organisation et les données des modules qui lui sont rattachées sont supprimées ;
  - s'il est le **seul `owner`** d'une organisation qui a d'autres membres : `erase` refuse en levant une `APIError` de Better Auth avec un code explicite (« Transférez d'abord la propriété »), que les clients traduisent ; une autre exception sortirait en 500.
- **Écart à porter par l'ADR du projet** : ce que le membre a créé dans une organisation partagée reste aux autres membres. Garder ce contenu en effaçant l'auteur (`created_by` à `null`) revient à anonymiser, ce que GLB-013 écarte ; et ce contenu n'est pas dans son export. L'ADR du projet tranche (contenu conservé et annoncé dans la politique, ou supprimé avec le compte).
- Le registre `UserDataContributor` ne connaît que l'utilisateur : supprimer une organisation demande un contrat équivalent par organisation (`OrganizationDataContributor`), à décider par un ADR (GLB-013), avec un test d'architecture sur les tables `organization_id` comme celui des tables `user_id`.
- L'export contient ses organisations, son rôle, ses invitations envoyées et reçues.
- L'e-mail de chaque membre est visible des autres membres : le dire dans la politique.

## Pièges

- **Permission vérifiée dans la mauvaise organisation** : `hasPermission` sans `organizationId`, ou les décorateurs de l'organisation active, sur une ressource d'une autre organisation. Exemple : owner de Y (active) et simple member de X, l'utilisateur supprimerait des données de X.
- **401 sur un non-membre** : les clients déconnectent l'utilisateur ; le convertir en 404.
- **Organisation active périmée** : un membre retiré la garde dans sa session ; chaque requête revérifie l'adhésion (le guard le fait).
- **Invitations** : compte non vérifié avec l'adresse invitée ; envoi massif d'e-mails par la création d'organisations et d'invitations.
- **Cache client** mêlant deux organisations : vider au changement.
- **Rôle global et rôle d'organisation confondus** : un `admin` global n'a aucun droit sur les données d'une organisation sans en être membre (sauf décision contraire dans un ADR).

## Tests à écrire

Niveau e2e : API réelle et PostgreSQL en Testcontainers (BE-008).

- Chaque route sans session → 401.
- Un membre de l'organisation A ne lit ni ne modifie rien de l'organisation B → 404 (pas 401) ; un `member` ne peut pas inviter → 403.
- **Owner de Y (organisation active) et member de X** : action réservée sur X → 403.
- Admin global non membre → 404 sur les données d'une organisation.
- Membre retiré, avec l'organisation encore active dans sa session → 404.
- Id d'organisation ou de membre mal formé → 400.
- Invitation : acceptée seulement par l'adresse invitée et vérifiée ; refusée après expiration ou annulation ; débit limité sur la création d'invitations.
- Suppression d'un compte : adhésions effacées ; seul `owner` avec d'autres membres → refus avec le code attendu (pas 500), compte intact ; organisation à un seul membre supprimée avec les données de ses modules.
- Export : organisations, rôle, invitations.
- Garde-fou : toute route du plugin `organization` est classée.
- Web : changement d'organisation qui vide le cache (aucune donnée de A affichée dans B) ; deux onglets sur deux organisations écrivent chacun dans la leur.
- En staging, à la main (`A-VERIFIER.md`) : invitation reçue, lien ouvert sur le web, acceptation ; e-mail d'invitation sans HTML injecté par le nom de l'organisation.
