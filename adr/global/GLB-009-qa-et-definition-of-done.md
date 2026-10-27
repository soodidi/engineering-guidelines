# GLB-009 : QA, Definition of Done et gestion des bugs

- **Statut** : Proposé
- **Date** : 2026-10-26
- **Périmètre** : global
- **Auteurs** : Mo, Claude
- **Liens** : GLB-003, GLB-004, OPS-004, OPS-007

## Contexte

La stratégie de tests (GLB-004) dit *comment* tester le code, mais pas *quand* une fonctionnalité est terminée, qui la valide, ni comment traiter un bug. Sans règle commune, « c'est fini » veut dire « ça marche sur mon poste », et chaque bug est traité dans l'urgence ou oublié. Sur mobile, un bug publié reste chez les utilisateurs jusqu'à la mise à jour suivante.

## Décision

### Critères d'acceptation

- Chaque ticket fonctionnel DOIT avoir des critères d'acceptation vérifiables, au format *Étant donné / Quand / Alors* quand c'est pertinent.
- Les cas limites attendus (vide, erreur réseau, droits insuffisants, texte long) DEVRAIENT y figurer.

### Definition of Done

Un ticket est terminé quand **toutes** ces conditions sont remplies :

1. Le code est fusionné sur `main` après revue (GLB-003), CI verte.
2. Les tests prévus par GLB-004 sont écrits : logique métier testée, test de non-régression pour un bug corrigé, parcours E2E mis à jour si un parcours critique change.
3. Pour toute UI : vérification au clavier et au lecteur d'écran sur l'écran modifié (FE-008, AND-001, IOS-001), mode sombre, petit écran.
4. Les textes passent par les fichiers de traduction (GLB-007).
5. Les erreurs sont remontées dans l'outil de suivi (Sentry ou équivalent, FE-009, BE-007).
6. La documentation est à jour : README, `.env.example`, ADR si une décision a été prise.
7. La fonctionnalité est déployée en **staging** et **validée** sur les critères d'acceptation par une autre personne que l'auteur (PO, QA ou un autre dev). **Seul sur le projet** : l'auteur la valide lui-même en staging, critère par critère ; la validation par une autre personne s'applique à partir de deux personnes.
8. Si la fonctionnalité est risquée : elle est derrière un feature flag, avec un plan de désactivation.

### Gestion des bugs

**Sévérité**

| Niveau | Définition | Délai de traitement | Bloque une release ? |
|--------|-----------|---------------------|----------------------|
| **S1 – Critique** | Production indisponible, perte ou fuite de données, faille de sécurité, paiement cassé | Immédiat (correctif urgent) | Oui |
| **S2 – Majeur** | Fonctionnalité importante cassée, sans contournement | Avant la prochaine release | Oui |
| **S3 – Mineur** | Fonctionnalité dégradée, contournement possible | Planifié selon priorité | Non |
| **S4 – Cosmétique** | Défaut visuel ou de texte sans impact fonctionnel | Backlog | Non |

**Rapport de bug** : il DOIT contenir les étapes pour reproduire, le résultat attendu, le résultat obtenu, l'environnement (staging/prod, navigateur ou appareil + OS), la version ou le numéro de build, et le lien Sentry s'il existe.

**Cycle** : `Nouveau` → `Confirmé` (reproduit, sévérité fixée) → `En cours` → `À valider` (corrigé en staging) → `Fermé`. Celui qui a signalé le bug, ou la QA, valide la correction.

Tout incident S1 en production donne lieu à un post-mortem (OPS-007).

### Validation avant mise en production

**Web et backend**

- Tests E2E verts sur staging.
- Recette des tickets de la release sur staging.
- Aucun nouveau type d'erreur dans Sentry sur staging depuis le déploiement.

**Mobile**

- Build testé via TestFlight (iOS) et la piste interne (Android) avant soumission.
- Smoke test manuel (checklist courte des parcours critiques) sur la matrice minimale :
  - la version d'OS minimale supportée ;
  - la dernière version d'OS ;
  - un petit écran et un grand écran (ou tablette si supportée).
- Publication progressive ; on n'élargit le déploiement que si le taux de sessions sans crash reste ≥ 99,5 % et qu'aucun bug S1/S2 n'est apparu.

### Tests exploratoires

Les fonctionnalités importantes DEVRAIENT faire l'objet d'une session de test exploratoire de 30 à 60 minutes avant la release, par quelqu'un qui ne les a pas développées.

## Alternatives envisagées

- **Équipe QA dédiée qui valide tout en fin de cycle** : goulot d'étranglement, retours tardifs. La qualité reste la responsabilité de toute l'équipe ; une personne QA, quand il y en a une, anime et outille plutôt qu'elle ne fait barrage.
- **Pas de Definition of Done écrite** : chacun a la sienne, les oublis (a11y, docs, monitoring) se répètent.
- **Outil de gestion de tests (TestRail, Xray…)** : utile à grande échelle, prématuré ici. Les checklists vivent dans les templates GitHub.

## Conséquences

- ✅ « Terminé » a le même sens pour tout le monde.
- ✅ Les bugs sont priorisés de façon cohérente, les releases ont des critères d'arrêt clairs.
- ⚠️ À partir de deux personnes, la validation par une autre personne ajoute un délai : à anticiper dans la planification.

## Mise en application

- Template de PR avec la checklist de la Definition of Done (fourni dans les boilerplates, GLB-010).
- Template d'issue GitHub `bug.yml` avec les champs obligatoires et la sévérité.
- Labels GitHub `severity:S1` à `severity:S4`.
- Checklist de smoke test mobile dans le repo de chaque app (`docs/smoke-test.md`).
