# Architecture : comment tout s'emboîte

Ce document montre, en schémas, comment les repos, les briques d'une app et les services s'articulent. Il décrit l'état des boilerplates ; chaque section renvoie aux ADR qui fixent les règles. Les diagrammes sont en [Mermaid](https://mermaid.js.org/) : GitHub les affiche directement.

À tenir à jour dans la même PR que tout changement qui modifie une flèche : nouveau service, nouvelle brique, nouveau flux de données.

## 1. Les trois repos et une app générée

Les règles viennent d'`engineering-guidelines`, le code de départ de `boilerplates`, les configurations communes de `shared-libs`. `/new-project` copie les boilerplates choisis dans les repos d'une nouvelle app ([GLB-010](../adr/global/GLB-010-boilerplates-et-libs-partagees.md)).

```mermaid
flowchart LR
  subgraph racine["Dossier racine (poste de travail)"]
    EG["engineering-guidelines<br/>ADR, checklist, skills IA"]
    BP["boilerplates<br/>api-nestjs, web-react-vite,<br/>android-compose, ios-swiftui,<br/>infra-scaleway, _shared"]
    SL["shared-libs<br/>eslint, prettier, tsconfig,<br/>env, problem-details,<br/>design-tokens, preset Renovate"]
  end
  APP["Repos de l'app<br/>(un par brique)"]

  EG -- "règles (ADR) appliquées par" --> BP
  EG -- "CLAUDE.md commun, /new-project, /adr" --> APP
  SL -- "configs copiées, puis paquets @soodidi/*" --> BP
  SL -- "preset Renovate" --> APP
  BP -- "/new-project copie" --> APP
  BP -- "_shared : agents, skills, hooks IA<br/>(scripts/sync-shared.sh)" --> BP
```

- Un boilerplate reste autonome : il s'installe, se teste et se construit seul.
- Une amélioration trouvée dans une app remonte au boilerplate par `/upstream`.
- Le kit IA (agents `planner`, `reviewer`, `qa`, `security`, `devops`, skills `/feature`, `/fix`, `/review`) vit dans `boilerplates/_shared` et est recopié dans chaque boilerplate ([GLB-011](../adr/global/GLB-011-developpement-avec-l-ia.md)).

## 2. Une app en production

Ce qui tourne quand l'app est déployée, et qui parle à qui ([OPS-005](../adr/devops/OPS-005-hebergement-scaleway.md)).

```mermaid
flowchart TB
  user(("Utilisateur"))
  subgraph clients["Clients"]
    WEB["Web (SPA React)<br/>app.example.com"]
    AND["App Android"]
    IOS["App iOS"]
  end

  subgraph scw["Scaleway, région fr-par"]
    EDGE["Edge Services<br/>TLS + cache"]
    BUCKET["Object Storage<br/>fichiers du front"]
    API["Serverless Container<br/>API NestJS<br/>api.app.example.com"]
    subgraph vpc["Réseau privé"]
      PG[("PostgreSQL managé<br/>sauvegardes 14 j,<br/>autre région UE")]
    end
    TEM["Transactional Email"]
    REG["Container Registry"]
    COCKPIT["Cockpit<br/>logs et métriques"]
  end
  SENTRY["Sentry (région UE)<br/>erreurs, sans donnée personnelle"]

  user --> WEB & AND & IOS
  WEB -- "fichiers statiques" --> EDGE --> BUCKET
  WEB -- "HTTPS + cookie de session" --> API
  AND & IOS -- "HTTPS + Bearer signé" --> API
  API --> PG
  API -- "SMTP" --> TEM -- "e-mails (liens vers le web)" --> user
  REG -- "image" --> API
  API -- "logs sans IP" --> COCKPIT
  WEB & API & AND & IOS --> SENTRY
```

- Le front et l'API partagent le même domaine, pour que le cookie de session parte ([BE-006](../adr/backend/BE-006-authentification-et-securite.md)).
- La base n'est joignable que depuis le réseau privé ; l'API y applique ses migrations au démarrage, sous verrou ([BE-003](../adr/backend/BE-003-donnees-drizzle-et-migrations.md), [OPS-004](../adr/devops/OPS-004-environnements-et-deploiement.md)).
- Les secrets (URL de la base, secret Better Auth, SMTP) sont injectés dans le conteneur depuis OpenTofu ([OPS-006](../adr/devops/OPS-006-gestion-des-secrets-en-production.md)).
- Ce que chaque service reçoit comme données personnelles est listé dans la politique de confidentialité du web ([GLB-013](../adr/global/GLB-013-donnees-personnelles-et-rgpd.md)).

## 3. En local

`npm run setup && npm run stack` côté API, puis `npm run dev:api` côté web. L'API tourne dans la **même image** qu'en production.

