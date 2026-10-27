# Instructions pour les assistants IA

Ce fichier s'adresse aux assistants de code (Claude, Copilot, Cursor…) qui travaillent sur un projet suivant ces guidelines.

## Avant d'écrire du code

1. Identifier le ou les domaines concernés : frontend, backend, devops, android, ios.
2. Lire `adr/global/README.md` puis le `README.md` du domaine concerné.
3. Ouvrir l'ADR détaillé seulement si la règle courte ne suffit pas ou si la situation sort de l'ordinaire.

## Pendant le travail

- Appliquer les règles des ADR au statut **Accepté** sans demander confirmation.
- Les ADR au statut **Proposé** sont la direction par défaut : les suivre, mais signaler tout point qui pose problème.
- Ignorer les ADR **Déprécié** ou **Remplacé**.
- Ne pas introduire de nouvelle dépendance, de nouveau pattern d'architecture ou de nouvel outil qui contredit un ADR. Si c'est nécessaire, **le dire explicitement** et proposer un nouvel ADR plutôt que de déroger en silence.
- Quand une règle est volontairement contournée (cas exceptionnel), laisser un commentaire dans le code avec la référence : `// Dérogation FE-004 : <raison>`.

## Nouveau projet

Un nouveau projet part toujours du boilerplate correspondant dans le repo `boilerplates` (GLB-010). Ne pas générer un projet avec un autre outil (`create-vite`, `nest new`…) sans le signaler.

## Cycle de travail

Toutes les commandes IA (`/new-project`, `/feature`, `/fix`, `/review`, `/adr`, `/upstream`) et les agents sont résumés dans [ai/COMMANDES.md](ai/COMMANDES.md).

Une fonctionnalité suit le cycle de [GLB-011](adr/global/GLB-011-developpement-avec-l-ia.md) : issue, plan validé par un humain, code, vérification, contrôles par les agents spécialisés, PR, puis fusion automatique une fois la CI verte (`gh pr merge --squash --auto`, jamais `--admin`). Ne jamais annoncer qu'un travail est fini sans avoir lancé la vérification et cité son résultat.

## Quand une décision manque

Si une question d'architecture revient et qu'aucun ADR ne la couvre, proposer un brouillon d'ADR à partir de `adr/template.md` au lieu de trancher seul (commande `/adr`, voir [ai/README.md](ai/README.md)).

## Référence rapide

| Domaine  | Guide |
|----------|-------|
| Global   | [adr/global/README.md](adr/global/README.md) |
| Frontend | [adr/frontend/README.md](adr/frontend/README.md) |
| Backend  | [adr/backend/README.md](adr/backend/README.md) |
| DevOps   | [adr/devops/README.md](adr/devops/README.md) |
| Android  | [adr/android/README.md](adr/android/README.md) |
| iOS      | [adr/ios/README.md](adr/ios/README.md) |
