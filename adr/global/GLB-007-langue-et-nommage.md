# GLB-007 : Langue et nommage

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Mélanger français et anglais dans le code rend la recherche et la lecture difficiles. Les bibliothèques, les frameworks et la majorité des ressources sont en anglais.

## Décision

| Élément | Langue |
|---------|--------|
| Code : variables, fonctions, classes, fichiers, tables SQL | Anglais |
| Messages de commit, titres de PR | Anglais |
| Commentaires dans le code | Anglais |
| ADR, guides, documentation projet | Français |
| Textes affichés à l'utilisateur | Via fichiers de traduction, jamais en dur |

**Termes métier** : on fixe une traduction anglaise unique par concept et on la note dans un glossaire (`docs/glossary.md` du projet). Exemple : *fonds de commerce* → `business`, *devis* → `quote`. Un même concept NE DOIT PAS avoir deux noms dans le code.

**Nommage**
- Noms explicites plutôt que courts : `unpaidInvoices` plutôt que `inv2`.
- Booléens préfixés : `is`, `has`, `can`, `should`.
- Pas d'abréviations maison ; seules les abréviations universelles sont admises (`id`, `url`, `api`, `db`).
- Les conventions de casse suivent l'écosystème de chaque langage (détaillées dans chaque domaine).

**Commentaires**
- Un commentaire explique le **pourquoi**, pas le quoi. Si le code a besoin d'un commentaire pour expliquer ce qu'il fait, il faut d'abord essayer de le rendre plus clair.

## Alternatives envisagées

- **Tout en français** : se heurte aux API des frameworks (`getUtilisateur()`), recherche de ressources plus difficile.

## Conséquences

- ✅ Code homogène, lisible par n'importe quel développeur.
- ⚠️ Le glossaire doit être tenu à jour.

## Mise en application

- Revue de code.
- Linters de nommage par domaine (ESLint `naming-convention`, detekt, SwiftLint).