```mermaid
flowchart LR
  dev(("Développeur"))
  subgraph compose["Docker Compose (api-nestjs)"]
    APIL["API<br/>image de production<br/>localhost:3000"]
    PGL[("PostgreSQL")]
    MP["Mailpit<br/>localhost:8025"]
  end
  VITE["Vite (web-react-vite)<br/>localhost:5173<br/>npm run dev:api"]
  SIM["Émulateur Android /<br/>simulateur iOS"]

  dev --> VITE & SIM
  VITE -- "/v1/*" --> APIL
  SIM -- "/v1/*" --> APIL
  APIL --> PGL
  APIL -- "SMTP" --> MP
  dev -- "lire les e-mails" --> MP
```

- Sans API, `npm run dev` côté web s'appuie sur les mocks MSW (`src/mocks/`), au même contrat que l'API.
- Les tests de l'API démarrent leur propre PostgreSQL avec Testcontainers ([BE-008](../adr/backend/BE-008-tests-backend.md)).

## 4. De la PR à la production

```mermaid
flowchart LR
  PR["Pull request"] --> CI["CI GitHub Actions<br/>verify, tests, build,<br/>image, scan Trivy"]
  CI -- "verte : fusion auto (squash)" --> MAIN["main"]
  MAIN --> IMG["Image Docker<br/>poussée au registry"]
  IMG --> STG["Déploiement staging"]
  STG -- "validation manuelle" --> PROD["Déploiement production"]
  STG & PROD -. "démarrage : migrations<br/>sous pg_advisory_lock" .-> DB[("PostgreSQL")]

  TF["infra-scaleway<br/>tofu plan en CI"] -. "tofu apply<br/>(par un humain)" .-> SCW["Ressources Scaleway"]
```

- Branches courtes, Conventional Commits, fusion automatique quand la CI est verte ([GLB-002](../adr/global/GLB-002-git-trunk-based-et-conventional-commits.md), [OPS-002](../adr/devops/OPS-002-ci-github-actions.md)).
- Le front est construit puis copié dans le bucket ; l'API est une image déployée dans le conteneur ([OPS-001](../adr/devops/OPS-001-conteneurisation-docker.md), [OPS-004](../adr/devops/OPS-004-environnements-et-deploiement.md)).
- L'infra ne change que par `tofu apply`, toujours lancé par un humain ([OPS-003](../adr/devops/OPS-003-infrastructure-as-code.md)).

## 5. Dans l'API

Un module par domaine métier ; un module n'importe que l'`index.ts` d'un autre, jamais ses tables ([BE-002](../adr/backend/BE-002-architecture-modulaire.md)). `npm run arch` le vérifie.

```mermaid
flowchart TB
  subgraph modules["src/modules"]
    AUTH["auth<br/>Better Auth, tables users / sessions,<br/>guard global, rôles et permissions,<br/>purge des données expirées"]
    ACC["account<br/>GET /v1/account/export"]
    NOTES["notes<br/>module d'exemple"]
    ADMIN["admin<br/>GET /v1/admin/stats,<br/>exemple de route réservée"]
  end
  subgraph shared["Code partagé"]
    UD["common/user-data<br/>registre UserDataContributor"]
    COMMON["common<br/>Problem Details, validation,<br/>CSRF, OpenAPI, masquage des logs"]
    MAIL["mail<br/>Mailer, SMTP, gabarits"]
    DB["database<br/>Drizzle, migrations"]
    CFG["config<br/>env validé"]
  end

  NOTES -- "Session (index.ts)" --> AUTH
  ADMIN -- "UserHasPermission, UsersService" --> AUTH
  ADMIN -- "NotesService" --> NOTES
  ACC -- "Session (index.ts)" --> AUTH
  ACC -- "exportAll" --> UD
  AUTH -- "eraseAll à la suppression" --> UD
  NOTES -. "@ContributesUserData" .-> UD
  AUTH -. "@ContributesUserData" .-> UD
  AUTH --> MAIL
  AUTH & NOTES & UD --> DB
  MAIL & DB --> CFG
```

- Une requête passe par : guard d'auth (route protégée par défaut), validation Zod, controller, service, repository ([BE-004](../adr/backend/BE-004-api-rest-et-openapi.md), [BE-005](../adr/backend/BE-005-validation-aux-frontieres.md)).
- Une route réservée porte `@UserHasPermission` ou `@Roles` ; les permissions sont déclarées une seule fois dans `auth/access-control.ts` ([BE-010](../adr/backend/BE-010-roles-et-permissions.md)).
- Toute table avec une colonne `user_id` est couverte par un contributeur du registre, qui l'exporte et l'efface avec le compte ([GLB-013](../adr/global/GLB-013-donnees-personnelles-et-rgpd.md)).

## 6. Dans le web

Code rangé par feature ; une feature n'expose que son `index.ts` ([FE-003](../adr/frontend/FE-003-structure-par-feature.md)).

