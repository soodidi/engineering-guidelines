# GLB-002 : Git — trunk-based development et Conventional Commits

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : global
- **Auteurs** : Mo, Claude

## Contexte

Les branches longues créent des conflits, retardent l'intégration et rendent les revues pénibles. Un historique de commits incohérent empêche de générer des changelogs et de comprendre l'évolution du code.

## Décision

**Branches**

- `main` est la seule branche longue. Elle DOIT toujours être déployable.
- Les branches de travail DOIVENT être courtes (idéalement < 2 jours) et nommées `<type>/<sujet-court>` : `feat/login-form`, `fix/cart-total`, `chore/bump-deps`.
- Une fonctionnalité inachevée DEVRAIT être fusionnée derrière un feature flag plutôt que de garder une branche ouverte.
- Push direct sur `main` interdit.

**Commits** — format [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>(<scope>): <description à l'impératif, en anglais>

feat(auth): add refresh token rotation
fix(cart): round totals to 2 decimals
```

- Types autorisés : `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`, `revert`, `adr`.
- Un changement cassant DOIT être signalé par `!` (`feat(api)!: …`) et un footer `BREAKING CHANGE:`.

**Fusion**

- Fusion par **squash merge** : le titre de la PR devient le commit sur `main`, il DOIT donc respecter le format.

## Alternatives envisagées

- **Git Flow (develop, release, hotfix)** : adapté aux releases rares et lourdes ; trop de cérémonie pour du déploiement continu. Pour le mobile, voir le tag de release dans GLB-006.
- **Merge commits** : historique de `main` bruité par les commits intermédiaires.
- **Rebase merge** : propre, mais exige que chaque commit de la branche soit soigné.

## Conséquences

- ✅ Historique linéaire et lisible, changelog générable automatiquement.
- ✅ Intégration fréquente, peu de conflits.
- ⚠️ Nécessite des feature flags pour le travail long.

## Mise en application

- Protection de branche GitHub sur `main` : PR obligatoire, CI verte, squash merge uniquement.
- `commitlint` sur le titre de PR (action GitHub) ; `commitlint` + `lefthook` en local (optionnel).
