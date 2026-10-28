# GLB-013 : Données personnelles, RGPD et suppression du compte

- **Statut** : Proposé
- **Date** : 2026-10-28
- **Périmètre** : global
- **Auteurs** : Mo, Claude
- **Liens** : BE-002, BE-006, BE-007, FE-009, AND-004, IOS-004, OPS-007

## Contexte

Les apps sont d'abord faites pour un usage personnel, mais elles peuvent devenir publiques. Dès qu'un compte existe, le RGPD s'applique : collecter le minimum, informer, permettre l'accès aux données et leur effacement. L'App Store (règle 5.1.1 v) et Google Play exigent en plus qu'un compte créé dans l'app puisse y être supprimé.

Les données d'un utilisateur sont réparties entre plusieurs modules de l'API (par exemple `notes`). BE-002 interdit à un module d'accéder aux tables d'un autre, et il n'y a pas de clé étrangère entre modules. La suppression du compte, gérée par Better Auth (BE-006), ne sait donc pas ce que les autres modules gardent. Il faut un mécanisme explicite, qui ne laisse rien derrière lui quand un module est ajouté.

## Décision

**Données collectées**

- Les apps DOIVENT collecter le minimum : pour le compte, le nom, l'adresse e-mail et le hash du mot de passe ; pour les sessions, l'adresse IP et l'agent utilisateur (sécurité, BE-006). Toute donnée en plus DOIT servir une fonctionnalité et figurer dans la politique de confidentialité.
- Durées de conservation : les données du compte jusqu'à sa suppression ; les sessions jusqu'à leur expiration (BE-006) ; les jetons de vérification jusqu'à leur expiration ; les sauvegardes de la base pendant leur rétention (OPS-007), que la politique de confidentialité indique.
- Les logs et le suivi des erreurs NE DOIVENT contenir ni donnée personnelle ni secret (BE-007, FE-009, AND-004, IOS-004).

**Traceurs et consentement**

- Pas de traceur sans consentement. Tant qu'il n'y a ni mesure d'audience ni publicité, il n'y a **pas de bandeau cookies** : le cookie de session est strictement nécessaire, donc exempté.
- Ajouter une mesure d'audience, un pixel ou tout traceur non essentiel DOIT passer par un ADR, avec recueil du consentement ou un outil exempté.

**Sous-traitants**

- La politique de confidentialité DOIT lister les sous-traitants réellement utilisés : Scaleway (hébergement, base, e-mails), Sentry (erreurs, région UE), Apple et Google pour les apps mobiles. Tout nouveau service qui reçoit des données personnelles s'y ajoute dans la même PR.

**Droit d'accès et de portabilité**

- L'API DOIT exposer `GET /v1/account/export`, authentifié, qui renvoie en JSON toutes les données de l'utilisateur connecté : son compte et celles de chaque module.
- Le web DOIT proposer « Exporter mes données » dans l'écran « Mon compte ». Les apps mobiles PEUVENT renvoyer vers le web pour l'export.

**Droit à l'effacement**

- La suppression DOIT être **immédiate et réelle** : pas d'anonymisation, pas de délai de grâce. Seules les sauvegardes gardent les données, pendant leur rétention.
- Elle passe par la route `deleteUser` de Better Auth (`POST /delete-user`) et DOIT exiger la **ressaisie du mot de passe**. Better Auth rend ce mot de passe facultatif : sans lui, une session de moins d'un jour (`freshAge`) suffit. Un hook `before` DOIT donc refuser `/delete-user` sans mot de passe, et un test le vérifie.
- Le web et les apps mobiles DOIVENT proposer « Supprimer mon compte » dans l'app, avec une confirmation explicite.

**Registre des données d'utilisateur (API)**

- Chaque module qui garde des données liées à un utilisateur DOIT enregistrer un `UserDataContributor`, avec une clé, `export(userId)` et `erase(userId, tx)`. C'est la seule manière pour le module auth d'atteindre ces données (BE-002).
- Le hook `beforeDelete` de Better Auth DOIT appeler `erase` de tous les contributeurs **dans une seule transaction**. Si elle échoue, le compte n'est pas supprimé et l'utilisateur peut réessayer.
- L'export DOIT être construit par le même registre : une donnée effacée est une donnée exportée, et inversement.
- On NE DOIT PAS utiliser de clé étrangère entre modules ni un événement asynchrone pour effacer les données d'un utilisateur.

**Pages légales**

- Le web DOIT fournir des pages modèles « Mentions légales », « Politique de confidentialité » et « Conditions d'utilisation ». Les champs à remplir y sont clairement marqués (`[NOM DE L'ÉDITEUR]`…). Elles sont liées dans le pied de page.
- Les apps mobiles DOIVENT donner accès à la politique de confidentialité, par un lien vers le web. Les fiches des stores pointent vers la même page.

## Alternatives envisagées

- **Événement `user.deleted`** (`@nestjs/event-emitter`), écouté par chaque module : c'est le plus découplé, et BE-002 le cite. Écarté : la suppression n'est pas transactionnelle (un écouteur en échec laisse des données orphelines, sans que personne ne le voie), et l'export demanderait un second mécanisme.
- **Clé étrangère `ON DELETE CASCADE` vers `users`** : la base le garantit. Écarté : chaque module dépendrait du schéma d'auth (BE-002), et l'export n'est pas couvert.
- **Délai de grâce de 30 jours** (compte désactivé, puis purgé par une tâche planifiée) : la suppression pourrait être annulée. Écarté pour l'instant : il faut un job, un état intermédiaire et des tests en plus, pour un besoin non avéré.
- **Confirmation par lien e-mail** : plus sûre si une session est volée, mais le lien s'ouvre sur le web, même depuis le mobile. La ressaisie du mot de passe protège déjà contre la plupart des usages d'une session volée.

## Conséquences

- ✅ Un seul point d'entrée pour l'export et l'effacement ; un module oublié est détecté par un test.
- ✅ L'effacement est atomique côté modules ; le compte n'est supprimé que si toutes leurs données l'ont été.
- ✅ Conforme aux exigences des stores sur la suppression du compte dans l'app.
- ⚠️ Chaque nouveau module avec des données d'utilisateur ajoute un contributeur et ses tests.
- ⚠️ La suppression Better Auth (compte, sessions) suit la transaction des modules sans en faire partie : si elle échoue après coup, les données des modules sont déjà effacées et le compte reste. C'est acceptable, car l'utilisateur a demandé l'effacement et peut relancer la suppression.
- 🔁 Le module `notes` du boilerplate `api-nestjs` devient le premier contributeur.

## Mise en application

- Test d'architecture dans l'API : toute table Drizzle avec une colonne `user_id` DOIT appartenir à un module qui enregistre un contributeur.
- Tests d'intégration : l'export contient les données de chaque module ; après une suppression, aucune ligne ne reste pour cet utilisateur ; un mauvais mot de passe ne supprime rien.
- Checklist « nouveau projet », section Légal : pages légales remplies, sous-traitants à jour.
- Revue de code et agent `security` : nouvelle donnée personnelle, nouveau sous-traitant, nouveau traceur.
