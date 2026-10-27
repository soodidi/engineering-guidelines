# BE-003 : Accès aux données avec Drizzle et conventions SQL

- **Statut** : Proposé
- **Date** : 2026-10-28
- **Périmètre** : backend
- **Auteurs** : Mo, Claude

## Contexte

L'ORM conditionne la performance, la lisibilité des requêtes et la sécurité des migrations. On veut rester proche du SQL (compétence durable et transférable), avec un typage fort.

## Décision

**Outil**

- **Drizzle ORM** : schéma déclaré en TypeScript, requêtes proches du SQL et typées.
- Migrations générées par `drizzle-kit generate`, **relues** puis commitées. `drizzle-kit push` est interdit hors environnement local jetable.
- Les migrations sont appliquées **au démarrage de l'API, avant qu'elle n'accepte du trafic**, sous un verrou PostgreSQL (`pg_advisory_lock`) : une seule instance migre, les autres attendent puis constatent qu'il n'y a plus rien à faire. Une migration qui échoue empêche l'instance de démarrer : `/health/ready` ne répond pas et la nouvelle version n'est pas mise en service.
- Raison : la base n'a pas d'accès public (OPS-005), et Scaleway Serverless Jobs ne peut pas joindre un réseau privé. Un job lancé depuis un runner GitHub ne joint donc pas la base. L'API est déjà dans le réseau privé, avec la même image.
- `npm run db:migrate` reste disponible pour le développement local et une intervention manuelle.

**Conventions de schéma**

- Tables au pluriel, `snake_case` : `invoice_lines`. Colonnes en `snake_case` (mappées en `camelCase` côté TS).
- Clé primaire : `id` de type **UUID v7** (triable dans le temps, pas d'énumération possible). Les identifiants exposés dans l'API sont ces UUID, jamais un entier auto-incrémenté.
- Chaque table a `created_at` et `updated_at` en `timestamptz`. Toutes les dates sont stockées en **UTC**.
- Montants en entiers (centimes) ou `numeric`, jamais en `float`.
- Clés étrangères et contraintes (`not null`, `unique`, `check`) déclarées en base : la base est la dernière ligne de défense.
- Index sur chaque clé étrangère et chaque colonne filtrée fréquemment.
- Suppression logique (`deleted_at`) seulement quand un besoin métier ou légal l'exige, pas par défaut.

**Migrations sûres (zero-downtime)**

- Une migration NE DOIT PAS casser la version de l'app actuellement en production. Pour renommer ou supprimer une colonne : *expand* (ajouter) → déployer le code compatible → *contract* (retirer) dans un déploiement suivant.
- Ajout d'index sur une grosse table : `CREATE INDEX CONCURRENTLY`.
- Ajout de colonne `not null` : avec valeur par défaut, ou en plusieurs étapes.

**Requêtes**

- Pas de requête dans une boucle (N+1) : utiliser des jointures ou `inArray`.
- Les opérations qui modifient plusieurs tables DOIVENT être dans une transaction.
- SQL brut autorisé via le template `sql` de Drizzle (paramétré), jamais par concaténation de chaînes.

## Alternatives envisagées

- **Prisma** : très populaire et confortable, mais plus éloigné du SQL, avec un moteur de requêtes propre et un contrôle moindre sur le SQL généré.
- **TypeORM** (historique de NestJS) : typage plus faible, nombreux pièges connus.
- **Job de migration avant le déploiement** (règle précédente) : impossible sans exposer la base ou ajouter une machine dans le réseau privé.
- **Conteneur de migration dédié, déclenché par la CI** : un point d'entrée HTTP à écrire et à sécuriser, et une ressource de plus.
- **Runner GitHub auto-hébergé dans le VPC** : un serveur à patcher et à surveiller, disproportionné pour un développeur seul.
- **Kysely** : excellent query builder typé ; Drizzle apporte en plus la gestion du schéma et des migrations.

## Conséquences

- ✅ SQL maîtrisé et typé ; compétence SQL qui reste utile quelle que soit la stack.
- ⚠️ Écosystème Drizzle plus jeune que Prisma ; à surveiller.

## Mise en application

- CI : `drizzle-kit check` et application des migrations sur une base de test vierge ; `npm run stack:smoke` vérifie que l'image démarre en appliquant ses migrations.
- Test d'intégration : deux exécutions concurrentes des migrations ne se gênent pas (verrou).
- `CODEOWNERS` : 2 approbations pour tout fichier de migration (GLB-003).
- `squawk` (linter de migrations PostgreSQL) en CI pour détecter les opérations bloquantes.
