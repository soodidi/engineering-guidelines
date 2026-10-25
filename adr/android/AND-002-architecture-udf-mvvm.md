# AND-002 : Architecture MVVM avec flux de données unidirectionnel

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : android
- **Auteurs** : Mo, Claude

## Contexte

Sans architecture claire, la logique se retrouve dans les écrans, l'état est dupliqué et les rotations d'écran ou la mort du processus provoquent des bugs. Google publie des recommandations d'architecture largement adoptées : on les suit plutôt que d'inventer.

## Décision

Architecture en couches selon le **guide d'architecture Android officiel** :

```
UI layer        Composables  ←  UiState  ←  ViewModel
                     │ événements          │
Domain layer    (optionnel) UseCases
                                           │
Data layer      Repositories  →  DataSources (réseau, base locale, DataStore)
```

**UI layer**
- Un **ViewModel par écran**, qui expose un unique `StateFlow<XxxUiState>` (data class immuable ou `sealed interface` Loading/Success/Error).
- L'UI collecte l'état avec `collectAsStateWithLifecycle()`.
- Les actions utilisateur remontent sous forme d'appels de fonctions du ViewModel (`onSubmitClick()`), jamais de modification directe d'état par l'UI.
- Les événements ponctuels (navigation, snackbar) sont modélisés dans l'état et consommés, plutôt que via des `Channel`/`SharedFlow` qui peuvent se perdre.

**Domain layer**
- Optionnelle : créer un **UseCase** seulement quand une logique est réutilisée par plusieurs ViewModels ou combine plusieurs repositories.

**Data layer**
- Les **repositories** sont la seule source de vérité exposée au reste de l'app ; ils exposent des `Flow` et des fonctions `suspend`.
- Stratégie **offline-first** quand le produit le justifie : la base locale (Room) est la source de vérité, le réseau la met à jour.
- Les modèles réseau (DTO) et base (entités) sont convertis en modèles du domaine ; l'UI ne voit jamais un DTO.

**Navigation**
- **Navigation Compose** avec routes **typées** (`@Serializable`). Les arguments passés sont des identifiants, pas des objets complets.

## Alternatives envisagées

- **MVI strict avec framework (Orbit, Mavericks)** : plus de cérémonie ; le modèle UiState + fonctions d'événements donne l'essentiel des bénéfices.
- **Clean Architecture complète systématique** : UseCases triviaux qui ne font que déléguer ; ajoutée seulement quand utile.

## Conséquences

- ✅ État prévisible, testable, résistant aux changements de configuration.
- ✅ Architecture connue de tout développeur Android.
- ⚠️ Un peu de code de mapping entre couches.

## Mise en application

- Revue de code ; règles detekt personnalisées (pas d'import de couche data dans un composable).
