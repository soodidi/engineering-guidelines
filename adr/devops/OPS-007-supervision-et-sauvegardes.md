# OPS-007 : Supervision, alertes et sauvegardes

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : devops
- **Auteurs** : Mo, Claude

## Contexte

Une panne détectée par un utilisateur est une panne détectée trop tard. Une sauvegarde jamais restaurée n'est pas une sauvegarde.

## Décision

**Supervision**
- Logs, métriques et traces centralisés dans **Scaleway Cockpit** (Grafana), alimenté par les logs JSON et l'export OpenTelemetry des applications (BE-007).
- Tableau de bord standard par service : trafic, taux d'erreur, latence (p50/p95/p99), saturation (CPU, mémoire, connexions DB).
- **Supervision externe** (uptime) sur les URL publiques et `/health/ready`, depuis un service tiers distinct de l'hébergeur.
- Suivi des erreurs applicatives (Sentry / GlitchTip) pour le backend, le web et le mobile.

**Alertes**
- On alerte sur les **symptômes vus par l'utilisateur** (taux d'erreur, latence, indisponibilité), pas sur chaque métrique technique.
- Chaque alerte DOIT être actionnable et renvoyer vers un runbook. Une alerte ignorée régulièrement est supprimée ou corrigée.
- Canaux : critiques → notification immédiate ; non critiques → canal d'équipe, traitées en journée.

**Sauvegardes**
- PostgreSQL de production : sauvegardes automatiques quotidiennes managées, rétention ≥ 7 jours, plus une **copie hebdomadaire hors de la région ou chez un autre fournisseur**.
- Buckets de fichiers utilisateurs : versioning activé en production.
- Objectifs par défaut : **RPO ≤ 24 h**, **RTO ≤ 4 h** (à durcir par projet si besoin).
- **Test de restauration** au moins une fois par trimestre, documenté.

**Incidents**
- Tout incident de production ayant un impact utilisateur donne lieu à un **post-mortem sans recherche de coupable**, avec actions correctives suivies.

## Alternatives envisagées

- **Stack de supervision auto-hébergée** (Prometheus, Loki, Grafana) : complète mais à opérer soi-même ; Cockpit fournit la même base en managé.
- **Datadog / New Relic** : très complets, coût élevé et données hors UE.

## Conséquences

- ✅ Pannes détectées avant les utilisateurs, restauration éprouvée.
- ⚠️ Les tests de restauration prennent du temps : à planifier.

## Mise en application

- Dashboards et alertes définis en code quand c'est possible (OPS-003).
- Rappel trimestriel du test de restauration.
