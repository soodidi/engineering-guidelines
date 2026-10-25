# IOS-002 : Architecture MVVM avec @Observable et modules SPM

- **Statut** : Proposé
- **Date** : 2026-10-25
- **Périmètre** : ios
- **Auteurs** : Mo, Claude

## Contexte

Il faut une architecture testable, lisible par tout développeur iOS, et cohérente avec celle d'Android (AND-002) pour faciliter le travail entre les deux plateformes.

## Décision

**Couches** (miroir d'Android)

```
View (SwiftUI)  ←  ViewModel (@Observable, @MainActor)
                         │
                   (UseCase optionnel)
                         │
                   Repository (protocole)  →  API client / persistance locale
```

- Un **ViewModel par écran**, annoté `@Observable` et `@MainActor`, qui expose un état de vue (`enum` Loading/Loaded/Error ou struct) et des méthodes d'action (`func submit() async`).
- Les ViewModels dépendent de **protocoles** de repository, injectés par le constructeur.
- Les modèles réseau sont convertis en modèles du domaine ; la vue ne voit jamais un DTO.
- UseCase seulement quand une logique est partagée entre écrans.

**Navigation**
- `NavigationStack` piloté par un état de navigation typé (`enum Route: Hashable`), détenu par un objet de navigation par flux. Pas de `NavigationLink` dispersés avec destinations construites en dur pour les flux complexes.

**Modularisation**
- Code organisé en **packages Swift locaux** (Swift Package Manager) dans le workspace :
```
Packages/
├── Features/<Nom>      # écrans + ViewModels d'une fonctionnalité
├── Core/Networking     # client API généré
├── Core/Persistence
├── Core/DesignSystem
├── Core/Models
└── Core/Testing        # fakes
```
- L'app (`App/`) assemble les modules et fait l'injection racine.
- Un module Feature ne dépend pas d'un autre module Feature.
- Visibilité `internal` par défaut, `public` uniquement pour l'API du module.

**Injection de dépendances**
- Injection par constructeur ; conteneur simple construit au démarrage de l'app ; `@Environment` pour les dépendances transverses de l'UI. Pas de singleton global accessible partout (`shared`) pour la logique métier.

## Alternatives envisagées

- **TCA (The Composable Architecture)** : très rigoureuse et testable, mais courbe d'apprentissage et dépendance forte à une librairie tierce. Pas par défaut.
- **« MV » (pas de ViewModel, logique dans des modèles observables)** : séduisant pour des écrans simples, moins testable sur des écrans riches.
- **VIPER** : trop de cérémonie.

## Conséquences

- ✅ Architecture symétrique avec Android, ViewModels testables sans UI.
- ✅ Packages SPM : compilation incrémentale, frontières vérifiées par le compilateur.
- ⚠️ Mise en place initiale du workspace modulaire.

## Mise en application

- Les dépendances entre packages sont déclarées dans `Package.swift` : un import interdit ne compile pas.
- Revue de code.
