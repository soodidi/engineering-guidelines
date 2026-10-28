# Engineering Guidelines

Règles de code et décisions d'architecture (ADR) par domaine : **global, frontend, backend, devops, android, ios**.

Ce repo sert de référence commune, pour les humains comme pour les assistants IA (voir [`AGENTS.md`](./AGENTS.md)).

## Stack de référence

| Domaine  | Stack par défaut |
|----------|------------------|
| Frontend | React + TypeScript + Vite + Tailwind. Next.js uniquement si l'app l'exige ([FE-001](adr/frontend/FE-001-react-vite-par-defaut.md)) |
| Backend  | Node.js LTS + TypeScript + NestJS (adaptateur Fastify) + PostgreSQL + Drizzle ([BE-001](adr/backend/BE-001-choix-de-stack.md)) |
| DevOps   | Docker + GitHub Actions + Terraform/OpenTofu sur Scaleway (OVH en alternative) ([OPS-005](adr/devops/OPS-005-hebergement-scaleway.md)) |
| Android  | Kotlin + Jetpack Compose + Hilt ([AND-001](adr/android/AND-001-kotlin-compose.md)) |
| iOS      | Swift 6 + SwiftUI + Swift Package Manager ([IOS-001](adr/ios/IOS-001-swift-swiftui.md)) |

## Repos associés

| Repo | Rôle |
|------|------|
| `boilerplates` | Points de départ des nouveaux projets, qui appliquent déjà ces ADR ([GLB-010](adr/global/GLB-010-boilerplates-et-libs-partagees.md)) |
| `shared-libs` | Configurations et libs communes (`@soodidi/*`), preset Renovate, workflows GitHub réutilisables |

## Démarrer un projet

`/new-project` crée les repos à partir des boilerplates ([GLB-010](adr/global/GLB-010-boilerplates-et-libs-partagees.md)). Les comptes et secrets à configurer à la main sont dans la [checklist « nouveau projet »](docs/checklist-nouveau-projet.md).

Nouvelle machine : outils, versions et plugins Claude dans [docs/poste-de-travail.md](docs/poste-de-travail.md). Un chantier en cours se suit dans [docs/suivi/](docs/suivi/). Ce sont des **documents temporaires, à effacer** une fois le chantier terminé, qui fluidifient le travail entre les postes et entre les instances d'IA.

## Organisation

```
adr/
├── template.md          # modèle à copier pour tout nouvel ADR
├── global/              # GLB-xxx : règles transverses, tous postes
├── frontend/            # FE-xxx
├── backend/             # BE-xxx
├── devops/              # OPS-xxx
├── android/             # AND-xxx
└── ios/                 # IOS-xxx
docs/                    # guides pratiques (checklist nouveau projet, poste de travail, suivi du chantier)
```

Chaque dossier contient un `README.md` qui sert de **guide du domaine** : la liste des règles en vigueur, en version courte, avec un lien vers l'ADR qui justifie chacune. Pour coder, on lit le guide. Pour comprendre ou contester une règle, on lit l'ADR.

## Ordre de priorité

1. Les ADR **global** s'appliquent partout.
2. Les ADR du domaine complètent ou précisent le global. En cas de conflit, l'ADR le plus spécifique l'emporte, à condition de le dire explicitement dans sa section *Décision*.
3. Un ADR au statut `Remplacé` ou `Déprécié` ne s'applique plus.

## Contribuer

Voir [`CONTRIBUTING.md`](./CONTRIBUTING.md) pour proposer, modifier ou remplacer un ADR.
