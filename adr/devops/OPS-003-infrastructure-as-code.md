# OPS-003 : Infrastructure as Code avec OpenTofu / Terraform

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

Une infrastructure créée à la main dans la console (*click-ops*) ne peut être ni relue, ni reproduite, ni restaurée rapidement. On veut pouvoir recréer un environnement complet à partir du code.

## Décision

- Toute ressource cloud durable (réseau, bases, registres, conteneurs, DNS, buckets, secrets — hors valeurs) DOIT être décrite en code avec **OpenTofu** (compatible Terraform), via les providers **Scaleway** et **OVH**.
- La console cloud sert à **observer**, pas à modifier. Une modification manuelle d'urgence DOIT être reportée dans le code le jour même.
- **State distant** dans un bucket Object Storage (backend compatible S3), chiffré, versionné, avec verrouillage du state activé. Un state par environnement. Le state est en plus chiffré par OpenTofu, car il contient des secrets générés (OPS-006).
- Structure :

```
infra/
├── modules/            # briques réutilisables : app-service, database, static-site…
└── envs/
    ├── staging/
    └── production/
```

- Les environnements utilisent les **mêmes modules** avec des variables différentes (taille, nombre d'instances).
- Versions des providers et de l'outil épinglées.
- Toute modification passe par une PR avec le `plan` affiché en commentaire ; l'`apply` est fait par la CI après fusion (staging) ou approbation (production).
- Ressources taguées : `env`, `project`, `managed-by=opentofu`.

## Alternatives envisagées

- **Terraform (HashiCorp)** : équivalent technique ; OpenTofu est open source sous gouvernance de la Linux Foundation, sans contrainte de licence BSL. Les deux restent interchangeables à ce stade.
- **Pulumi (TypeScript)** : séduisant pour une équipe TS, mais écosystème et offres d'emploi plus réduits que Terraform/OpenTofu.
- **Ansible** : adapté à la configuration de serveurs, pas au provisioning cloud déclaratif.

## Conséquences

- ✅ Infrastructure relue, versionnée, reproductible.
- ✅ Compétence Terraform/OpenTofu très recherchée.
- ⚠️ Rigueur sur le state (jamais modifié à la main).

## Mise en application

- CI : `tofu fmt -check`, `tofu validate`, `tflint`, `checkov` (ou `trivy config`) sur chaque PR touchant `infra/`.
- `plan` commenté automatiquement sur la PR.
- Détection de dérive planifiée (`plan` hebdomadaire sur la production).
