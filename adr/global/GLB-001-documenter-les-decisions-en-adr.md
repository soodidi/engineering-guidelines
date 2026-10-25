# GLB-001 : Documenter les décisions structurantes en ADR

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Les choix techniques se prennent souvent à l'oral ou dans un fil Slack, puis le *pourquoi* se perd. Six mois plus tard, personne ne sait si une règle est encore justifiée, et on rediscute les mêmes sujets en revue de code. On veut aussi que les assistants IA codent selon les mêmes règles que l'équipe.

## Décision

- Les décisions structurantes DOIVENT être consignées en ADR dans ce repo, au format de `adr/template.md`.
- Les ADR sont rangés par domaine (`global`, `frontend`, `backend`, `devops`, `android`, `ios`) et numérotés par domaine : `GLB-`, `FE-`, `BE-`, `OPS-`, `AND-`, `IOS-`.
- Chaque domaine a un `README.md` qui résume les règles en vigueur en une ligne chacune.
- Un ADR accepté NE DOIT PAS être réécrit sur le fond : on le remplace par un nouvel ADR.
- Les projets qui suivent ces règles DEVRAIENT référencer ce repo dans leur propre `AGENTS.md` / `CLAUDE.md`.

## Alternatives envisagées

- **Un seul gros document de conventions** : simple, mais l'historique des décisions disparaît et le document devient vite illisible.
- **Wiki (Notion, Confluence)** : pas versionné avec le code, pas de revue par PR, moins accessible aux assistants IA.
- **Numérotation globale (0001, 0002…)** : fonctionne, mais rend le rangement par domaine moins lisible.

## Conséquences

- ✅ Le *pourquoi* reste trouvable ; les nouveaux arrivants et les IA ont une source unique.
- ✅ Les discussions se font en PR, avec historique.
- ⚠️ Discipline nécessaire : mettre à jour le README du domaine à chaque ADR.

## Mise en application

- Processus décrit dans `CONTRIBUTING.md`.
- Revue de code : toute PR qui introduit une nouvelle lib structurante ou un nouveau pattern sans ADR est renvoyée.
