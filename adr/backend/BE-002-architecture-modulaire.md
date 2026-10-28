# BE-002 : Monolithe modulaire, découpé par domaine métier

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

Les microservices dès le départ multiplient les coûts (déploiement, réseau, cohérence des données, observabilité) sans bénéfice tant que l'équipe et le trafic sont modestes. À l'inverse, un monolithe sans frontières devient un plat de spaghettis. Il faut des frontières claires dès le premier jour, en gardant la possibilité d'extraire un service plus tard.

## Décision

**Un monolithe modulaire** : un seul déployable, découpé en **modules NestJS par domaine métier** (`users`, `billing`, `catalog`…), pas par couche technique.

```
src/
├── main.ts
├── app.module.ts
├── config/                 # chargement + validation de la config (BE-005)
├── common/                 # transverse : filtres d'erreur, guards, intercepteurs, utils
├── database/               # client Drizzle, schéma, migrations
└── modules/
    └── billing/
        ├── billing.module.ts
        ├── billing.controller.ts     # HTTP : validation, mapping, codes de retour
        ├── billing.service.ts        # logique métier, transactions
        ├── billing.repository.ts     # accès aux données (Drizzle)
        ├── dto/                      # schémas Zod d'entrée / sortie
        ├── billing.service.spec.ts
        └── index.ts                  # ce que le module expose aux autres
```

**Règles des couches**

- **Controller** : aucun accès à la base, aucune règle métier. Il valide l'entrée, appelle un service, formate la réponse.
- **Service** : porte les règles métier. Il ne connaît ni HTTP (pas de `Request`/`Response`) ni le détail SQL.
- **Repository** : seul endroit qui parle à Drizzle. Retourne des objets du domaine, pas des lignes brutes si elles diffèrent.

**Règles entre modules**

- Un module n'accède **jamais** aux tables ou au repository d'un autre module. Il passe par le service exporté par ce module.
- Pas de dépendance circulaire entre modules.
- Pour réagir à un événement d'un autre module sans couplage fort : événements internes (`@nestjs/event-emitter`), puis file de messages si besoin d'asynchrone fiable.
- Exception, les données d'un utilisateur : leur export et leur effacement passent par le registre `UserDataContributor` (GLB-013), synchrone et transactionnel, pas par un événement.

## Alternatives envisagées

- **Microservices** : prématuré. Un module bien isolé pourra être extrait le jour où un besoin réel (scalabilité différente, équipe dédiée) apparaît.
- **Architecture hexagonale / clean architecture complète** (ports, adapters, entités pures) : rigoureuse, mais beaucoup de code d'interface pour des domaines souvent CRUD. On PEUT l'appliquer à un module au cœur métier complexe, via un ADR dédié.
- **Rangement par couche** (`controllers/`, `services/`) : éparpille chaque domaine.

## Conséquences

- ✅ Un seul déploiement, une seule base, transactions simples.
- ✅ Frontières claires, extraction future possible.
- ⚠️ La discipline entre modules doit être vérifiée automatiquement, sinon elle s'érode.

## Mise en application

- `dependency-cruiser` en CI : interdit les imports internes d'un module à l'autre et les cycles.
- Revue de code sur les controllers qui contiennent de la logique.
