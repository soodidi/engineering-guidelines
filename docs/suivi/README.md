# Suivi du chantier : documents temporaires

**Les documents de ce dossier sont temporaires et sont à effacer** une fois le chantier terminé.

Ils servent uniquement à fluidifier le travail entre les postes et entre les instances d'IA. N'importe quelle machine ou session de Claude reprend le chantier avec un `git pull`, sans dépendre d'une mémoire locale ni d'un historique de conversation.

- [`HANDOFF.md`](HANDOFF.md) : état du chantier, décisions, préférences, pièges déjà rencontrés.
- [`PLAN-SUITE.md`](PLAN-SUITE.md) : feuille de route et ordre des tâches.

Règles :

- Chaque tâche terminée les met à jour par PR.
- On en ajoute selon les besoins (changement de poste, nouvelle instance d'IA, nouveau chantier).
- Rien de durable ici : une règle qui doit rester va dans un ADR, un guide de `docs/` ou un `AGENTS.md`.
- Chantier terminé : on supprime les fichiers (PR).
