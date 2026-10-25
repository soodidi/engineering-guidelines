# BE-005 : Validation et typage aux frontières

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

Le typage TypeScript disparaît à l'exécution. Toute donnée qui entre dans le système (requête HTTP, variable d'environnement, message de file, réponse d'API tierce, webhook) peut être invalide ou malveillante.

## Décision

- Toute donnée entrante DOIT être validée par un **schéma Zod** à la frontière, avant d'atteindre la logique métier :
  - corps, params et query des requêtes HTTP (pipe de validation global) ;
  - variables d'environnement au démarrage (GLB-005) ;
  - messages de file, événements, webhooks (avec vérification de signature) ;
  - réponses d'API tierces.
- Les types TypeScript des DTO sont **dérivés** des schémas (`z.infer`). Les mêmes schémas alimentent la spec OpenAPI (BE-004).
- Les schémas sont **stricts** : les champs inconnus sont rejetés ou retirés (pas de mass assignment).
- Les réponses sont aussi passées par un schéma de sortie : on n'expose que les champs prévus (pas de fuite de `password_hash`, de champ interne…).
- Après la frontière, le code fait confiance aux types : pas de revalidation défensive partout.
- Les règles métier (« une facture payée ne peut pas être modifiée ») vivent dans le service, pas dans le schéma, et retournent une erreur `422`.

## Alternatives envisagées

- **class-validator + class-transformer** (classique avec NestJS) : décorateurs sur des classes, typage moins fiable, double déclaration type/validation. Zod permet en plus de partager les schémas avec le front.
- **Valibot** : plus léger, API proche ; Zod a l'écosystème le plus large.

## Conséquences

- ✅ Une seule définition par contrat de données, validée et typée.
- ✅ Schémas partageables avec le front quand c'est pertinent.
- ⚠️ Intégration Zod ↔ NestJS ↔ OpenAPI via une librairie dédiée (ex. `nestjs-zod`) à maintenir.

## Mise en application

- Pipe de validation global ; un endpoint sans schéma d'entrée est refusé en revue.
- Schéma de configuration validé au bootstrap : l'app plante immédiatement si la config est invalide.