```mermaid
flowchart TB
  subgraph app["src/app"]
    ROUTER["router.tsx<br/>routes, beforeLoad: requireSession"]
    LAYOUT["root-layout.tsx<br/>en-tête, pied de page"]
  end
  subgraph features["src/features"]
    FAUTH["auth<br/>pages, client Better Auth,<br/>session, garde"]
    FNOTES["notes"]
    FLEGAL["legal<br/>pages légales"]
    FHOME["home"]
  end
  subgraph lib["src/lib et src/i18n"]
    HTTP["http.ts : request()<br/>schéma Zod, 401 → connexion"]
    QC["TanStack Query"]
    I18N["i18n fr / en"]
    SENTRYW["sentry.ts"]
  end
  MOCKS["src/mocks<br/>MSW (dev et tests)"]
  APIX["API"]

  ROUTER --> FAUTH & FNOTES & FLEGAL & FHOME
  LAYOUT --> FAUTH & FLEGAL
  FNOTES --> HTTP --> APIX
  FAUTH -- "Better Auth SDK" --> APIX
  FNOTES & FAUTH --> QC
  HTTP -. "en dev sans API" .-> MOCKS
```

## 7. Dans les apps mobiles

Même découpage sur Android et iOS : un cœur partagé et des features, au même contrat d'API que le web ([AND-002](../adr/android/AND-002-architecture-udf-mvvm.md), [IOS-002](../adr/ios/IOS-002-architecture-mvvm-observable.md)).

```mermaid
flowchart TB
  subgraph android["android-compose (Hilt)"]
    ANAV["navigation<br/>AppNavHost, SessionViewModel"]
    AFA["feature/auth"]
    AFN["feature/notes"]
    ACA["core/auth<br/>token chiffré (Tink + Keystore)"]
    ACN["core/network"]
    ADS["core/designsystem"]
  end
  subgraph ios["ios-swiftui (Swift Packages)"]
    IAPP["App<br/>SessionStore.states()"]
    IFA["AuthFeature"]
    IFN["NotesFeature"]
    ICA["CoreAuth<br/>Keychain"]
    ICN["CoreNetworking"]
    IDS["DesignSystem"]
  end
  APIM["API /v1"]

  ANAV --> AFA & AFN
  AFA & AFN --> ACN --> APIM
  AFA --> ACA
  ACN -- "Bearer, 401 → déconnexion" --> ACA
  AFA & AFN --> ADS
  IAPP --> IFA & IFN
  IFA & IFN --> ICN --> APIM
  IFA --> ICA
  ICN -- "Bearer, 401 → déconnexion" --> ICA
  IFA & IFN --> IDS
```

## 8. Parcours clés

### Connexion : web par cookie, mobile par Bearer

```mermaid
sequenceDiagram
  autonumber
  participant W as Web
  participant M as Mobile
  participant A as API (Better Auth)
  participant DB as PostgreSQL

  W->>A: POST /v1/auth/sign-in/email
  A->>DB: vérifie le hachage Argon2id, crée la session
  A-->>W: cookie HttpOnly (session)
  W->>A: GET /v1/notes (cookie envoyé)

  M->>A: POST /v1/auth/sign-in/email
  A->>DB: crée la session
  A-->>M: en-tête set-auth-token (token signé)
  Note over M: stocké chiffré (Keystore / Keychain)
  M->>A: GET /v1/notes, Authorization: Bearer
  A-->>M: 401 si session expirée ou révoquée → écran de connexion
```

Règles : [BE-006](../adr/backend/BE-006-authentification-et-securite.md), [AND-004](../adr/android/AND-004-reseau-donnees-et-securite.md), [IOS-004](../adr/ios/IOS-004-reseau-donnees-et-securite.md).

### Suppression du compte

```mermaid
sequenceDiagram
  autonumber
  participant C as Client (web ou mobile)
  participant BA as Better Auth
  participant R as Registre UserDataContributor
  participant DB as PostgreSQL

  C->>BA: POST /v1/auth/delete-user { password }
  BA->>BA: hook before : mot de passe exigé
  BA->>DB: vérifie le mot de passe
  BA->>R: beforeDelete → eraseAll(userId)
  R->>DB: transaction : erase de chaque module
  BA->>DB: supprime le compte, ses sessions, ses moyens de connexion
  BA->>R: afterDelete → eraseAll (écritures concurrentes)
  BA-->>C: 200, session révoquée
```

Règles : [GLB-013](../adr/global/GLB-013-donnees-personnelles-et-rgpd.md). L'export (`GET /v1/account/export`) passe par le même registre.

## 9. Le cycle de travail avec l'IA

```mermaid
flowchart LR
  ISSUE["Issue"] --> PLAN["/feature : agent planner<br/>plan validé par l'humain"]
  PLAN --> CODE["Code + tests<br/>npm run verify"]
  CODE --> CTRL["Agents reviewer, qa,<br/>security, devops"]
  CTRL -- "bloquant" --> CODE
  CTRL --> PRX["PR + fusion automatique"]
  PRX --> SUIVI["docs/suivi :<br/>passation à jour"]
```

Règles : [GLB-011](../adr/global/GLB-011-developpement-avec-l-ia.md). Une décision non couverte par un ADR passe par `/adr` avant d'être codée.
