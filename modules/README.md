# Catalogue de modules optionnels

Des recettes à appliquer **quand une app en a besoin** : elles n'entrent pas dans les boilerplates, qui restent minimaux (GLB-010). Chaque fiche dit quand utiliser le module, ce qu'on recommande, ce que ça change dans chaque brique et ce qu'il faut tester.

## Statut des fiches

Toutes les fiches sont au statut **Proposé**. Au premier usage réel dans un projet :

1. lire la fiche avant de planifier (l'agent `planner` le fait) ;
2. vérifier les points datés (tarifs, régions, règles des stores) : ils bougent plus vite que la fiche ;
3. tirer un ADR de la fiche avec `/adr` (option retenue, alternatives écartées), dans le repo du projet ou ici si le choix vaut pour tous les projets ;
4. corriger la fiche avec ce que le projet a appris (pièges, étapes manquantes).

Une fiche ne déroge à aucun ADR **Accepté** : quand le module en demande une, la fiche le dit et c'est l'ADR du projet qui la porte.

## Index

| Module | Quand l'utiliser | Fiche |
|---|---|---|
| Upload de fichiers | L'utilisateur envoie des images, documents ou pièces jointes | [upload-fichiers.md](upload-fichiers.md) |
| Paiement | L'app vend un abonnement, un achat unique ou des crédits | [paiement.md](paiement.md) |
| Mesure d'audience | On veut savoir quelles pages sont vues et d'où viennent les visiteurs | [analytics.md](analytics.md) |
| Notifications push | L'app mobile prévient l'utilisateur hors de l'app | à venir |
| Client d'API généré | L'API grossit et les appels écrits à la main divergent du contrat | à venir |
| Organisations et équipes | Plusieurs utilisateurs partagent des données dans un espace commun | à venir |
| Temps réel | L'écran se met à jour sans recharger (notifications in-app, collaboration, chat) | à venir |

## Format d'une fiche

Chaque fiche suit les mêmes sections, pour qu'un humain ou un agent y trouve vite ce qu'il cherche :

- **Quand l'utiliser** (et quand s'en passer) ;
- **Recommandation** et **alternatives**, avec la raison du choix ;
- **ADR impactés** ;
- **Intégration par brique** : api, web, android, ios, infra ;
- **Comptes et secrets** : à ajouter à la [checklist du projet](../docs/checklist-nouveau-projet.md) (issue « Mise en route ») ;
- **Données personnelles** (GLB-013) : export, effacement, sous-traitants ;
- **Pièges** ;
- **Tests à écrire**.

Ajouter un module : copier la structure d'une fiche existante, l'ajouter à l'index, et le dire dans la PR.
