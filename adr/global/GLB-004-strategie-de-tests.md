# GLB-004 : Stratégie de tests

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Sans stratégie commune, on oscille entre « pas de tests » et « 100 % de couverture sur des getters ». On veut des tests qui donnent confiance pour livrer, sans ralentir le développement.

## Décision

**Principes**

- On teste le **comportement**, pas l'implémentation. Un refactoring qui ne change pas le comportement ne DEVRAIT pas casser de test.
- Priorité à la **logique métier** et aux **zones à risque** (paiement, auth, calculs, migrations de données).
- Tout bug corrigé DOIT être accompagné d'un test qui le reproduit.
- Les tests DOIVENT être déterministes : pas de dépendance à l'heure réelle, au réseau externe, ni à l'ordre d'exécution.

**Répartition**

| Niveau | Rôle | Volume |
|--------|------|--------|
| Unitaire | Logique pure, fonctions, hooks, services | Beaucoup |
| Intégration | Plusieurs briques réelles (API + base de données, composant + store) | Moyen |
| End-to-end | Parcours utilisateur critiques uniquement | Peu (5 à 15 parcours) |

**Couverture**

- Pas d'objectif de couverture global imposé. La couverture DEVRAIT être suivie et ne pas baisser sur le code modifié.

**Nommage**

- Un test se lit comme une spécification : `it("refuse un panier vide")`, `test_returns_404_when_user_not_found`.

Les outils par domaine sont précisés dans FE-007, BE-008, AND-005 et IOS-005.

## Alternatives envisagées

- **Objectif de couverture à 80 %** : pousse à écrire des tests sans valeur pour atteindre le chiffre.
- **Tout en E2E** : lent et fragile.

## Conséquences

- ✅ Tests utiles et maintenables.
- ⚠️ Demande du jugement : « qu'est-ce qui est à risque ? » se discute en revue.

## Mise en application

- La CI exécute les tests unitaires et d'intégration sur chaque PR, les E2E avant chaque déploiement en production.
- Rapport de couverture en commentaire de PR (informatif).
