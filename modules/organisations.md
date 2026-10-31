# Module : organisations et équipes

- **Statut** : Proposé
- **ADR impactés** : BE-002, BE-006, BE-009, BE-010, GLB-013, FE-004, AND-002, IOS-002

## Quand l'utiliser

Plusieurs utilisateurs partagent des données dans un **espace commun** : une famille, une association, une équipe, un client B2B. Chaque donnée appartient alors à une organisation, et les droits dépendent du rôle **dans cette organisation**.

S'en passer quand le partage reste ponctuel (partager une note avec une personne : une table de partage suffit) ou quand les rôles globaux de BE-010 (`user`, `admin`) couvrent le besoin.

## Recommandation

**Plugin `organization` de Better Auth**, comme le prévoit BE-010 : organisations, membres, invitations par e-mail, rôles par organisation (`owner`, `admin`, `member`) et contrôle d'accès déclaré comme `access-control.ts`. Il cohabite avec le plugin `admin` : le rôle global sert à l'administration de l'app, le rôle dans l'organisation sert aux données partagées.

Pourquoi : même librairie que l'auth (sessions, e-mails, rate limiting), tables et routes déjà écrites, organisation active portée par la session (`activeOrganizationId`).

Options à fixer au premier usage :

- `requireEmailVerificationOnInvitation: true` : l'identifiant d'une invitation ne suffit pas, il faut l'adresse vérifiée ;
- `invitationExpiresIn` (48 h par défaut), `membershipLimit`, `invitationLimit`, `organizationLimit` ;
- `teams` (sous-équipes) seulement si le besoin est réel ;
- rôles et permissions propres à l'app dans un `ac` dédié, en partant des déclarations par défaut du plugin.

## Alternatives

- **Table maison** (`memberships`) : simple pour un seul niveau de partage, mais invitations, rôles et cas limites à réécrire.
- **Fournisseur d'identité avec organisations** (Zitadel, Keycloak) : pour du B2B avec SSO d'entreprise ; hors du modèle de BE-006.

## Intégration par brique

**API**

- Migration générée pour les tables du plugin (`organization`, `member`, `invitation`, colonne de l'organisation active sur `session`).
- Chaque table de données partagées porte `organization_id` ; le repository filtre par l'organisation **et** vérifie que l'utilisateur en est membre. Organisation dont il n'est pas membre → **404**, comme pour l'IDOR (BE-006) ; membre sans la permission → **403**.
- Permissions vérifiées côté serveur avec `auth.api.hasPermission({ headers, body: { permissions } })` dans un guard ou le service, **toujours avec les en-têtes de la requête**.
- Invitations : `sendInvitationEmail` branché sur `Mailer` (BE-009), lien vers le web.
- Hooks du plugin (`organizationHooks`) pour les règles de l'app : empêcher le départ du dernier `owner`, limiter la création, et effacer les données des modules à la suppression d'une organisation (`beforeDeleteOrganization`), par le contrat par organisation.
- Routes de l'organisation à classer comme celles du plugin `admin` (ouvertes, fermées), avec le même test garde-fou que `access-control.spec.ts`.

**Web**

- Sélecteur d'organisation dans l'en-tête ; changement d'organisation = `setActive` puis **cache vidé** (`resetUserCache()`), comme au changement de compte.
- Pages : membres, invitations, rôles ; acceptation d'une invitation après connexion avec la bonne adresse.
- `useCan` demande les permissions de l'organisation active à l'API.

**Android / iOS**

- Organisation active lue depuis la session ; sélecteur dans « Mon compte » ; listes rechargées au changement.
- Invitations acceptées sur le web (lien de l'e-mail), comme les autres liens d'e-mail des apps.

## Comptes et secrets (checklist du projet)

- Aucun compte ni secret. À reporter dans l'issue « Mise en route » : modèles d'e-mail d'invitation relus (BE-009), section Légal mise à jour (données partagées, auteur effacé).

## Données personnelles (GLB-013)

- Les données d'une organisation appartiennent à l'organisation, pas à un membre. À la suppression d'un compte :
  - ses adhésions et ses invitations sont effacées ;
  - ce qu'il a créé dans une organisation **reste**, avec l'auteur effacé (`created_by` à `null`) ; le dire dans la politique de confidentialité ;
  - s'il est le **seul `owner`** d'une organisation qui a d'autres membres : `erase` refuse, la suppression du compte échoue avec un code d'erreur explicite que les clients traduisent (« Transférez d'abord la propriété ») ;
  - s'il en est le seul membre : supprimer l'organisation **et les données des modules** rattachées à elle. Le registre `UserDataContributor` ne connaît que l'utilisateur : il faut un contrat équivalent par organisation (`OrganizationDataContributor`), à décider par un ADR au premier usage (GLB-013).
- L'export contient ses organisations, son rôle, ses invitations envoyées et reçues.
- Chaque module concerné l'écrit dans son `UserDataContributor` ; les tables avec `organization_id` sont couvertes par le contrat par organisation, avec un test d'architecture comme celui des tables `user_id`.

## Pièges

- **Organisation active périmée** : un membre retiré garde un `activeOrganizationId` dans sa session ; chaque requête revérifie l'adhésion.
- **Invitations** : sans vérification d'adresse, quiconque obtient le lien rejoint l'organisation ; ne pas révéler si une adresse a déjà un compte.
- **Cache client** mêlant deux organisations : vider au changement.
- **Rôle global et rôle d'organisation confondus** : un `admin` global n'a aucun droit sur les données d'une organisation sans en être membre (sauf décision contraire dans un ADR).

## Tests à écrire

Niveau e2e : API réelle et PostgreSQL en Testcontainers (BE-008).

- Chaque route sans session → 401.
- Un membre de l'organisation A ne lit ni ne modifie rien de l'organisation B (404) ; un `member` ne peut pas inviter (403).
- Invitation : acceptée seulement avec l'adresse invitée et vérifiée ; refusée après expiration ou annulation.
- Le dernier `owner` ne peut ni partir ni supprimer son compte tant que d'autres membres restent.
- Suppression d'un compte : adhésions effacées, données partagées conservées sans auteur ; organisation à un seul membre supprimée.
- Garde-fou : toute route du plugin `organization` est classée.
- Web : changement d'organisation qui vide le cache (aucune donnée de A affichée dans B).
