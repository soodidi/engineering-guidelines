# Catalogue de modules optionnels

Des recettes à appliquer **quand une app en a besoin** : elles n'entrent pas dans les boilerplates, qui restent minimaux (GLB-010). Chaque fiche dit quand utiliser le module, ce qu'on recommande, ce que ça change dans chaque brique et ce qu'il faut tester.

## Statut des fiches

Toutes les fiches sont au statut **Proposé**. Au premier usage réel dans un projet :

1. lire la fiche avant de planifier (le `CLAUDE.md` commun et l'agent `planner` le demandent) ;
2. vérifier les points datés (tarifs, régions, règles des stores, doc des fournisseurs) : ils bougent plus vite que la fiche ;
3. tirer un ADR de la fiche avec `/adr` (option retenue, alternatives écartées), dans le repo du projet ou ici si le choix vaut pour tous les projets ;
4. corriger la fiche avec ce que le projet a appris (pièges, étapes manquantes).

Une fiche ne déroge à aucun ADR **Accepté** : quand le module en demande une, la fiche le dit et c'est l'ADR du projet qui la porte.

## Index

| Module | Quand l'utiliser | Fiche |
|---|---|---|
| Upload de fichiers | L'utilisateur envoie des images, documents ou pièces jointes | [upload-fichiers.md](upload-fichiers.md) |
| Paiement | L'app vend un abonnement, un achat unique ou des crédits | [paiement.md](paiement.md) |
| Mesure d'audience | On veut savoir quelles pages sont vues et d'où viennent les visiteurs | [analytics.md](analytics.md) |
| Notifications push | L'app mobile prévient l'utilisateur hors de l'app | [notifications-push.md](notifications-push.md) |
| Client d'API généré | L'API grossit et les appels écrits à la main divergent du contrat | [client-api-openapi.md](client-api-openapi.md) |
| Organisations et équipes | Plusieurs utilisateurs partagent des données dans un espace commun | [organisations.md](organisations.md) |
| Temps réel | L'écran se met à jour sans recharger (notifications in-app, collaboration, chat) | [temps-reel.md](temps-reel.md) |

## Format d'une fiche

Chaque fiche suit les mêmes sections, pour qu'un humain ou un agent y trouve vite ce qu'il cherche :

- en-tête : **statut** et **ADR impactés** ;
- **Quand l'utiliser** (et quand s'en passer) ;
- **Recommandation** et **Alternatives**, avec la raison du choix ;
- **Intégration par brique** : api, web, android, ios, infra ;
- **Comptes et secrets** : cases à reporter dans l'issue « Mise en route » du projet, qui reprend la [checklist « nouveau projet »](../docs/checklist-nouveau-projet.md) (section indiquée quand ce n'est pas la plus évidente) ;
- **Données personnelles** (GLB-013) : export, effacement, sous-traitants ;
- **Pièges** ;
- **Tests à écrire**, avec ce qui ne se vérifie qu'à la main en staging (à reporter dans `A-VERIFIER.md` ou l'équivalent du projet).

Ajouter un module : copier la structure d'une fiche existante, l'ajouter à l'index, et le dire dans la PR.

## Règles communes aux fiches

### Effacement hors de la base

Le contrat `UserDataContributor` n'a qu'`erase(userId, tx)`, appelé avant la suppression du compte, puis une seconde fois après. Un module qui garde des données ailleurs que dans PostgreSQL (bucket, Stripe…) les supprime **dans `erase`, avant ses lignes** : au premier passage, si le service externe ne répond pas, `erase` échoue, la transaction est annulée et le compte reste ; l'utilisateur réessaie. (Le second passage tourne après la suppression du compte : il ne fait que rattraper.)

La suppression externe DOIT être **idempotente** : une ressource déjà absente compte comme un succès. Sinon, une tentative interrompue après la suppression externe (autre contributeur en échec, transaction annulée) rendrait le compte impossible à supprimer. Ne pas ajouter de hook au contrat sans un ADR (GLB-013).

### Secrets saisis à la main

OPS-006 range les secrets saisis par un humain (clé Stripe, clé APNs…) dans Scaleway Secret Manager, mais l'infra des boilerplates n'a pas encore de chemin de Secret Manager jusqu'au conteneur. Recette au premier usage, à confirmer par un ADR :

1. OpenTofu crée un `scaleway_secret` par environnement (jamais sa valeur) ;
2. un humain saisit la valeur dans la console ou avec `scw` ;
3. OpenTofu la lit (`data "scaleway_secret_version"`) et la passe en `secret_environment_variables` du conteneur ;
4. après chaque rotation, ré-appliquer l'environnement.

À vérifier : la clé `ci-plan` (lecture seule) doit pouvoir lire la valeur, sinon les plans des PR échouent.

### Purges

Une purge appartient au module qui possède les données (BE-002), sur le modèle de `ExpiredAuthDataPurge` : au démarrage, puis toutes les 24 h. En staging, les instances descendent à zéro : la purge ne tourne qu'aux démarrages.
